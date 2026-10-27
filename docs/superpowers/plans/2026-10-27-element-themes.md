# Element theme update

Goal: preserve the recognizable three-stone body, balance body and fire roughly equally, and replace retired molten-gold/blue-fire options with independent lightning/snow themes.

Approach: reuse the existing rig. Fire uses cached procedural alpha textures, with particles behind the crystal and a restrained foreground layer. Lightning/snow have separate shared drawing/coverage helpers. Keep appearance identifiers stable and migrate retired selections at the shared catalog boundary.

- [x] Verify large surrounding flames, full crystal visibility by rendered inspection, lifetime coverage and animation bounds.
- [x] Add lightning paths and snow geometry with sampled coverage checks; keep empty desktop gaps clickable.
- [x] Update catalog, preference migration and settings preview; verify hidden preview suspension and rendered color agreement.
- [x] Measure mature fire plus live preview and inspect three-theme render.
- [x] Complete final integrated regression, export and isolated installer validation.
- [x] Commit implementation and release artifacts separately.
