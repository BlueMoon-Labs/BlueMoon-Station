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
curl --fail --location --retry 3 'https://ziglang.org/download/0.17.0/zig-x86_64-linux-0.17.0.tar.xz' --output /tmp/netrun-zig.tar.xz
printf '%s  %s\n' '1cbe9df9f27e6b78d14ccbca43b6703a404ef79ef1c463de901d7f088d4e2026' /tmp/netrun-zig.tar.xz | sha256sum --check -
mkdir -p /opt/netrun-zig
tar --extract --xz --file /tmp/netrun-zig.tar.xz --strip-components=1 --directory /opt/netrun-zig
/opt/netrun-zig/zig c++ -std=c++17 -shared -O2 -Wall -Wextra -Werror -fvisibility=hidden \
    -target x86-linux-gnu.2.17 native/netrun_bridge.cpp -pthread -ldl \
    -Wl,--version-script=native/netrun_bridge.map -o /netrun-output/libnetrun_bridge.so
cp source-files.sha256 source-manifest.json /netrun-output/
