# AI Chat Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the user's DeepSeek configuration work and improve everyday conversation handling.
**Architecture:** Extend existing private config, single-flight brain and chat panel; no new dependencies or streaming transport.
**Tech Stack:** Godot 4.7.2 / GDScript, PowerShell.
**Spec:** docs/superpowers/specs/2026-10-30-ai-chat-polish-design.md

## Global Constraints
- Personal key stays only in the user's private data directory; no credential-bearing logs.
- Tests use isolated data and synthetic messages. Live test is explicitly opt-in.
- Preserve companion context, editable preferences/persona and reduced-motion behavior.

## Review Focus
- HTTP failures must leave the composer usable without disclosing provider bodies.
- Rapid retries must preserve a draft while respecting the existing cooldown.
- Companion switching must not send another companion's draft.
- Deferred UI work must remain safe when closing a window.
- Native window bounds must hold at all four font scales.

## Task 1: DeepSeek defaults and request reliability
- [x] Extend core/settings tests for default model selection, provider switching and fixed HTTP/timeout errors; run RED.
- [x] Update config_store.gd, companion_brain.gd and ai_settings_panel.gd. Use 45-second chat and 10-second decision timeouts. Run GREEN.
- [x] Save real local config and run an opt-in live Godot test (decision, preference chat, contextual follow-up); persist/reload only synthetic memory in isolated directory.

## Task 2: Conversation usability
- [x] Extend chat UI and integration tests for Ctrl/Cmd+Enter, per-companion drafts, waiting state, failure/retry/cancel and unchanged history; run RED.
- [x] Implement rounded message presentation, compact composer actions, waiting indicator and explicit retry affordance. Preserve scroll position when reading old messages. Run GREEN.
- [x] Inspect native preview at normal/large font; run full regression and exported-package checks.

## Task 3: Delivery
- [x] Update user docs, obtain fresh code review, inspect tracked diff for secrets, build latest executable, commit and push under standing user authorization.

## Execution notes
- Existing main and launcher/build path retained under the ongoing authorized workflow; no worktree relocation of personal configuration or executable.
- Existing local model display name differs from the official API model ID; use `deepseek-flash` verified against current official docs.
- User clarified models must be a dropdown: added official account model discovery with cancellation on provider/key changes and preserved selection on failure. API IDs are used directly, never display names.
- RED: 13 core assertions (defaults/errors/wire history), 3 settings assertions, missing discovery, and 9 chat UI assertions failed before implementation. GREEN: all AI suites passed, followed by full test-prototype.ps1 (exit 0).
- Live diagnosis: first decision and first chat succeeded but follow-up returned 11 non-JSON characters with finish_reason=stop. Previous assistant replies were being sent as plain text. Encoding them as the same reply/memories JSON protocol fixed real follow-ups without weakening response validation.
- Live GREEN: official models returned deepseek-flash and deepseek-v4-pro; decision ~900 ms; chat ~1150 ms; synthetic explicit preference persisted/reloaded and correctly recalled in follow-up. No user history was sent.

- Final review: no blockers. Added the suggested direct regression for preserving the reading position when a new reply arrives; passed. Native previews and actual exported AI/companion package checks passed. Source and exported binary credential scans passed; personal config reloaded with DeepSeek enabled and deepseek-flash selected.
