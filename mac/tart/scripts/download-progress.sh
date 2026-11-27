#!/bin/bash

set -e

label=$1
shift
track='....................'
printf '[====................] %s (elapsed 0 s)\n' "$label" >&2

SECONDS=0
parent=$$
(
  position=0
  while sleep 30 </dev/null >/dev/null 2>&1 && kill -0 "$parent" 2>/dev/null; do
    position=$(((position + 4) % 20))
    printf '[%s====%s] %s (elapsed %s s)\n' \
      "${track:0:position}" "${track:position+4}" "$label" "$SECONDS" >&2
  done
) &
reporter=$!

stop_reporter() {
  kill "$reporter" 2>/dev/null || true
  wait "$reporter" 2>/dev/null || true
}

trap stop_reporter EXIT
exit_code=0
"$@" || exit_code=$?
stop_reporter
trap - EXIT

if [[ "$exit_code" -eq 0 ]]; then
  printf '[====================] %s (done in %s s)\n' "$label" "$SECONDS" >&2
else
  printf '[--------------------] %s (failed after %s s)\n' "$label" "$SECONDS" >&2
fi
exit "$exit_code"
