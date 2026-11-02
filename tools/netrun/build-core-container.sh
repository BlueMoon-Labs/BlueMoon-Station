#!/bin/sh
# Build-only SDK stage: проверяет точный local source context и собирает Host плюс BYOND x86 bridge.
set -eu
cd /netrun-core
test -n "${NETRUN_CORE_DIGEST:-}" || { echo 'netrun_core_digest_required' >&2; exit 2; }
test "$(sha256sum source-files.sha256 | cut -d ' ' -f 1)" = "$NETRUN_CORE_DIGEST" || { echo 'netrun_core_manifest_mismatch' >&2; exit 2; }
if find . -type l | grep -q .; then echo 'netrun_core_symlink' >&2; exit 2; fi
find . -type f ! -path './source-files.sha256' ! -path './source-manifest.json' -printf '%P\n' | LC_ALL=C sort >/tmp/netrun-actual-files
cut -c 67- source-files.sha256 | LC_ALL=C sort >/tmp/netrun-expected-files
cmp --silent /tmp/netrun-actual-files /tmp/netrun-expected-files || { echo 'netrun_core_unlisted_file' >&2; exit 2; }
sha256sum --check source-files.sha256 >/dev/null
dotnet restore src/Netrun.Host/Netrun.Host.csproj --locked-mode
dotnet publish src/Netrun.Host/Netrun.Host.csproj --configuration Release --no-restore --output /netrun-output/host /p:UseAppHost=false

# Официальный release 0.17.0; SHA-256 проверен по https://ziglang.org/download/index.json.
# Target glibc 2.17 остаётся совместимым с Ubuntu Xenial в существующем BYOND image.
netrun_archive='zig-x86_64-linux-0.17.0.tar.xz'
netrun_hash='1cbe9df9f27e6b78d14ccbca43b6703a404ef79ef1c463de901d7f088d4e2026'
printf '%s\n' "https://ziglang.org/download/0.17.0/$netrun_archive" >/tmp/netrun-zig-sources
# Community mirrors меняют только транспорт: доверие задаёт reviewed release hash в исходниках.
# Список ограничен HTTPS URLs: проверенный доступный Fastly mirror и ещё один случайный,
# либо два случайных, если Fastly больше не входит в опубликованный список.
if curl --fail --location --connect-timeout 15 --max-time 30 \
    'https://ziglang.org/download/community-mirrors.txt' --output /tmp/netrun-zig-mirrors; then
    tr -d '\r' </tmp/netrun-zig-mirrors | grep -E '^https://[A-Za-z0-9.-]+(/[A-Za-z0-9._/-]+)?$' >/tmp/netrun-zig-valid-mirrors
    if grep -Fxq 'https://ziglang.freetls.fastly.net' /tmp/netrun-zig-valid-mirrors; then
        printf '%s\n' "https://ziglang.freetls.fastly.net/$netrun_archive?source=netrun-core" >>/tmp/netrun-zig-sources
        grep -Fxv 'https://ziglang.freetls.fastly.net' /tmp/netrun-zig-valid-mirrors | shuf -n 1 \
            | sed "s|$|/$netrun_archive?source=netrun-core|" >>/tmp/netrun-zig-sources
    else
        shuf -n 2 /tmp/netrun-zig-valid-mirrors | sed "s|$|/$netrun_archive?source=netrun-core|" >>/tmp/netrun-zig-sources
    fi
fi
netrun_downloaded=0
while IFS= read -r netrun_url; do
    if curl --fail --location --connect-timeout 20 --max-time 300 --speed-limit 1024 --speed-time 30 \
        "$netrun_url" --output /tmp/netrun-zig.tar.xz \
        && printf '%s  %s\n' "$netrun_hash" /tmp/netrun-zig.tar.xz | sha256sum --check -; then
        netrun_downloaded=1
        break
    fi
    rm -f /tmp/netrun-zig.tar.xz
done </tmp/netrun-zig-sources
test "$netrun_downloaded" = 1 || { echo 'netrun_zig_download_failed' >&2; exit 2; }
mkdir -p /opt/netrun-zig
tar --extract --xz --file /tmp/netrun-zig.tar.xz --strip-components=1 --directory /opt/netrun-zig
/opt/netrun-zig/zig c++ -std=c++17 -shared -O2 -Wall -Wextra -Werror -fvisibility=hidden \
    -target x86-linux-gnu.2.17 native/netrun_bridge.cpp -pthread -ldl \
    -Wl,--version-script=native/netrun_bridge.map -o /netrun-output/libnetrun_bridge.so
cp source-files.sha256 source-manifest.json /netrun-output/
