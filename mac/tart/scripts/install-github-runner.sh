#!/bin/bash

set -euo pipefail

# Read the version and ARM64 checksum from the same stable release.
release_metadata="$(
  bash /tmp/matee-download-progress.sh 'Get the GitHub Actions runner version' \
    curl --fail --location --silent --show-error --retry 2 --max-time 15 \
    https://api.github.com/repos/actions/runner/releases/latest |
    /usr/bin/ruby -rjson -e '
      release = JSON.parse(STDIN.read)
      tag = release.fetch("tag_name")
      abort "Invalid runner release tag #{tag}" unless /\Av\d+\.\d+\.\d+\z/.match?(tag)

      version = tag.delete_prefix("v")
      archive_name = "actions-runner-osx-arm64-#{version}.tar.gz"
      asset = release.fetch("assets").find { |entry| entry["name"] == archive_name }
      digest = asset && asset["digest"]
      abort "Missing SHA-256 digest for #{archive_name}" unless digest && /\Asha256:[0-9a-f]{64}\z/.match?(digest)

      puts "#{version} #{digest.delete_prefix("sha256:")}"
    '
)"
read -r runner_version runner_sha256 <<< "$release_metadata"

archive_name="actions-runner-osx-arm64-$runner_version.tar.gz"
runner_dir="$HOME/actions-runner"

# Keep the old runner until the new runner is in place.
staging_dir="$(mktemp -d "$HOME/.actions-runner.XXXXXXXX")"
previous_runner="$staging_dir/previous"
cleanup() {
  if [[ -d "$previous_runner" && ! -e "$runner_dir" && ! -L "$runner_dir" ]]; then
    if ! mv "$previous_runner" "$runner_dir"; then
      printf 'Could not restore the previous runner. It is at %s.\n' "$previous_runner" >&2
      return 1
    fi
  fi
  rm -rf "$staging_dir"
}
trap cleanup EXIT
archive="$staging_dir/$archive_name"

echo "Installing GitHub Actions runner $runner_version for macOS ARM64"
bash /tmp/matee-download-progress.sh "Download GitHub Actions runner $runner_version" \
  curl --fail --location --silent --show-error --retry 2 \
  --output "$archive" "https://github.com/actions/runner/releases/download/v$runner_version/$archive_name"
printf '%s  %s\n' "$runner_sha256" "$archive" | shasum -a 256 -c -

new_runner="$staging_dir/actions-runner"
echo "Extracting GitHub Actions runner $runner_version"
mkdir "$new_runner"
tar -xzf "$archive" -C "$new_runner"
if ! installed_version="$("$new_runner/bin/Runner.Listener" --version)"; then
  printf 'Could not read the version of the extracted runner. Output: %s\n' "$installed_version" >&2
  exit 1
fi
if [[ "$installed_version" != "$runner_version" ]]; then
  printf 'Expected runner version %s. The extracted runner reported %s.\n' "$runner_version" "$installed_version" >&2
  exit 1
fi

# The Tart base image can include an unconfigured runner.
if [[ -e "$runner_dir" || -L "$runner_dir" ]]; then
  if [[ -L "$runner_dir" || ! -x "$runner_dir/bin/Runner.Listener" ||
        -e "$runner_dir/.runner" || -e "$runner_dir/.credentials" ||
        -e "$runner_dir/.service" ]]; then
    printf 'Cannot replace the runner at %s. The path is configured or is not a runner directory.\n' "$runner_dir" >&2
    exit 1
  fi
  echo "Replacing the unconfigured runner from the base image"
  mv "$runner_dir" "$previous_runner"
fi

mv "$new_runner" "$runner_dir"
printf 'Installed GitHub Actions runner %s in %s.\n' "$runner_version" "$runner_dir"
