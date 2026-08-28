#!/usr/bin/env python3
"""Resolve the latest stable Butterfree toolchain as shell environment variables."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import sys
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from typing import Protocol, cast

GRADLE_URL = "https://services.gradle.org/versions/current"
KOTLIN_RELEASE_URL = "https://api.github.com/repos/JetBrains/kotlin/releases/latest"
MAESTRO_RELEASE_URL = (
    "https://api.github.com/repos/mobile-dev-inc/Maestro/releases/latest"
)
ANDROID_STUDIO_URL = "https://developer.android.com/studio"
ANDROID_REPOSITORY_URL = "https://dl.google.com/android/repository/repository2-3.xml"
USER_AGENT = "matee-butterfree-version-resolver/1.0"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
OVERRIDABLE_VARIABLES = {
    "UBUNTU_VERSION",
    "JAVA_VERSION",
    "GRADLE_VERSION",
    "GRADLE_SHA256",
    "KOTLIN_VERSION",
    "KOTLIN_NATIVE_SHA256",
    "ANDROID_CMDLINE_TOOLS_VERSION",
    "ANDROID_CMDLINE_TOOLS_SHA256",
    "ANDROID_BUILD_TOOLS_VERSIONS",
    "ANDROID_PLATFORM_VERSIONS",
    "ANDROID_PLATFORM_TOOLS_VERSION",
    "ANDROID_EMULATOR_VERSION",
    "EMULATOR_ARCH",
    "EMULATOR_TARGET",
    "EMULATOR_API_LEVEL",
    "EMULATOR_NAME",
    "EMULATOR_DEVICE",
    "MAESTRO_VERSION",
    "MAESTRO_SHA256",
}
ARCHIVE_VERSION_CHECKSUM_PAIRS = (
    ("GRADLE_VERSION", "GRADLE_SHA256"),
    ("KOTLIN_VERSION", "KOTLIN_NATIVE_SHA256"),
    ("ANDROID_CMDLINE_TOOLS_VERSION", "ANDROID_CMDLINE_TOOLS_SHA256"),
    ("MAESTRO_VERSION", "MAESTRO_SHA256"),
)


class UrlResponse(Protocol):
    def read(self) -> bytes: ...

    def close(self) -> None: ...


@dataclass(frozen=True)
class Arguments:
    output_format: str
    namespace: str
    ubuntu_version: str
    java_version: str
    emulator_api_level: str
    emulator_arch: str
    emulator_target: str
    emulator_name: str
    emulator_device: str
    overrides: list[str]


def request_bytes(url: str) -> bytes:
    headers = {"Accept": "application/json", "User-Agent": USER_AGENT}
    if url.startswith("https://api.github.com/") and os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {os.environ['GITHUB_TOKEN']}"

    request = urllib.request.Request(url, headers=headers)
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            response = cast(UrlResponse, urllib.request.urlopen(request, timeout=30))
            try:
                return response.read()
            finally:
                response.close()
        except (urllib.error.URLError, TimeoutError) as error:
            last_error = error
            if attempt < 2:
                time.sleep(float(1 << attempt))
    raise RuntimeError(f"failed to fetch {url}: {last_error}")


def object_mapping(value: object, context: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise TypeError(f"{context} must be a JSON object")
    mapping = cast(dict[object, object], value)
    if not all(isinstance(key, str) for key in mapping):
        raise TypeError(f"{context} contains a non-string key")
    return cast(dict[str, object], mapping)


def json_object(data: bytes, context: str) -> dict[str, object]:
    value = cast(object, json.loads(data))
    return object_mapping(value, context)


def required_string(mapping: dict[str, object], name: str, context: str) -> str:
    value = mapping.get(name)
    if not isinstance(value, str):
        raise TypeError(f"{context}.{name} must be a string")
    if not value:
        raise ValueError(f"{context}.{name} must not be empty")
    return value


def string_list(mapping: dict[str, object], name: str, context: str) -> list[str]:
    value = mapping.get(name)
    if not isinstance(value, list):
        raise TypeError(f"{context}.{name} must be a list")
    items = cast(list[object], value)
    if not all(isinstance(item, str) for item in items):
        raise TypeError(f"{context}.{name} must contain only strings")
    return cast(list[str], items)


def release_assets(release: dict[str, object]) -> dict[str, dict[str, object]]:
    value = release.get("assets")
    if not isinstance(value, list):
        raise TypeError("release.assets must be a list")

    assets: dict[str, dict[str, object]] = {}
    for index, item in enumerate(cast(list[object], value)):
        asset = object_mapping(item, f"release.assets[{index}]")
        assets[required_string(asset, "name", f"release.assets[{index}]")] = asset
    return assets


def checksum_from_release(release: dict[str, object], archive_name: str) -> str:
    assets = release_assets(release)
    archive = assets.get(archive_name)
    if archive is None:
        raise RuntimeError(
            f"release {release.get('tag_name')} has no {archive_name} asset"
        )

    digest_value = archive.get("digest")
    digest = digest_value if isinstance(digest_value, str) else ""
    if digest.startswith("sha256:") and SHA256_RE.fullmatch(
        digest.removeprefix("sha256:")
    ):
        return digest.removeprefix("sha256:")

    checksum_asset = assets.get(f"{archive_name}.sha256")
    if checksum_asset is not None:
        checksum_url = required_string(
            checksum_asset, "browser_download_url", f"asset {archive_name}.sha256"
        )
        body = request_bytes(checksum_url).decode("ascii")
        match = re.search(r"\b([0-9a-fA-F]{64})\b", body)
        if match:
            return match.group(1).lower()

    checksum_list = assets.get("checksums_sha256.txt")
    if checksum_list is not None:
        checksum_url = required_string(
            checksum_list, "browser_download_url", "asset checksums_sha256.txt"
        )
        body = request_bytes(checksum_url).decode("ascii")
        for line in body.splitlines():
            if line.split()[-1:] == [archive_name]:
                checksum = line.split()[0].lower()
                if SHA256_RE.fullmatch(checksum):
                    return checksum

    raise RuntimeError(
        f"release {release.get('tag_name')} has no SHA-256 for {archive_name}"
    )


def resolve_gradle(payload: dict[str, object]) -> tuple[str, str]:
    version = required_string(payload, "version", "Gradle release")
    checksum = required_string(payload, "checksum", "Gradle release").lower()
    if payload.get("final") is not True or not SHA256_RE.fullmatch(checksum):
        raise RuntimeError(
            "Gradle current release metadata is not a final checksummed release"
        )
    return version, checksum


def resolve_kotlin(release: dict[str, object]) -> tuple[str, str]:
    version = required_string(release, "tag_name", "Kotlin release").removeprefix("v")
    archive = f"kotlin-native-prebuilt-linux-x86_64-{version}.tar.gz"
    return version, checksum_from_release(release, archive)


def resolve_maestro(release: dict[str, object]) -> tuple[str, str]:
    tag = required_string(release, "tag_name", "Maestro release")
    if not tag.startswith("cli-"):
        raise RuntimeError(f"unexpected Maestro release tag: {tag}")
    return tag.removeprefix("cli-"), checksum_from_release(release, "maestro.zip")


def resolve_android_cli(html: str) -> tuple[str, str]:
    match = re.search(
        r"commandlinetools-linux-(\d+)_latest\.zip</button>\s*</td>\s*"
        + r"<td>[^<]+</td>\s*<td>([0-9a-fA-F]{64})</td>",
        html,
    )
    if not match:
        raise RuntimeError(
            "could not find the Linux command-line tools SHA-256 on the Android Studio page"
        )
    return match.group(1), match.group(2).lower()


def local_name(element: ET.Element) -> str:
    return element.tag.rsplit("}", 1)[-1]


def child(element: ET.Element, name: str) -> ET.Element | None:
    return next((item for item in element if local_name(item) == name), None)


def child_text(element: ET.Element, name: str, default: str = "") -> str:
    item = child(element, name)
    return (item.text or default).strip() if item is not None else default


def channel(package: ET.Element) -> str:
    item = child(package, "channelRef")
    return item.attrib.get("ref", "") if item is not None else ""


def revision(package: ET.Element) -> str:
    item = child(package, "revision")
    if item is None:
        raise RuntimeError(
            f"Android package {package.attrib.get('path')} has no revision"
        )
    values = [child_text(item, part, "0") for part in ("major", "minor", "micro")]
    return ".".join(values)


def version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def resolve_android_repository(xml: bytes) -> tuple[list[str], list[str], str, str]:
    root = ET.fromstring(xml)
    packages = [item for item in root.iter() if local_name(item) == "remotePackage"]

    build_tools: list[str] = []
    platforms: list[str] = []
    for package in packages:
        path = package.attrib.get("path", "")
        if channel(package) != "channel-0":
            continue
        build_match = re.fullmatch(r"build-tools;(\d+\.\d+\.\d+)", path)
        platform_match = re.fullmatch(r"platforms;android-(\d+(?:\.\d+)?)", path)
        if build_match:
            build_tools.append(build_match.group(1))
        elif platform_match:
            platforms.append(platform_match.group(1))

    build_tools = sorted(set(build_tools), key=version_key, reverse=True)[:3]
    platforms = sorted(set(platforms), key=version_key, reverse=True)[:3]
    if len(build_tools) != 3 or len(platforms) != 3:
        raise RuntimeError(
            "Android repository did not contain three stable build-tools and platforms"
        )

    platform_tools_packages = [
        item
        for item in packages
        if item.attrib.get("path") == "platform-tools" and channel(item) == "channel-0"
    ]
    emulator_packages = [
        item
        for item in packages
        if item.attrib.get("path") == "emulator" and channel(item) == "channel-0"
    ]
    if not platform_tools_packages or not emulator_packages:
        raise RuntimeError(
            "Android repository is missing stable platform-tools or emulator metadata"
        )

    platform_tools = max(
        (revision(item) for item in platform_tools_packages), key=version_key
    )
    emulator = max((revision(item) for item in emulator_packages), key=version_key)
    return build_tools, platforms, platform_tools, emulator


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9_.-]+", "-", value.lower()).strip("-._")


def fingerprint(values: dict[str, str]) -> str:
    encoded = json.dumps(values, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()[:12]


def parse_overrides(items: list[str]) -> dict[str, str]:
    overrides: dict[str, str] = {}
    for item in items:
        name, separator, value = item.partition("=")
        if not separator or not name or not value:
            raise ValueError(f"invalid --set value {item!r}; expected NAME=VALUE")
        if name not in OVERRIDABLE_VARIABLES:
            allowed = ", ".join(sorted(OVERRIDABLE_VARIABLES))
            raise ValueError(
                f"{name} cannot be overridden; allowed variables: {allowed}"
            )
        overrides[name] = value
    return overrides


def validate_overrides(latest: dict[str, str], overrides: dict[str, str]) -> None:
    for version_name, checksum_name in ARCHIVE_VERSION_CHECKSUM_PAIRS:
        if (
            version_name in overrides
            and overrides[version_name] != latest[version_name]
            and checksum_name not in overrides
        ):
            raise ValueError(
                f"overriding {version_name} also requires --set {checksum_name}=..."
            )

    for checksum_name in (checksum for _, checksum in ARCHIVE_VERSION_CHECKSUM_PAIRS):
        checksum = overrides.get(checksum_name, latest[checksum_name]).lower()
        if not SHA256_RE.fullmatch(checksum):
            raise ValueError(f"{checksum_name} must be a 64-character SHA-256")


def parse_args() -> Arguments:
    parser = argparse.ArgumentParser(
        description="Print latest stable Butterfree versions as environment variables."
    )
    _ = parser.add_argument("--format", choices=("shell", "env"), default="shell")
    _ = parser.add_argument(
        "--namespace",
        default=os.environ.get("DOCKERHUB_NAMESPACE", "mateedevs"),
        help="Docker Hub user or organization that owns the fixed repositories",
    )
    _ = parser.add_argument(
        "--ubuntu-version", default=os.environ.get("UBUNTU_VERSION", "22.04")
    )
    _ = parser.add_argument(
        "--java-version", default=os.environ.get("JAVA_VERSION", "21")
    )
    _ = parser.add_argument(
        "--emulator-api-level", default=os.environ.get("EMULATOR_API_LEVEL", "34")
    )
    _ = parser.add_argument(
        "--emulator-arch", default=os.environ.get("EMULATOR_ARCH", "x86_64")
    )
    _ = parser.add_argument(
        "--emulator-target",
        default=os.environ.get("EMULATOR_TARGET", "google_apis_playstore"),
    )
    _ = parser.add_argument(
        "--emulator-name", default=os.environ.get("EMULATOR_NAME", "Pixel_7_Pro")
    )
    _ = parser.add_argument(
        "--emulator-device", default=os.environ.get("EMULATOR_DEVICE", "pixel_7_pro")
    )
    _ = parser.add_argument(
        "--set",
        action="append",
        default=[],
        metavar="NAME=VALUE",
        help=(
            "override a resolved build variable; repeat as needed. Changing Gradle, "
            + "Kotlin, Android command-line tools, or Maestro also requires its SHA-256"
        ),
    )
    parsed = cast(dict[str, object], vars(parser.parse_args()))
    return Arguments(
        output_format=required_string(parsed, "format", "arguments"),
        namespace=required_string(parsed, "namespace", "arguments"),
        ubuntu_version=required_string(parsed, "ubuntu_version", "arguments"),
        java_version=required_string(parsed, "java_version", "arguments"),
        emulator_api_level=required_string(parsed, "emulator_api_level", "arguments"),
        emulator_arch=required_string(parsed, "emulator_arch", "arguments"),
        emulator_target=required_string(parsed, "emulator_target", "arguments"),
        emulator_name=required_string(parsed, "emulator_name", "arguments"),
        emulator_device=required_string(parsed, "emulator_device", "arguments"),
        overrides=string_list(parsed, "set", "arguments"),
    )


def main() -> int:
    args = parse_args()
    overrides = parse_overrides(args.overrides)
    urls = (
        GRADLE_URL,
        KOTLIN_RELEASE_URL,
        MAESTRO_RELEASE_URL,
        ANDROID_STUDIO_URL,
        ANDROID_REPOSITORY_URL,
    )
    with ThreadPoolExecutor(max_workers=len(urls)) as executor:
        responses = dict(zip(urls, executor.map(request_bytes, urls)))

    gradle_version, gradle_sha = resolve_gradle(
        json_object(responses[GRADLE_URL], "Gradle response")
    )
    kotlin_version, kotlin_sha = resolve_kotlin(
        json_object(responses[KOTLIN_RELEASE_URL], "Kotlin response")
    )
    maestro_version, maestro_sha = resolve_maestro(
        json_object(responses[MAESTRO_RELEASE_URL], "Maestro response")
    )
    command_tools_version, command_tools_sha = resolve_android_cli(
        responses[ANDROID_STUDIO_URL].decode("utf-8")
    )
    build_tools, platforms, platform_tools_version, emulator_version = (
        resolve_android_repository(responses[ANDROID_REPOSITORY_URL])
    )

    values = {
        "DOCKERHUB_NAMESPACE": slug(args.namespace),
        "UBUNTU_VERSION": args.ubuntu_version,
        "JAVA_VERSION": args.java_version,
        "GRADLE_VERSION": gradle_version,
        "GRADLE_SHA256": gradle_sha,
        "KOTLIN_VERSION": kotlin_version,
        "KOTLIN_NATIVE_SHA256": kotlin_sha,
        "ANDROID_CMDLINE_TOOLS_VERSION": command_tools_version,
        "ANDROID_CMDLINE_TOOLS_SHA256": command_tools_sha,
        "ANDROID_BUILD_TOOLS_VERSIONS": ",".join(build_tools),
        "ANDROID_PLATFORM_VERSIONS": ",".join(platforms),
        "ANDROID_PLATFORM_TOOLS_VERSION": platform_tools_version,
        "ANDROID_EMULATOR_VERSION": emulator_version,
        "EMULATOR_ARCH": args.emulator_arch,
        "EMULATOR_TARGET": args.emulator_target,
        "EMULATOR_API_LEVEL": args.emulator_api_level,
        "EMULATOR_NAME": args.emulator_name,
        "EMULATOR_DEVICE": args.emulator_device,
        "MAESTRO_VERSION": maestro_version,
        "MAESTRO_SHA256": maestro_sha,
    }
    validate_overrides(values, overrides)
    values.update(overrides)
    for _, checksum_name in ARCHIVE_VERSION_CHECKSUM_PAIRS:
        values[checksum_name] = values[checksum_name].lower()
    if not values["DOCKERHUB_NAMESPACE"]:
        raise ValueError("DOCKERHUB_NAMESPACE must not be empty")

    platforms_value = [
        item.strip()
        for item in values["ANDROID_PLATFORM_VERSIONS"].split(",")
        if item.strip()
    ]
    if not platforms_value:
        raise ValueError("ANDROID_PLATFORM_VERSIONS must contain at least one platform")

    common_identity = {
        "ubuntu": values["UBUNTU_VERSION"],
        "java": values["JAVA_VERSION"],
        "gradle": values["GRADLE_VERSION"],
        "gradle_sha256": values["GRADLE_SHA256"],
        "kotlin": values["KOTLIN_VERSION"],
        "kotlin_sha256": values["KOTLIN_NATIVE_SHA256"],
        "android_cli": values["ANDROID_CMDLINE_TOOLS_VERSION"],
        "android_cli_sha256": values["ANDROID_CMDLINE_TOOLS_SHA256"],
        "build_tools": values["ANDROID_BUILD_TOOLS_VERSIONS"],
        "platforms": values["ANDROID_PLATFORM_VERSIONS"],
        "platform_tools": values["ANDROID_PLATFORM_TOOLS_VERSION"],
    }
    emulator_identity = {
        **common_identity,
        "emulator": values["ANDROID_EMULATOR_VERSION"],
        "emulator_api": values["EMULATOR_API_LEVEL"],
        "emulator_arch": values["EMULATOR_ARCH"],
        "emulator_target": values["EMULATOR_TARGET"],
        "maestro": values["MAESTRO_VERSION"],
        "maestro_sha256": values["MAESTRO_SHA256"],
    }

    newest_platform = platforms_value[0]
    butterfree_tag = slug(
        f"build-jdk{values['JAVA_VERSION']}-gradle{values['GRADLE_VERSION']}"
        + f"-kotlin{values['KOTLIN_VERSION']}"
        + f"-sdk{newest_platform}-{fingerprint(common_identity)}"
    )
    emulator_tag = slug(
        f"emulator-jdk{values['JAVA_VERSION']}-sdk{newest_platform}"
        + f"-api{values['EMULATOR_API_LEVEL']}"
        + f"-maestro{values['MAESTRO_VERSION']}-{fingerprint(emulator_identity)}"
    )

    values["BUTTERFREE_IMAGE_TAG"] = butterfree_tag
    values["EMULATOR_IMAGE_TAG"] = emulator_tag
    namespace = values["DOCKERHUB_NAMESPACE"]
    repository = f"{namespace}/butterfree"
    values["BUTTERFREE_IMAGE"] = f"{repository}:{butterfree_tag}"
    values["EMULATOR_IMAGE"] = f"{repository}:{emulator_tag}"

    prefix = "export " if args.output_format == "shell" else ""
    for name, value in values.items():
        print(f"{prefix}{name}={shlex.quote(str(value))}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        KeyError,
        TypeError,
        ValueError,
        RuntimeError,
        ET.ParseError,
        json.JSONDecodeError,
    ) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
