# Appearance and motion implementation plan

> **For agentic workers:** Use superpowers:executing-plans for integration and verification. The user has explicitly requested autonomous implementation without further design approval.

**Goal:** One-click material/color selection with a faithful live settings preview, richer gestures and seamless return to hover.

**Architecture:** Keep the existing rigid three-stone jade rig and animation player. A shared appearance catalog supplies four materials and nine colors to both the actor and the preview. Store stable identifiers in the existing preferences file.

**Tech Stack:** Godot 4.7.2, GDScript, existing Windows packaging.

## Constraints and choices

- Preserve the recognizable jade-core outline, growth state and current action when changing appearance.
- Use real rig rendering in the preview; stop preview work when its settings window is hidden.
- Materials: warm jade, clear crystal, iridescent opal, particle flame. Colors: jade, ice, violet, rose, amber, moon, ember, gold, bluefire.
- The additional flame request uses 96 upward tapered particles, growing to 136; main core and side shards emit independently, with zero opacity at lifetime boundaries.
- Prefer a compact catalog and shared rendering over duplicated scene assets or whole-pet color modulation; this preserves white highlights and allows distinct transparency/refraction.
- Keep narrow-window scrolling and fixed footer controls.

## Tasks

- [x] Add failing actor appearance and persistence checks, implement catalog and rendering, confirm both pass.
- [x] Add appearance card, real preview, named swatches and material buttons; check one-click signals and hidden preview suspension.
- [x] Add bow, roll and dance, strengthen walk/laugh anticipation; sample start/end, finite transforms, separation and clipping bounds.
- [x] Render and inspect all material/color combinations, settings at standard/compact sizes and updated motion trajectories.
- [x] Run full regression and packaged persistence; review changes, build and test v0.13 installation.
- [x] Commit implementation and release files separately, excluding unrelated user changes.

## Review focus

Invalid saved identifiers fall back to jade; selection restoration emits no user action; switching during a gesture preserves its timeline; hidden settings consume no preview rendering; narrow settings retain access to all choices.


## Verification results

274 core checks passed; warm-jade and big-motion suites passed; 11,448 refined-motion checks passed. Appearance UI and persistence passed in source and exported Windows runtime. Preview/direct-render mean channel difference was 0.00143. Isolated v0.13 install/uninstall and payload identity passed. Existing tray-close regression also passed in the exported app.

