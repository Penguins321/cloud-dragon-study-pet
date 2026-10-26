# Windows Startup Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** 设置页支持当前用户登录 Windows 后启动桌宠。

**Architecture:** 一个 desktop/startup.gd 管理 Startup 快捷方式，settings_panel.gd 发出开关信号，main.gd 协调状态与错误反馈。快捷方式作为唯一状态来源。

**Tech Stack:** Godot 4.7.2 GDScript、Windows PowerShell、WScript.Shell。

**Spec:** docs/superpowers/specs/2026-10-26-windows-startup-design.md

## Global Constraints

不新增依赖、不提权、不写全用户启动项、不重置学习进度、不主动开启。测试操作临时目录。

## Review Focus

中文、空格、单引号等路径必须保真；重复启用禁用幂等；写入失败反馈实际状态；编辑器和隔离运行不得修改系统启动；目标 EXE 与工作目录须正确。

## Task 1: 自启动服务与设置接入

Files: 新建 desktop-pet/desktop/startup.gd、desktop-pet/tests/test_startup.gd；修改 settings_panel.gd、main.gd、tests/run_tests.gd。

- [x] 先增加真实临时快捷方式开关、重复开关、路径保真、无效目标和设置页信号测试；运行确认缺失服务导致失败。
- [x] 实现 Startup.new(directory_override := "", executable_override := "")、is_enabled()、set_enabled(bool) -> Error，提供 available、message 状态。
- [x] 设置页接入开关与状态说明，main 每次打开设置刷新实际状态，失败显示原因。
- [x] 运行 test-prototype.ps1；渲染设置页检查布局；导出并运行新 EXE；更新操作说明并单独提交。

验证记录：194 checks / 0 failures，温玉灵核动作检查通过。自启动专项 16 项，使用临时目录中的真实 `.lnk`，包含中文 / 单引号 / shell 特殊字符目录。Windows COM 对 TargetPath 与 WorkingDirectory 的斜杠保留方式不同，生产代码统一写 Windows 反斜杠后验证通过。无法创建目录的测试会产生一条预期 Godot 错误日志，不代表测试失败。

独立审查：review_startup 无可执行发现。设置页实际渲染已检查。Ruling: 本轮在当前用户明确要求提交改动的现有工作区原地完成，避免在提交既有改动后切换工作区；自启动行为使用单独提交。旧 v0.6 导出目标重命名失败，改用新版本 v0.7 文件名交付，不修改或结束其他进程。

最终导出验证：WarmJadePrototype-v0.7.exe 启动并打开设置页，退出码 0，日志无运行错误。当前用户 Startup 路径只读解析已验证，未为用户实际开启开关；未进行重启登录测试。
