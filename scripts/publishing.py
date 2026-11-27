"""Run the shared image publishing workflow."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
import re
import shlex
import subprocess
import sys

import dockerhub


@dataclass(frozen=True)
class Image:
    tag: str
    ref: str
    local: str = ""


@dataclass(frozen=True)
class Plan:
    images: list[Image]
    settings: list[tuple[str, str]]
    description: tuple[str, str] | None
    build: Callable[[list[Image]], None]
    upload: Callable[[Image], None]
    check_local: Callable[[Image], None]
    build_prompt: str


def run(command, **kwargs) -> None:
    subprocess.run(command, check=True, **kwargs)


def validate_namespace(namespace: str) -> str:
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", namespace):
        raise ValueError(f"Invalid Docker Hub namespace: {namespace}")
    return namespace


def validate_tag(tag: str) -> str:
    if not re.fullmatch(r"[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}", tag):
        raise ValueError(f"Invalid image tag: {tag}")
    return tag


def workflow(
    name: str,
    namespace: str,
    repository: str,
    assume_yes: bool,
    publish_only: bool,
    resolve: Callable[[tuple[str, str]], Plan],
) -> int:
    def step(number: int, title: str) -> None:
        print(f"\n[{number}/5] {title}", flush=True)

    def status(label: str, message: str) -> None:
        print(f"  {label:<9} {message}", flush=True)

    def confirm(prompt: str) -> bool:
        if assume_yes:
            print(f"  {prompt} [yes]", flush=True)
            return True
        return input(f"  {prompt} [y/N] ").strip().lower() in ("y", "yes")

    def show_retry(images: list[Image]) -> None:
        for image in images:
            if image not in uploaded and image.tag not in existing:
                command = [f"./{name.lower()}", "--namespace", namespace, "--publish-only", image.tag]
                status("Retry", shlex.join(command))

    print(name, flush=True)
    if not assume_yes and not sys.stdin.isatty():
        raise ValueError("Use --yes if you cannot answer the prompts.")

    account = dockerhub.docker_config_credentials()
    if account is None:
        raise RuntimeError("Sign in to Docker Hub with docker login before publishing.")
    token = dockerhub.access_token(account)

    uploaded: list[Image] = []
    existing: set[str] = set()
    stage = "Resolve build settings"
    try:
        step(1, stage)
        plan = resolve(account)
        if publish_only:
            status("Skipped", "Use the local images for the specified tags.")
        for label, value in plan.settings:
            print(f"  {label:<20} {value}", flush=True)

        stage = "Check Docker Hub tags"
        step(2, stage)
        existing = dockerhub.check_tags(
            namespace, repository, [image.tag for image in plan.images], token
        )
        missing = [image for image in plan.images if image.tag not in existing]
        for image in plan.images:
            status("Exists" if image.tag in existing else "Missing", image.ref)

        stage = "Build images"
        step(3, stage)
        if not missing:
            status("Skipped", "All tags already exist.")
        elif publish_only:
            for image in missing:
                plan.check_local(image)
            status("Skipped", "Use the local images.")
        elif confirm(plan.build_prompt):
            plan.build(missing)
            for image in missing:
                status("Built", image.ref)
        else:
            status("Skipped", "Build declined. No images were uploaded.")
            return 0

        stage = "Upload images"
        step(4, stage)
        if not missing:
            status("Skipped", "All tags already exist.")
        elif confirm("Upload the missing images to Docker Hub?"):
            for image in missing:
                token = dockerhub.access_token(account)
                if image.tag in dockerhub.check_tags(namespace, repository, [image.tag], token):
                    existing.add(image.tag)
                    status("Exists", image.ref)
                else:
                    status("Uploading", image.ref)
                    plan.upload(image)
                    uploaded.append(image)
                    status("Uploaded", image.ref)
        else:
            status("Skipped", "Upload declined.")
            show_retry(missing)
            print(f"\nDone. 0 uploaded. {len(existing)} already existed.", flush=True)
            return 0

        stage = "Update the Docker Hub description"
        step(5, stage)
        if plan.description is None:
            status("Skipped", "Upload-only mode uses the existing description.")
        else:
            summary, description = plan.description
            print(description, flush=True)
            if confirm("Update the repository description?"):
                token = dockerhub.access_token(account)
                dockerhub.update_description(namespace, repository, summary, description, token)
                status("Updated", f"{namespace}/{repository}")
            else:
                status("Skipped", "Description update declined.")
    except (OSError, RuntimeError, TypeError, ValueError, KeyError, subprocess.CalledProcessError, EOFError) as error:
        print(f"\nFailed. {stage}. {error}", file=sys.stderr)
        print(f"{len(uploaded)} uploaded. {len(existing)} already existed.", file=sys.stderr)
        if stage == "Upload images":
            show_retry(missing)
        return 1

    print(f"\nDone. {len(uploaded)} uploaded. {len(existing)} already existed.", flush=True)
    return 0


def entry_point(main: Callable[[], int]) -> None:
    try:
        result = main()
    except (OSError, RuntimeError, TypeError, ValueError) as error:
        print(f"Error. {error}", file=sys.stderr)
        result = 1
    except KeyboardInterrupt:
        print("\nStopped.", file=sys.stderr)
        result = 130
    raise SystemExit(result)
