# Gobkit animal companion assets

Retrieved 2026-10-30 Asia/Shanghai (2026-10-29 UTC) from official Gobkit public links. Author: **Gobkit**. The GLB bytes are unchanged.

- Source page: https://gobkit.itch.io/gobkit-free-animal-pack
- Official manifest and explicit CC0 / offline redistribution statement: https://gobkit.com/api/free
- Pack download: https://gobkit.com/freebies/animal/gobkit-animal-pack.zip
- Model URLs: https://gobkit.com/freebies/animal/Corgi.glb , https://gobkit.com/freebies/animal/Duck.glb , https://gobkit.com/freebies/animal/Jellyfish.glb
- License: CC0 1.0 Universal, https://creativecommons.org/publicdomain/zero/1.0/ . See `CC0-NOTICE.txt` and the unchanged `source-manifest.json` snapshot.
- Integrity: `SHA256SUMS`; measured structure, clip times and bounds: `validation.json`.

All three downloaded GLBs contain one textured mesh, one skinned skeleton with 16 joints, and separate named `idle`, `attack`, `dead`, `walk` clips, approximately 1.20833 seconds each. No external buffers/images or required compression extensions were found. Use the named animations; do not slice using legacy frame metadata. The old itch description of one combined timeline is inconsistent with these verified binaries.

Normalize geometry from actual imported transforms: mesh-local geometry is Z-up and about 400 units tall; the mesh node supplies a -90 degree X rotation to make it Y-up. Do not apply a second conversion rotation or assume meter-scale geometry. `validation.json` includes both mesh-local and rotated-rest bounds. Native materials are textured standard PBR, with no `KHR_materials_unlit` extension; the source marketing description of unlit materials is not a statement about these binaries.

Only idle/walk are general companion motions. Other project interactions are separately composed by the application and must not be described as extra animations supplied by Gobkit. The source has inconsistent provenance marketing (itch says no generative AI; the broader service describes AI generation), so this project makes no handmade/no-AI claim.
