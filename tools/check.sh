#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64}"
if [[ ! -x "$engine" ]]; then engine="$(command -v godot)"; fi
version="$("$engine" --version)"
[[ "$version" == 4.7.2.stable.* ]] || { echo "Godot 4.7.2 Stable benötigt, gefunden: $version" >&2; exit 1; }
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/sternenbruch-check/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/sternenbruch-check/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/sternenbruch-check/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
log_dir="${STERNENBRUCH_LOG_DIR:-/tmp/sternenbruch-check/logs}"
mkdir -p "$log_dir"
check() {
 local name="$1"; shift
 if ! timeout 180 "$engine" "$@" >"$log_dir/$name.log" 2>&1; then cat "$log_dir/$name.log"; return 1; fi
 cat "$log_dir/$name.log"
 if rg -q 'SCRIPT ERROR|ERROR:|FAIL |instances were leaked' "$log_dir/$name.log"; then return 1; fi
}
check import --headless --editor --path . --quit
check unit --headless --path . -s res://tests/test_runner.gd
check mutations --headless --path . -s res://tests/mutation_runner.gd
check rifts --headless --path . -s res://tests/rift_runner.gd
check reactions --headless --path . -s res://tests/reaction_runner.gd
check constellations --headless --path . -s res://tests/constellation_runner.gd
check polish --headless --path . -s res://tests/polish_runner.gd
check catalog --headless --path . -s res://tests/catalog_runner.gd
if [[ "${1:-}" == "--long" ]]; then
 check stress --headless --path . -s res://tests/stress_runner.gd
 check full-run --headless --path . -s res://tests/full_run_runner.gd
fi
