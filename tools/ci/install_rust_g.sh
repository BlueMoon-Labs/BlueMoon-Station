#!/usr/bin/env bash
set -euo pipefail

source dependencies.sh

TARGET="$HOME/.byond/bin/librust_g.so"
URL="https://github.com/tgstation/rust-g/releases/download/$RUST_G_VERSION/librust_g.so"

mkdir -p "$HOME/.byond/bin"

verify_checksum() {
	echo "${RUST_G_SHA256}  ${TARGET}" | sha256sum -c - >/dev/null 2>&1
}

# Reuse a cached copy (e.g. from actions/cache) only if it matches the pinned hash.
if [ -f "$TARGET" ] && verify_checksum; then
	echo "Using cached librust_g.so ($RUST_G_VERSION)."
else
	for attempt in 1 2 3; do
		if wget -nv -O "$TARGET" "$URL"; then
			break
		fi
		echo "librust_g.so download failed (attempt ${attempt}/3), retrying..." >&2
		sleep 3
	done

	if ! verify_checksum; then
		echo "ERROR: librust_g.so checksum mismatch for ${RUST_G_VERSION}." >&2
		echo "Expected: ${RUST_G_SHA256}" >&2
		echo "Actual:   $(sha256sum "$TARGET" 2>/dev/null | awk '{print $1}')" >&2
		exit 1
	fi
fi

chmod +x "$TARGET"
ldd "$TARGET"
