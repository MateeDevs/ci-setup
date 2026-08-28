#!/usr/bin/env bash
set -Eeuo pipefail

display="${XVFB_DISPLAY:-:1}"
screen="${XVFB_SCREEN:-0}"
resolution="${XVFB_RESOLUTION:-1280x1024x24}"
startup_timeout="${XVFB_TIMEOUT:-10}"

export DISPLAY="${display}"

Xvfb "${display}" -screen "${screen}" "${resolution}" >/tmp/xvfb.log 2>&1 &
xvfb_pid=$!

deadline=$((SECONDS + startup_timeout))
until xdpyinfo -display "${display}" >/dev/null 2>&1; do
    if ! kill -0 "${xvfb_pid}" 2>/dev/null || (( SECONDS >= deadline )); then
        echo "[ERROR] Xvfb failed to start" >&2
        cat /tmp/xvfb.log >&2 || true
        exit 1
    fi
    sleep 1
done

fluxbox >/tmp/fluxbox.log 2>&1 &
fluxbox_pid=$!
deadline=$((SECONDS + startup_timeout))
until wmctrl -m >/dev/null 2>&1; do
    if ! kill -0 "${fluxbox_pid}" 2>/dev/null || (( SECONDS >= deadline )); then
        echo "[ERROR] Fluxbox failed to start" >&2
        cat /tmp/fluxbox.log >&2 || true
        exit 1
    fi
    sleep 1
done

password_args=(-nopw)
if [[ -n "${VNC_PASSWORD:-}" ]]; then
    password_file=/tmp/x11vnc.pass
    x11vnc -storepasswd "${VNC_PASSWORD}" "${password_file}" >/dev/null
    chmod 0600 "${password_file}"
    password_args=(-rfbauth "${password_file}")
else
    echo "[WARN] VNC is running without a password" >&2
fi

exec x11vnc \
    -display "${display}" \
    -forever \
    -shared \
    -ncache_cr \
    "${password_args[@]}"
