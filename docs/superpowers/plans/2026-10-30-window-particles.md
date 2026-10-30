# Window chrome and spatial particles Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Consistent jade window headers and visible spatial crystal particles.
**Architecture:** Shared WindowChrome Control for app windows and confirmation dialogs; reuse MultiMesh particles and current clipping regions.
**Tech Stack:** Godot 4.7 GDScript, spatial shader.
**Spec:** docs/superpowers/specs/2026-10-30-window-particles-design.md

## Global Constraints
No new dependencies. Keep native file dialogs. Preserve 2D fallback and font scaling.

## Review Focus
- Modal dialogs keep content below header and cancel correctly.
- Minimum sizes include header; large fonts remain usable.
- Transparent particles stay in desktop clipping regions.
- Preview renderer survives skin replacement and hidden windows stop rendering.
- Front/back particle size and alpha differ, without covering crystal.

## Task 1: Shared chrome
- [x] Add behavior checks for borderless app windows, shared headers and dialog header space.
- [x] Implement ui/window_chrome.gd and integrate main.gd, plan_panel.gd, plan_data_dialog.gd.
- [x] Verify headless UI and font checks.

## Task 2: Spatial particles
- [x] Add checks for near/far depth, scale and alpha variation.
- [x] Update energy_motes_3d.gd and shader; retain renderer mode on preview replacement.
- [x] Verify rendered particles on pale/dark backgrounds, action clipping, and preview renderer.

## Task 3: Deliver
- [x] Build current executable; inspect rendered settings and particle images.

## Verification evidence
- check_window_particles.gd: 0 failures, graphical; modal header close, all four font levels, renderer preservation, front/back depth and size.
- check_font_scale.gd and check_v016_ui.gd: 0 failures.
- check_production_3d.gd: 0 failures across actions and growth; transparent background and desktop clipping preserved.
- check_renderer_mode.gd: PASS.
- preview_window_particles.gd: settings and maintenance-dialog captures inspected; body starts below 52px chrome; pale-background motes visible.
- build-prototype.ps1: exit 0; exported EXE settings smoke: exit 0, no runtime errors with workspace APPDATA.
- Ruling: keep work in current checkout so existing local engine/export/launcher paths remain usable; no shared branch operations.
- Ruling: file picker remains native; application-owned confirmation dialogs use shared chrome.
- Export first could not replace the old EXE; preserved it as build/WarmJadePrototype-v0.17-before-chrome.exe and rebuilt successfully.
