#!/bin/bash

set -e

downloads_dir="$HOME/Downloads"

# Accept version arguments when run directly from a terminal.
if [[ $# -gt 0 ]]; then
  versions=("$@")
else
  read -r -a versions <<< "$XCODE_VERSIONS"
fi

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
    # Send Apple sign-in prompts to the terminal when one is available.
    if { exec 3<>/dev/tty; } 2>/dev/null; then
      xcodes download "$version" --directory "$staging_dir" <&3 >&3 2>&3
    elif ! xcodes download "$version" --directory "$staging_dir" </dev/null; then
      echo "Could not download Xcode $version. Run scripts/download-xcode-archives.sh $version from a terminal on the build Mac, then retry the build." >&2
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
