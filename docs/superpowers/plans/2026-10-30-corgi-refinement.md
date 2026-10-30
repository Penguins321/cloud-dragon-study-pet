# Corgi Refinement Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline.

**Goal:** Refine corgi appearance and local motion without changing the other companions.
**Architecture:** One corgi subclass, per-instance head skinning, fur shader and small ground shadow; preserve imported GLB.
**Tech Stack:** Godot 4.7.2 GDScript, existing GLB, spatial shaders.
**Spec:** docs/superpowers/specs/2026-10-30-corgi-refinement-design.md

## Global Constraints
Keep shared pet API, native walking, clipping and preview. No dependencies or replacement models. Preserve existing user work. Commit all project changes and push when verified.

## Review Focus
- Facial parts follow the same head transform; legs stay attached.
- Repeated zero-time evaluation never accumulates deformation.
- Native animation and rest poses restore cleanly on action/skin changes.
- GPU output stays inside native mask at all actions/scales.
- Shadow stays on ground during jump and all added state is instance-local.

## Steps
- [x] Record baseline and add failing checks for head binding, independent facial movement and stable repeated pose.
- [x] Implement corgi_view.gd, corgi_fur.gdshader and contact shadow; connect corgi.tscn only.
- [x] Render comparison/actions, test clipping and eye closure; run animal/UI and full regression checks.
- [x] Review, rebuild current EXE and smoke test; document result.
- [x] Inspect all Git changes; deliver by committing and pushing current branch, with remote-head verification recorded in the chat.

## Evidence
- RED baseline: head weights, eye closure and local head turn failed (3 failures).
- GREEN check_corgi_details: 0 failures headless and on Intel OpenGL; 120 graphical action/direction/time samples, zero edge clipping or uncovered pixels.
- preview_animal_skins: 18 GPU samples, zero clipping/missing coverage; 9 rapid swaps drained.
- Full test-prototype.ps1: exit 0 (178 base; 11,533 motion; 235,580 expressive actions; data, animal and UI integration all green).
- Export build exit 0; engine --main-pack current EXE --script verify-companion-package.gd: 0 failures.
- Settings production preview captured and inspected; corgi before/after comparison saved under screenshots/v0.17.
- Ruling: correct the imported raw Z-up normalization offset only for corgi so turn-in-place fits its viewport; other animals retain original framing.
- Ruling: keep this existing checkout and its uncommitted work because user explicitly requested all modifications committed/pushed together.
- Remote preflight: origin/main equals local HEAD b52a7c43aece39c19fa7d17c48ac43d0515cc20c; network access works through the authorized elevated Git tool.

- Final independent review: no important findings in corgi code, shaders or shared-view changes.
- Delivery target is origin/main; Git commit and push results are reported with the verified remote hash in the chat.
