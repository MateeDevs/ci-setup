#!/bin/bash

set -e

downloads_dir="$HOME/Downloads"
read -r -a versions <<< "$XCODE_VERSIONS"

for version in "${versions[@]}"; do
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
    xcodes download "$version" --directory "$staging_dir"

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
