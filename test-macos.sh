#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
mkdir -p "$ROOT/.tools"
export CLOUD_DRAGON_DATA_DIR="$(mktemp -d "$ROOT/.tools/mac-tests.XXXXXX")"
export CLOUD_DRAGON_TEST_DIR="$CLOUD_DRAGON_DATA_DIR"
"$GODOT" --headless --editor --path "$ROOT/desktop-pet" --import
for script in run_tests check_macos_startup test_warm_jade test_big_motion test_motion_v13 check_flame_flow test_appearance_settings check_appearance_persistence; do
  "$GODOT" --headless --path "$ROOT/desktop-pet" --script "res://tests/$script.gd"
done
