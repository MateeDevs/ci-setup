#!/bin/bash

set -e

downloads_dir="$HOME/Downloads"

if [[ $# -eq 0 ]]; then
  echo "Usage: ${0##*/} <version> [<version> ...]" >&2
  exit 1
fi

for version in "$@"; do
  archive="$downloads_dir/Xcode_$version.xip"
  if [[ -f "$archive" ]]; then
    echo "Using $archive"
    continue
  fi

  if ! command -v xcodes >/dev/null; then
    echo "Install xcodes on the build Mac to download Xcode $version." >&2
    exit 1
  fi

  mkdir -p "$downloads_dir"
  (
    # Keep partial downloads out of the archive path.
    staging_dir="$(mktemp -d "$downloads_dir/.xcodes.XXXXXXXX")"
    trap 'rm -rf "$staging_dir"' EXIT

    echo "Downloading Xcode $version"
    if ! xcodes download "$version" --directory "$staging_dir"; then
      echo "Could not download Xcode $version." >&2
      echo "You can also download the XIP from https://developer.apple.com/download/all/ and save it as $archive." >&2
      exit 1
    fi

    shopt -s nullglob
    archives=("$staging_dir"/*.xip)
    if [[ ${#archives[@]} -ne 1 || ! -f "${archives[0]}" ]]; then
      echo "Expected one XIP archive for Xcode $version." >&2
      exit 1
    fi

    # Keep any archive placed at this path while the download was running.
    mv -n "${archives[0]}" "$archive"
    echo "Using $archive"
  )
done
