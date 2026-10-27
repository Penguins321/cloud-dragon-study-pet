# Guofeng live elemental effects

Approved visual: `desktop-pet/docs/screenshots/guofeng-elements-approved.png`.

Requirements: retain the original three-stone character, balance visible body and effects, use Chinese-animation palettes (vermilion / smoky violet / moon-white), and prioritize continuous real-time motion. No concept bitmap or fixed sprite board is used as the live effect.

Implementation:

- Procedural flame ribbons with advected width and heat, layered behind/in front of the crystal, plus independent fading ember trails.
- Continuously evolving branching lightning and traveling highlights; no discrete random topology changes or high-frequency flashes.
- Slowly growing frost edge veins, layered curling ice mist and depth-varied falling flakes/shards.
- Share generated paths between draw calls and native window masks; preserve desktop gaps where particles are sparse.
- Keep material switching, growth, hidden-preview suspension and all existing motion state.

Verification:

- [x] Smooth small-time-step geometry and meaningful evolution over one second.
- [x] Lifetime boundaries fade to zero; effects remain covered and inside animation bounds.
- [x] Actual live-render APNG preview and static screenshot inspection.
- [x] Native performance and settings-preview color agreement.
- [x] Full regression, exported persistence/close tests, isolated installer test.
- [x] Commit implementation and release documentation separately.

The earlier v0.14 draft has not been released. Integrate this approved design into v0.14.


Validation: 285 core checks, 11,478 choreography checks, 13 flame checks (including 3000 max-growth phases and retained-mask coverage), 13 current/mist checks; native rendered preview and exported preference migration passed. Pixel comparison mean channel difference 0.00143. Mature desktop fire averaged 54.12 FPS on Intel UHD 630. Final isolated install/uninstall and source/ZIP/installed payload identity passed.

