#!/bin/bash

set -e

read -r -a versions <<< "$XCODE_VERSIONS"
missing_versions=()

for version in "${versions[@]}"; do
  archive="$HOME/Downloads/Xcode_$version.xip"
  if [[ ! -f "$archive" ]]; then
    printf 'Missing archive %s\n' "$archive" >&2
    missing_versions+=("$version")
  fi
done

if [[ ${#missing_versions[@]} -gt 0 ]]; then
  printf 'Run this command from mac/tart on the build Mac.\n' >&2
  printf './scripts/download-xcode-archives.sh' >&2
  printf ' %q' "${missing_versions[@]}" >&2
  printf '\n' >&2
  exit 1
fi
