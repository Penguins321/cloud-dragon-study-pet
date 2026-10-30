# AI Companion Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development with independent file ownership, then integration and review.

**Goal:** Optional DeepSeek/OpenAI autonomous actions with short bubbles; private configuration persists locally and never enters Git or exported packs.
**Architecture:** Standalone config and HTTP brain, standalone settings editor, standalone speech Window, main.gd coordinates existing scheduler/guards. No dependencies or server.
**Tech Stack:** Godot 4.7.2 HTTPRequest, ConfigFile, Window/Control, GDScript tests.
**Spec:** docs/superpowers/specs/2026-10-30-ai-companion-design.md

## Global Constraints
Default off. 120-second minimum autonomous call interval including failed calls; single flight; timeout 10 seconds; no retries. Only fixed HTTPS provider endpoints. Only current-role whitelisted actions; plain text max24 characters, empty allowed. No screen/files/task text sent. Key is local plaintext ai_private.cfg, ignored and excluded from exports; no logging/backups. User explicitly replaced session-only key proposal with persisted config.

## Interfaces
- ai/config_store.gd RefCounted: defaults() -> Dictionary with enabled:bool=false, provider:String=deepseek, model:String='', api_key:String='', bubbles:bool=true; load_config(path)->{error,config}; save_config(path,config)->Error; validate(config)->bool.
- ai/companion_brain.gd Node: configure(config), cancel(), request_decision(context:Dictionary, actions:Array[StringName], manual:bool=false)->Error; vars busy:bool, next_allowed_msec:int. Signals decision_ready(decision:Dictionary), failed(message:String), status_changed(message:String). decision contains action:StringName,text:String,test:bool. Test requests use manual=true and never animate; automatic cooldown preserved on configure/cancel.
- ui/ai_settings_panel.gd VBoxContainer: save_requested(config), test_requested(config); set_config(config), set_status(message,busy=false). Fields expose named enabled_button/provider/model_input/key_input/bubbles_button/save_button/test_button/status_label. Provider change clears model/key to avoid credential confusion. Test button means save-and-test.
- ui/ai_bubble.gd Window: show_message(text,anchor:Rect2i,usable_areas:Array[Rect2i],level:int=0,on_top:bool=true), update_anchor(anchor,areas), dismiss(), set_font_level(level). Standalone borderless transparent nonfocusable 6s Window, plain Label max2 lines/24 chars; follows screen anchor; font scaling; click closes; property message_label.

## Tasks
- [x] Core/config agent: failing tests then persistence, endpoint construction, strict response/action checks, redaction, cooldown/timeout and cancellation generation tests.
- [x] UI agent: settings card + behavior tests, provider clearing, masked persisted key, all font levels.
- [x] Bubble agent: standalone themed Window + lifetime/placement/font tests, no main window resizing.
- [x] Root integration: private paths, settings/save/test, safe metadata, event queue, local fallback, current-state checks, interaction interruption and config errors; tests for restart persistence and stale decisions.
- [x] Independent final review, full regression, GPU previews/clip checks, export and package verification with no private files.

## Review Focus
Keys in logs/exports or normal preference backups; stale requests after switching/hiding; long-pause cooldown/event replay; untrusted responses beyond current action set; UI at170% fonts and screen edges.

## Sources
https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create
https://api-docs.deepseek.com/api/create-chat-completion/
Both use Chat Completions JSON response format; DeepSeek explicitly disables thinking for short decision latency. Models are user-configured, no model alias promises.

## Scope updates approved during implementation
User required persisted local plaintext configuration rather than session-only keys. Then approved chat context, long-term explicit preferences and per-role personas. Finally approved single-click companion response + lightweight clickable caption leading to chat, with learning goal via separate menu and no guiding-light paper card. Chat/memory modules and regression checks were added accordingly.

## Integration evidence so far
- All AI module tests and three root integration tests passed headless; graphical root/chat/interaction tests passed.
- Native smoke: first-run welcome, short invitation→chat, goal menu, dragging, manual progression, focus, scaling, GPU region coverage and hide/show passed.
- Full test-prototype completed with0failures; lifecycle ERROR found by log review is being pinned/fixed before final rerun.
- Independent review found manual-caption gating and per-editor draft overwrite; both have dedicated fixes and regression checks. Export excludes expanded to every preset and root/nested private file masks.
- UI screenshot QA at normal and170% remains520x720; memory page scrolls, composer/actions stay usable.
- No real API key provided or paid API requests sent; request tests use injected transport and placeholder keys.

## Final evidence
- Final full test-prototype.ps1: exit0; all eight AI suites0failures, base186, motion11533, expressive235580, remaining integrations allgreen; no unexpected script/resumed/deferred errors.
- Removed the awaited UI scroll coroutine; lifetime-bound one-shot callbacks now auto-disconnect when freed, with a regression.
- Final graphical interaction includes manual caption persistence and chat access in quiet/reduced/focus modes:0failures.
- Root integration restart tests preserve key,preferences,rolepersona and history; deletedprefsstaydeleted; rolechangesinvalidateoldchat; protected exportpaths include both privatefiles.
- Final export exit0. Engine --main-pack actual EXE: AI PACKAGE0failures and COMPANION PACKAGE0failures.
- Private placeholder probe files were placed in projectroot during export; packed FileAccess verified all four private config/memory/temp filenames absent. Probes removed afterwards. Every exportpreset explicitly excludes privatefiles, both root andnested masks.
- Git check-ignore --no-index -v verified cfg/memory/temp are ignored. Real keys were never read, requested in chat, logged or sent.
- Windows native screenshots inspected at normal/170% fonts; current chatwindow520x720, scrollable history/memory, valid composer/buttons. Real Mac and liveprovider authentication remain user-environment validation.
