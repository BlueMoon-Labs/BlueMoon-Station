#!/usr/bin/env bash
set -euo pipefail

source dependencies.sh

TARGET="$HOME/.byond/bin/libauxmos.so"
URL="https://github.com/Putnam3145/auxmos/releases/download/${AUXMOS_VERSION}/libauxmos.so"

mkdir -p "$HOME/.byond/bin"

verify_checksum() {
	echo "${AUXMOS_SHA256}  ${TARGET}" | sha256sum -c - >/dev/null 2>&1
}

# Reuse a cached copy (e.g. from actions/cache) only if it matches the pinned hash.
if [ -f "$TARGET" ] && verify_checksum; then
	echo "Using cached libauxmos.so ($AUXMOS_VERSION)."
else
	for attempt in 1 2 3; do
		if wget -nv -O "$TARGET" "$URL"; then
			break
		fi
		echo "libauxmos.so download failed (attempt ${attempt}/3), retrying..." >&2
		sleep 3
	done

	if ! verify_checksum; then
		echo "ERROR: libauxmos.so checksum mismatch for ${AUXMOS_VERSION}." >&2
		echo "Expected: ${AUXMOS_SHA256}" >&2
		echo "Actual:   $(sha256sum "$TARGET" 2>/dev/null | awk '{print $1}')" >&2
		exit 1
	fi
fi

chmod +x "$TARGET"
ldd "$TARGET"
