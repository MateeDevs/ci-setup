#!/bin/bash

set -euo pipefail

# Read the version and ARM64 checksum from the same stable release.
release_metadata="$(
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

# Keep the download and extracted files in a temporary directory until checked.
staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT
archive="$staging_dir/$archive_name"

echo "Installing GitHub Actions runner $runner_version for macOS ARM64"
curl --fail --location --silent --show-error --retry 2 \
  --output "$archive" "https://github.com/actions/runner/releases/download/v$runner_version/$archive_name"
printf '%s  %s\n' "$runner_sha256" "$archive" | shasum -a 256 -c -

mkdir "$staging_dir/actions-runner"
tar -xzf "$archive" -C "$staging_dir/actions-runner"
test "$("$staging_dir/actions-runner/bin/Runner.Listener" --version)" = "$runner_version"

# Keep any runner that is already installed.
test ! -e "$HOME/actions-runner"
mv "$staging_dir/actions-runner" "$HOME/actions-runner"
