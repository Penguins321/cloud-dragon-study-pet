#!/bin/bash
# Source-development launcher for macOS (compatible with the system Bash).
set -u

fail() {
    printf '\n%s\n' "$1" >&2
    if [[ -t 0 ]]; then
        read -r -p '按回车键关闭此窗口…' || true
    fi
    exit "${2:-1}"
}

ROOT="$(cd "$(dirname "$0")" && pwd)" || exit 1
PROJECT="$ROOT/desktop-pet"
[[ -f "$PROJECT/project.godot" ]] || fail "找不到项目：$PROJECT/project.godot，请将启动文件保留在源码根目录。"

godot_engine="${GODOT:-}"
if [[ -z "$godot_engine" ]]; then
    for candidate in /Applications/Godot.app "$HOME/Applications/Godot.app"; do
        if [[ -x "$candidate/Contents/MacOS/Godot" ]]; then
            godot_engine="$candidate/Contents/MacOS/Godot"
            break
        fi
    done
    if [[ -z "$godot_engine" ]]; then
        godot_engine="$(command -v godot || command -v godot4 || true)"
    fi
    if [[ -z "$godot_engine" ]]; then
        for candidate in /opt/homebrew/bin/godot /usr/local/bin/godot; do
            if [[ -x "$candidate" ]]; then
                godot_engine="$candidate"
                break
            fi
        done
    fi
fi
if [[ "$godot_engine" == *.app ]]; then
    godot_engine="$godot_engine/Contents/MacOS/Godot"
fi
[[ -n "$godot_engine" && -x "$godot_engine" ]] || fail '未找到 Godot 4.7.2 标准版。请安装到 /Applications/Godot.app 或 ~/Applications/Godot.app；也可通过 GODOT 环境变量指定 Godot.app 或可执行文件。'

actual_version="$("$godot_engine" --version 2>&1)"
version_status=$?
[[ "$version_status" -eq 0 ]] || fail "无法运行 Godot：$actual_version" "$version_status"
case "$actual_version" in
    4.7.2.stable*) ;;
    *) fail "当前 Godot 版本：$actual_version。本项目需要 Godot 4.7.2 标准版。" ;;
esac

printf '正在导入温玉灵核源码资源…\n'
"$godot_engine" --headless --editor --path "$PROJECT" --import
import_status=$?
[[ "$import_status" -eq 0 ]] || fail '资源导入失败，请查看上方 Godot 日志。' "$import_status"

printf '正在启动温玉灵核…\n'
"$godot_engine" --path "$PROJECT" "$@"
run_status=$?
[[ "$run_status" -eq 0 ]] || fail "启动失败，Godot 退出码：$run_status。请查看上方日志。" "$run_status"
