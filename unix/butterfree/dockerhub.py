#!/usr/bin/env python3
"""Check Butterfree tags and update Docker Hub repository descriptions."""

from __future__ import annotations

import base64
import binascii
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Protocol, cast

HUB_API = "https://hub.docker.com/v2"
USER_AGENT = "matee-butterfree-dockerhub/1.0"
SOURCE_URL = "https://github.com/MateeDevs/ci-setup/tree/master"
DOCKER_HUB_SERVERS = (
    "https://index.docker.io/v1/",
    "index.docker.io",
    "registry-1.docker.io",
    "docker.io",
)


class UrlResponse(Protocol):
    status: int

    def read(self) -> bytes: ...

    def close(self) -> None: ...


def request(
    url: str,
    *,
    method: str = "GET",
    token: str | None = None,
    payload: dict[str, object] | None = None,
) -> tuple[int, bytes]:
    headers = {"Accept": "application/json", "User-Agent": USER_AGENT}
    data: bytes | None = None
    if token is not None:
        headers["Authorization"] = f"Bearer {token}"
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload, separators=(",", ":")).encode()

    hub_request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        response = cast(UrlResponse, urllib.request.urlopen(hub_request, timeout=30))
        try:
            return response.status, response.read()
        finally:
            response.close()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def object_mapping(value: object, context: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise TypeError(f"{context} must be a JSON object")
    mapping = cast(dict[object, object], value)
    if not all(isinstance(key, str) for key in mapping):
        raise TypeError(f"{context} contains a non-string key")
    return cast(dict[str, object], mapping)


def json_object(data: bytes, context: str) -> dict[str, object]:
    return object_mapping(cast(object, json.loads(data)), context)


def required_string(mapping: dict[str, object], name: str, context: str) -> str:
    value = mapping.get(name)
    if not isinstance(value, str):
        raise TypeError(f"{context}.{name} must be a string")
    if not value:
        raise ValueError(f"{context}.{name} must not be empty")
    return value


def credential_helper(helper: str, server: str) -> tuple[str, str] | None:
    try:
        result = subprocess.run(
            [f"docker-credential-{helper}", "get"],
            input=f"{server}\n",
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
    except FileNotFoundError as error:
        raise RuntimeError(
            f"Docker credential helper docker-credential-{helper} was not found"
        ) from error
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"Docker credential helper docker-credential-{helper} timed out"
        ) from error

    if result.returncode != 0:
        return None
    response = json_object(result.stdout.encode(), "Docker credential helper response")
    username = required_string(
        response, "Username", "Docker credential helper response"
    )
    secret = required_string(response, "Secret", "Docker credential helper response")
    return username, secret


def docker_config_credentials() -> tuple[str, str] | None:
    configured_directory = os.environ.get("DOCKER_CONFIG")
    config_directory = (
        Path(configured_directory).expanduser()
        if configured_directory
        else Path.home() / ".docker"
    )
    config_path = config_directory / "config.json"
    try:
        config_data = config_path.read_bytes()
    except FileNotFoundError:
        return None

    config = json_object(config_data, str(config_path))
    auths_value = config.get("auths", {})
    auths = object_mapping(auths_value, f"{config_path}.auths")
    helpers_value = config.get("credHelpers", {})
    helpers = object_mapping(helpers_value, f"{config_path}.credHelpers")

    for server in DOCKER_HUB_SERVERS:
        helper = helpers.get(server)
        if helper is None:
            continue
        if not isinstance(helper, str) or not helper:
            raise TypeError(f"{config_path}.credHelpers.{server} must be a string")
        account = credential_helper(helper, server)
        if account is not None:
            return account

    store = config.get("credsStore")
    if store is not None:
        if not isinstance(store, str) or not store:
            raise TypeError(f"{config_path}.credsStore must be a string")
        for server in DOCKER_HUB_SERVERS:
            account = credential_helper(store, server)
            if account is not None:
                return account

    for server in DOCKER_HUB_SERVERS:
        entry_value = auths.get(server)
        if entry_value is None:
            continue
        entry = object_mapping(entry_value, f"{config_path}.auths.{server}")
        encoded = entry.get("auth")
        if encoded is None:
            continue
        if not isinstance(encoded, str):
            raise TypeError(f"{config_path}.auths.{server}.auth must be a string")
        try:
            decoded = base64.b64decode(encoded, validate=True).decode()
        except (binascii.Error, UnicodeDecodeError) as error:
            raise ValueError(
                f"{config_path}.auths.{server}.auth is not valid base64 UTF-8"
            ) from error
        username, separator, secret = decoded.partition(":")
        if not separator or not username or not secret:
            raise ValueError(
                f"{config_path}.auths.{server}.auth is not a username/password pair"
            )
        return username, secret
    return None


def credentials(*, required: bool) -> tuple[str, str] | None:
    username = os.environ.get("DOCKERHUB_USERNAME")
    secret = os.environ.get("DOCKERHUB_TOKEN")
    if username and secret:
        return username, secret
    if username or secret:
        raise ValueError("DOCKERHUB_USERNAME and DOCKERHUB_TOKEN must be set together")
    account = docker_config_credentials()
    if account is not None:
        return account
    if required:
        raise ValueError(
            "Docker Hub credentials were not found; run docker login or set "
            + "DOCKERHUB_USERNAME and DOCKERHUB_TOKEN"
        )
    return None


def auth_source() -> int:
    username = os.environ.get("DOCKERHUB_USERNAME")
    secret = os.environ.get("DOCKERHUB_TOKEN")
    if username and secret:
        print("environment")
        return 0
    if username or secret:
        raise ValueError("DOCKERHUB_USERNAME and DOCKERHUB_TOKEN must be set together")
    if docker_config_credentials() is not None:
        print("docker-login")
        return 0
    return 1


def access_token(*, required: bool) -> str | None:
    account = credentials(required=required)
    if account is None:
        return None
    username, secret = account
    status, body = request(
        f"{HUB_API}/auth/token",
        method="POST",
        payload={"identifier": username, "secret": secret},
    )
    if status != 200:
        raise RuntimeError(f"Docker Hub authentication failed with HTTP {status}")
    return required_string(
        json_object(body, "Docker Hub authentication response"),
        "access_token",
        "Docker Hub authentication response",
    )


def repository_url(namespace: str, repository: str, suffix: str = "") -> str:
    encoded_namespace = urllib.parse.quote(namespace, safe="")
    encoded_repository = urllib.parse.quote(repository, safe="")
    return (
        f"{HUB_API}/namespaces/{encoded_namespace}/repositories/"
        + f"{encoded_repository}{suffix}"
    )


def parse_tag_entry(entry: str) -> tuple[str, str, str]:
    target, separator, reference = entry.partition("=")
    repository, tag_separator, tag = reference.rpartition(":")
    if not separator or not target or not tag_separator or not repository or not tag:
        raise ValueError(f"invalid tag entry {entry!r}; expected TARGET=REPOSITORY:TAG")
    return target, repository, tag


def check_tags(namespace: str, entries: list[str]) -> int:
    token = access_token(required=False)
    checked_repositories: set[str] = set()
    for entry in entries:
        target, repository, tag = parse_tag_entry(entry)
        if repository not in checked_repositories:
            repository_status, _ = request(
                repository_url(namespace, repository), method="HEAD", token=token
            )
            if repository_status == 404:
                raise RuntimeError(
                    f"Docker Hub repository {namespace}/{repository} does not exist; "
                    + "Butterfree will not create repositories"
                )
            if repository_status in (401, 403):
                raise RuntimeError(
                    f"cannot inspect {namespace}/{repository} (HTTP {repository_status}); "
                    + "run docker login or set Docker Hub API credentials for "
                    + "private repositories"
                )
            if repository_status != 200:
                raise RuntimeError(
                    f"cannot inspect {namespace}/{repository} "
                    + f"(HTTP {repository_status})"
                )
            checked_repositories.add(repository)

        encoded_tag = urllib.parse.quote(tag, safe="")
        status, _ = request(
            repository_url(namespace, repository, f"/tags/{encoded_tag}"),
            method="HEAD",
            token=token,
        )
        if status == 200:
            print(f"{target}=exists")
        elif status == 404:
            print(f"{target}=missing")
        elif status in (401, 403):
            raise RuntimeError(
                f"cannot inspect {namespace}/{repository}:{tag} (HTTP {status}); "
                + "run docker login or set Docker Hub API credentials for "
                + "private repositories"
            )
        else:
            raise RuntimeError(
                f"cannot inspect {namespace}/{repository}:{tag} (HTTP {status})"
            )
    return 0


def environment_value(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"{name} is required to generate Docker Hub descriptions")
    return value


def markdown_table(rows: list[tuple[str, str]]) -> str:
    lines = ["| Component | Version |", "| --- | --- |"]
    for component, version in rows:
        escaped_component = component.replace("|", "\\|")
        escaped_version = version.replace("|", "\\|")
        lines.append(f"| {escaped_component} | `{escaped_version}` |")
    return "\n".join(lines)


def repository_descriptions() -> dict[str, tuple[str, str]]:
    common_rows = [
        ("Ubuntu", environment_value("UBUNTU_VERSION")),
        ("Java", environment_value("JAVA_VERSION")),
        ("Gradle", environment_value("GRADLE_VERSION")),
        ("Kotlin/Native", environment_value("KOTLIN_VERSION")),
        (
            "Android command-line tools",
            environment_value("ANDROID_CMDLINE_TOOLS_VERSION"),
        ),
        ("Android platform-tools", environment_value("ANDROID_PLATFORM_TOOLS_VERSION")),
        ("Android build-tools", environment_value("ANDROID_BUILD_TOOLS_VERSIONS")),
        ("Android platforms", environment_value("ANDROID_PLATFORM_VERSIONS")),
    ]
    emulator_rows = common_rows + [
        ("Android emulator", environment_value("ANDROID_EMULATOR_VERSION")),
        ("Emulator API", environment_value("EMULATOR_API_LEVEL")),
        ("Emulator target", environment_value("EMULATOR_TARGET")),
        ("Emulator architecture", environment_value("EMULATOR_ARCH")),
        ("Emulator device", environment_value("EMULATOR_DEVICE")),
        ("Maestro", environment_value("MAESTRO_VERSION")),
    ]

    summary = "Versioned Android CI images for builds and Maestro emulator testing."
    variants = [
        ("Build", environment_value("BUTTERFREE_IMAGE_TAG")),
        ("Emulator with Maestro", environment_value("EMULATOR_IMAGE_TAG")),
    ]
    variant_lines = ["| Variant | Versioned tag |", "| --- | --- |"]
    variant_lines.extend(f"| {variant} | `{tag}` |" for variant, tag in variants)
    emulator_only_rows = emulator_rows[len(common_rows) :]

    full_description = (
        "# butterfree\n\n"
        + "Butterfree supplies Android CI images for builds and emulator tests "
        + "with Maestro. Select a variant by its versioned tag prefix.\n\n"
        + "## Current variants\n\n"
        + "\n".join(variant_lines)
        + "\n\n## Shared build toolchain\n\n"
        + markdown_table(common_rows)
        + "\n\n## Emulator additions\n\n"
        + markdown_table(emulator_only_rows)
        + f"\n\n## Source\n\n[Source files and instructions]({SOURCE_URL})\n\n"
        + "Butterfree generated this description from the effective build "
        + "configuration.\n"
    )
    return {"butterfree": (summary, full_description)}


def update_descriptions(namespace: str) -> int:
    token = access_token(required=True)
    if token is None:
        raise RuntimeError("Docker Hub authentication unexpectedly returned no token")

    for repository, (summary, full_description) in repository_descriptions().items():
        status, _ = request(
            repository_url(namespace, repository),
            method="PATCH",
            token=token,
            payload={"description": summary, "full_description": full_description},
        )
        if status not in (200, 202):
            raise RuntimeError(
                f"failed to update {namespace}/{repository} description (HTTP {status})"
            )
        print(f"Updated Docker Hub description for {namespace}/{repository}")
    return 0


def show_descriptions() -> int:
    for repository, (_, full_description) in repository_descriptions().items():
        print(f"\n--- {repository} ---\n\n{full_description}")
    return 0


def usage() -> None:
    print(
        "Usage:\n"
        + "  dockerhub.py auth-source\n"
        + "  dockerhub.py check-tags NAMESPACE TARGET=REPOSITORY:TAG [...]\n"
        + "  dockerhub.py show-descriptions\n"
        + "  dockerhub.py update-descriptions NAMESPACE"
    )


def main(arguments: list[str]) -> int:
    if not arguments or arguments[0] in ("-h", "--help"):
        usage()
        return 0
    if arguments[0] == "auth-source" and len(arguments) == 1:
        return auth_source()
    if arguments[0] == "check-tags" and len(arguments) >= 3:
        return check_tags(arguments[1], arguments[2:])
    if arguments[0] == "show-descriptions" and len(arguments) == 1:
        return show_descriptions()
    if arguments[0] == "update-descriptions" and len(arguments) == 2:
        return update_descriptions(arguments[1])
    usage()
    raise ValueError("invalid Docker Hub helper arguments")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (
        json.JSONDecodeError,
        OSError,
        RuntimeError,
        TypeError,
        ValueError,
    ) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
