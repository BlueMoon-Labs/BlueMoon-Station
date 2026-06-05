#!/bin/bash
set -euo pipefail

source dependencies.sh

BINARY="$1"

case "$BINARY" in
	dreamchecker) EXPECTED_SHA256="$SPACEMAN_DMM_DREAMCHECKER_SHA256" ;;
	dmdoc) EXPECTED_SHA256="$SPACEMAN_DMM_DMDOC_SHA256" ;;
	*) echo "ERROR: unknown SpacemanDMM binary '$BINARY'." >&2; exit 1 ;;
esac

verify_checksum() {
	echo "${EXPECTED_SHA256}  $1" | sha256sum -c - >/dev/null 2>&1
}

if [ ! -f ~/"$BINARY" ]; then
	mkdir -p "$HOME/SpacemanDMM"
	CACHEFILE="$HOME/SpacemanDMM/$BINARY"

	# Re-download if the cache is missing, the wrong version, or fails the pinned checksum.
	if ! [ -f "$CACHEFILE.version" ] || ! grep -Fxq "$SPACEMAN_DMM_VERSION" "$CACHEFILE.version" || ! verify_checksum "$CACHEFILE"; then
		for attempt in 1 2 3; do
			if wget -nv -O "$CACHEFILE" "https://github.com/SpaceManiac/SpacemanDMM/releases/download/$SPACEMAN_DMM_VERSION/$BINARY"; then
				break
			fi
			echo "$BINARY download failed (attempt ${attempt}/3), retrying..." >&2
			sleep 3
		done

		if ! verify_checksum "$CACHEFILE"; then
			echo "ERROR: $BINARY checksum mismatch for ${SPACEMAN_DMM_VERSION}." >&2
			echo "Expected: ${EXPECTED_SHA256}" >&2
			echo "Actual:   $(sha256sum "$CACHEFILE" 2>/dev/null | awk '{print $1}')" >&2
			exit 1
		fi

		chmod +x "$CACHEFILE"
		echo "$SPACEMAN_DMM_VERSION" >"$CACHEFILE.version"
	fi

	ln -s "$CACHEFILE" ~/"$BINARY"
fi

~/"$BINARY" --version
