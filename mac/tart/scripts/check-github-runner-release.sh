#!/bin/bash

set -eo pipefail

if ! latest_tag="$(curl --fail --silent --show-error --location --max-time 10 \
    https://api.github.com/repos/actions/runner/releases/latest |
    plutil -extract tag_name raw -expect string -o - -- -)" ||
    [[ ! "$latest_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Warning: Could not check the latest GitHub Actions runner release. Using pinned version $GITHUB_RUNNER_VERSION." >&2
  exit 0
fi

latest_version="${latest_tag#v}"
highest_version="$(printf '%s\n' "$GITHUB_RUNNER_VERSION" "$latest_version" | sort -V | tail -n 1)"

if [[ "$latest_version" != "$GITHUB_RUNNER_VERSION" && "$latest_version" == "$highest_version" ]]; then
  echo "Warning: GitHub Actions runner $latest_version is available. This image uses $GITHUB_RUNNER_VERSION." >&2
  echo "Update the runner version and ARM64 checksum in matee.pkr.hcl. https://github.com/actions/runner/releases/tag/$latest_tag" >&2
fi
