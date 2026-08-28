#!/usr/bin/env bash
set -Eeuo pipefail

exec start_emulator.sh --window "$@"
