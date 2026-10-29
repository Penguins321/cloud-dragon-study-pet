# 3D 动物伙伴实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox syntax.

**Goal:** 保留玉核，新增三个真正不同的 3D 伙伴、专属动作与可保存的角色选择。
**Architecture:** 共享 SkinCatalog 提供资源及动作；Node2D 包装独立透明 3D 视口，继续由 PetView 调度。设置、预览和持久化共享角色 ID。
**Tech Stack:** Godot 4.7.2 / GDScript / GLB。
**Spec:** ../specs/2026-10-30-animal-companions-design.md

## Global Constraints

- 角色 ID：warm_jade、corgi、duck、jellyfish；未知 ID 回退 warm_jade。
- 原玉核材质、2D/3D、计划与进度不迁移；新模型运行时离线。
- 文件责任划分后并行实现；统一验证与一次本地 Git 提交由主代理完成。

## Review Focus

- 换肤期间旧 AnimationPlayer 信号不得修改新皮肤。
- 动物不可调用玉核专有渲染实现；可选接口必须受保护。
- 非法旧偏好／缺失皮肤安全回退。
- Windows 透明轮廓覆盖尾巴和动作极值，不使用巨大空白窗口拦截输入。
- 隐藏、静默、专注和减少动态继续生效。

## Task 1: 素材与来源

- [x] 下载官方 Corgi/Duck/Jellyfish GLB，解析实际动画及骨骼。
- [x] 写来源、CC0、SHA256 和备选比较到 research 与 models 目录。

## Task 2: 角色渲染和动作

- [x] 先用 check_animal_skins.gd 验证目录／加载／动作回归缺失。
- [x] 增加 skin_catalog.gd：entries、skin_id、load_skin、actions。
- [x] 增加透明视口包装、骨骼 idle/walk 和程序化回应；保持 AnimationPlayer 调度契约。
- [x] 运行行为检查并生成 GPU 关键帧预览。

## Task 3: 设置和预览

- [x] 先运行 check_companion_ui.gd，证明缺少角色切换接口。
- [x] settings_panel 添加 skin_requested 和 set_skin_selection，按角色更新动作与控件。
- [x] appearance_preview.set_skin 加载目录中的相同场景；保留旧 API。
- [x] 运行 UI 行为检查，验证默认／切换／预览同步。

## Task 4: 应用集成和交付

- [x] 增加皮肤持久化／未知值回退测试，再实现 main.gd 切换和状态重放。
- [x] 对角色可选 API 保护；换肤重放原外观、专注和陪伴状态。
- [x] 运行 test-prototype.ps1、专项测试、真实渲染并审阅关键画面。
- [x] 更新 README／发布记录；独立检查差异、git diff --check，然后本地提交。
