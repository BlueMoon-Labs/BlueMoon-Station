#!/bin/bash
# Namespace контейнера создаётся до Host sidecar; сам DreamDaemon ждёт готовый loopback listener.
set -eu
mode="${NETRUN_CORE_MODE:-external}"
case "$mode" in
    dm) exec DreamDaemon "$@" ;;
    external|shadow) ;;
    *) echo 'netrun_invalid_mode' >&2; exit 2 ;;
esac
port="${NETRUN_CORE_PORT:-18462}"
case "$port" in ''|0*|*[!0-9]*) echo 'netrun_invalid_port' >&2; exit 2 ;; esac
if [ "$port" -gt 65535 ] || [ ! -r "${NETRUN_CORE_TOKEN_FILE:-/run/secrets/netrun_session_token}" ]; then
    echo 'netrun_configuration_unavailable' >&2
    exit 2
fi
deadline=$((SECONDS + 60))
until (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; do
    if [ "$SECONDS" -ge "$deadline" ]; then
        echo 'netrun_host_start_timeout' >&2
        exit 2
    fi
    sleep 0.1
done
exec DreamDaemon "$@"
