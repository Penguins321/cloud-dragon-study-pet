#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
mkdir -p "$ROOT/.tools"
export CLOUD_DRAGON_DATA_DIR="$(mktemp -d "$ROOT/.tools/mac-tests.XXXXXX")"
export CLOUD_DRAGON_TEST_DIR="$CLOUD_DRAGON_DATA_DIR"
"$GODOT" --headless --editor --path "$ROOT/desktop-pet" --import
for script in test_autonomous_mind test_screen_roaming test_ai_core test_ai_models test_ai_memory test_ai_settings test_ai_chat_ui test_ai_bubble test_ai_integration test_ai_chat_integration test_ai_interaction run_tests check_macos_startup check_crystal_only check_spatial_actions test_warm_jade test_big_motion test_motion_v13 test_appearance_settings check_renderer_mode check_font_scale check_appearance_persistence check_data_tools check_companion_models check_v016_ui check_v016_integration; do
  export CLOUD_DRAGON_DATA_DIR="$(mktemp -d "$ROOT/.tools/mac-case.XXXXXX")"
  "$GODOT" --headless --path "$ROOT/desktop-pet" --script "res://tests/$script.gd"
done
