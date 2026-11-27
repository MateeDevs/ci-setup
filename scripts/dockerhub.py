#!/usr/bin/env python3
"""Docker Hub publishing helpers for Butterfree and Beautifly."""

from __future__ import annotations

import base64
import binascii
import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Protocol, cast

HUB_API = "https://hub.docker.com/v2"
USER_AGENT = "matee-ci-setup-dockerhub/1.0"
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


def access_token(account: tuple[str, str]) -> str:
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


def check_tags(namespace: str, repository: str, tags: list[str], token: str) -> set[str]:
    existing: set[str] = set()
    repository_status, _ = request(
        repository_url(namespace, repository), method="HEAD", token=token
    )
    if repository_status == 404:
        raise RuntimeError(f"Create {namespace}/{repository} on Docker Hub before publishing.")
    if repository_status != 200:
        raise RuntimeError(f"Cannot check {namespace}/{repository} (HTTP {repository_status}).")

    for tag in tags:
        encoded_tag = urllib.parse.quote(tag, safe="")
        status, _ = request(
            repository_url(namespace, repository, f"/tags/{encoded_tag}"),
            method="HEAD",
            token=token,
        )
        if status == 200:
            existing.add(tag)
        elif status != 404:
            raise RuntimeError(f"Cannot check {namespace}/{repository}:{tag} (HTTP {status}).")
    return existing


def update_description(
    namespace: str, repository: str, summary: str, description: str, token: str
) -> None:
    status, _ = request(
        repository_url(namespace, repository),
        method="PATCH",
        token=token,
        payload={"description": summary, "full_description": description},
    )
    if status not in (200, 202):
        raise RuntimeError(f"Cannot update the description for {namespace}/{repository} (HTTP {status}).")
