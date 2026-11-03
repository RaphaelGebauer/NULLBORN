#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64}"
[[ "$("$engine" --version)" == 4.7.2.stable.* ]]
: "${DISPLAY:?Set DISPLAY to an existing X11 display}"
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-true}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/sternenbruch-graphical/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/sternenbruch-graphical/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/sternenbruch-graphical/cache}"
log_dir="${STERNENBRUCH_LOG_DIR:-/tmp/sternenbruch-graphical/logs}"
mkdir -p "$log_dir" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
run() {
 local name="$1"; shift
 timeout 180 "$engine" --path . --rendering-method gl_compatibility --audio-driver Dummy "$@" >"$log_dir/$name.log" 2>&1
 cat "$log_dir/$name.log"
 if rg -q 'SCRIPT ERROR|ERROR:|FAIL |instances were leaked|Embedded window can.t be resized' "$log_dir/$name.log"; then return 1; fi
}
if [[ "${1:-}" == "--wid" ]]; then
 run embedded --wid "$2" -s res://tests/window_runner.gd
 run embedded-ui --wid "$2" -s res://tests/embedded_ui_runner.gd
else
 run window -s res://tests/window_runner.gd
 run visual -s res://tests/visual_runner.gd
 run mutation-visual -s res://tests/mutation_visual_runner.gd
 run rift-visual -s res://tests/rift_visual_runner.gd
 run reaction-visual -s res://tests/reaction_visual_runner.gd
 run star-visual -s res://tests/star_visual_runner.gd
 run polish-visual -s res://tests/polish_visual_runner.gd
 run maintenance-visual -s res://tests/maintenance_visual_runner.gd
 run ui-fixes-visual -s res://tests/ui_fixes_visual_runner.gd
 run ui-text-visual -s res://tests/ui_text_runner.gd
 run layout-visual -s res://tests/layout_visual_runner.gd
 run render-readonly -s res://tests/render_readonly_runner.gd
fi
