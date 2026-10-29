# macOS support implementation plan

Goal: reuse the Godot pet and learning features on macOS, with login startup and a distributable Universal app.

Architecture: retain Windows startup unchanged; select a small macOS LaunchAgent backend. Use existing Godot native menus and window APIs. Disable Windows-only icon awareness on Mac. Build on macOS to preserve executable permissions.

User authorized direct implementation. Work on codex/macos-support; no automatic commit or publication.

- [x] Test macOS startup in an isolated directory: opt-in, XML paths, upgrade, disable, missing executable, development isolation.
- [x] Implement backend and platform selection; use platform-neutral settings copy and disable unsupported icon awareness.
- [x] Add macOS export preset and build/test scripts; local signing by default, optional Developer ID and notarization.
- [x] Run Windows regression tests and static build-script checks; document real Mac verification still needed.

Review focus: paths containing spaces/XML characters; startup after app moves; hiding without losing recovery; permissions and signature order; full-screen/Spaces behavior.

Ruling: LaunchAgent changes apply on next login, without loading/killing the running pet. No KeepAlive. macOS real launch and Gatekeeper checks cannot be simulated on Windows.

Evidence: startup test first failed because backend was absent, then passed with XML parsing, path refresh and failure-path checks. test-prototype.ps1 exited 0 (287 base checks, 11478 motion checks, appearance persistence zero failures). bash -n passed for both new scripts. Existing Godot menu and transparency APIs retained; Mac runtime remains unverified.
