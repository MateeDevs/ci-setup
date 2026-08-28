#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    echo "Usage: start_emulator.sh [--headless|--window] [extra emulator arguments...]" >&2
}

mode="${1:---headless}"
case "${mode}" in
    --headless|--window)
        shift || true
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        usage
        exit 2
        ;;
esac

emulator_name="${EMULATOR_NAME:?EMULATOR_NAME is required}"
emulator_port="${EMULATOR_PORT:-5554}"
emulator_timeout="${EMULATOR_TIMEOUT:-300}"
emulator_gpu="${EMULATOR_GPU:-software}"
emulator_log="${EMULATOR_LOG_FILE:-/tmp/android-emulator.log}"
emulator_pid_file="${EMULATOR_PID_FILE:-/tmp/android-emulator.pid}"
emulator_serial="emulator-${emulator_port}"

if [[ ! "${emulator_port}" =~ ^[0-9]+$ ]] || (( emulator_port < 5554 || emulator_port > 5682 || emulator_port % 2 != 0 )); then
    echo "EMULATOR_PORT must be an even number from 5554 through 5682" >&2
    exit 2
fi

if [[ ! "${emulator_timeout}" =~ ^[0-9]+$ ]] || (( emulator_timeout < 1 )); then
    echo "EMULATOR_TIMEOUT must be a positive number of seconds" >&2
    exit 2
fi

if [[ -n "${EMULATOR_ACCEL:-}" ]]; then
    emulator_accel="${EMULATOR_ACCEL}"
elif [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    emulator_accel="on"
else
    emulator_accel="off"
    echo "[WARN] /dev/kvm is unavailable; using slow software CPU emulation" >&2
fi

adb start-server >/dev/null
if adb -s "${emulator_serial}" get-state >/dev/null 2>&1; then
    adb -s "${emulator_serial}" emu kill >/dev/null 2>&1 || true
    sleep 2
fi

emulator_args=(
    -avd "${emulator_name}"
    -port "${emulator_port}"
    -no-boot-anim
    -no-snapshot
    -gpu "${emulator_gpu}"
    -accel "${emulator_accel}"
)

if [[ "${mode}" == "--headless" ]]; then
    emulator_args+=(-no-window -no-audio)
fi

echo "[INFO] Starting ${emulator_name} as ${emulator_serial} (GPU=${emulator_gpu}, acceleration=${emulator_accel})"
nohup emulator "${emulator_args[@]}" "$@" >"${emulator_log}" 2>&1 &
emulator_pid=$!
echo "${emulator_pid}" >"${emulator_pid_file}"

deadline=$((SECONDS + emulator_timeout))
while (( SECONDS < deadline )); do
    if ! kill -0 "${emulator_pid}" 2>/dev/null; then
        echo "[ERROR] Emulator exited before completing boot; log follows:" >&2
        tail -n 100 "${emulator_log}" >&2 || true
        exit 1
    fi

    boot_completed="$(adb -s "${emulator_serial}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [[ "${boot_completed}" == "1" ]]; then
        echo "[INFO] Emulator is ready"
        adb devices -l
        adb -s "${emulator_serial}" shell input keyevent 82 >/dev/null 2>&1 || true
        adb -s "${emulator_serial}" shell settings put global window_animation_scale 0.0
        adb -s "${emulator_serial}" shell settings put global transition_animation_scale 0.0
        adb -s "${emulator_serial}" shell settings put global animator_duration_scale 0.0
        adb -s "${emulator_serial}" shell settings put global hidden_api_policy_pre_p_apps 1 || true
        adb -s "${emulator_serial}" shell settings put global hidden_api_policy_p_apps 1 || true
        adb -s "${emulator_serial}" shell settings put global hidden_api_policy 1 || true
        exit 0
    fi

    sleep 2
done

echo "[ERROR] Emulator did not boot within ${emulator_timeout} seconds; log follows:" >&2
tail -n 100 "${emulator_log}" >&2 || true
kill "${emulator_pid}" 2>/dev/null || true
exit 1
