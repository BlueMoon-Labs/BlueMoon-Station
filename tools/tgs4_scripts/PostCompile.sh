#!/bin/sh
set -eu

game_dir="${1:?TGS did not provide the game directory}"
event_scripts_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
python3 "$game_dir/tools/rsc_deploy/rsc_deploy.py" publish \
	--game-dir "$game_dir" \
	--config "$event_scripts_dir/../GameStaticFiles/config/rsc_deploy.env"
