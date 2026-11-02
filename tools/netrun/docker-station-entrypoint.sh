#!/bin/bash
# Namespace контейнера создаётся до Host sidecar; сам DreamDaemon ждёт готовый loopback listener.
set -eu
mode="${NETRUN_CORE_MODE:-external}"
case "$mode" in
    external) ;;
    *) echo 'netrun_invalid_mode' >&2; exit 2 ;;
esac
port="${NETRUN_CORE_PORT:-18462}"
case "$port" in ''|0*|*[!0-9]*) echo 'netrun_invalid_port' >&2; exit 2 ;; esac
if [ "$port" -gt 65535 ] || [ ! -r "${NETRUN_CORE_TOKEN_FILE:-/run/secrets/netrun_session_token}" ]; then
    echo 'netrun_configuration_unavailable' >&2
    exit 2
fi
# Windows bind mounts и Compose secrets могут иметь inode > UINT32_MAX.
# 32-bit BYOND stat/open отказывает даже при доступном для bash файле.
# Native filesystem copy сохраняет внешний config read-only и не раскрывает token в argv/logs.
config_source="${NETRUN_CONFIG_SOURCE:-/run/netrun/config-source}"
if [ ! -d "$config_source" ]; then
    echo 'netrun_config_directory_unavailable' >&2
    exit 2
fi
mkdir -p /tgstation/config /run/netrun
cp -R "$config_source"/. /tgstation/config/
umask 077
cp "${NETRUN_CORE_TOKEN_FILE:-/run/secrets/netrun_session_token}" /run/netrun/session-token
chmod 600 /run/netrun/session-token
export NETRUN_CORE_TOKEN_FILE=/run/netrun/session-token
deadline=$((SECONDS + 60))
until (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; do
    if [ "$SECONDS" -ge "$deadline" ]; then
        echo 'netrun_host_start_timeout' >&2
        exit 2
    fi
    sleep 0.1
done
exec DreamDaemon "$@"
