# Expressive desktop companion interactions

Research snapshot: 2026-10-30. Primary sources only; figures are the live pages' displayed snapshot and can change.

## Evidence and limits

| Source | Measurable product signal | Verified interaction |
| --- | --- | --- |
| [Bongo Cat, official Steam listing](https://store.steampowered.com/app/3419430/Bongo_Cat/) | 30,795 English reviews, 96% positive; 2,452 recent reviews, 96% positive | Each keyboard press produces a taskbar tap; everyday work becomes a visible response loop. |
| [Desktop Mate, official Steam listing](https://store.steampowered.com/app/3301060/Desktop_Mate/) | 5,361 English reviews, 61% positive; 124 recent reviews, 77% positive | Cursor chasing/play, head pats/click responses, dragging onto windows to sit, and window-to-window jumping. |
| [VPet, official repository](https://github.com/LorisYounger/VPet) | Approximately 7.1k GitHub stars | Demonstrates an established open-source desktop-pet ecosystem; this page alone does not establish which individual actions users prefer. |

These are product-level interest and satisfaction signals, not action rankings. No inspected primary source provides a measured ranking of petting, greeting, sleeping, or other individual actions. Review percentages across products and language scopes are not directly comparable.

## Four transferable mechanisms

1. **Attention follows the pointer.** Desktop Mate directly supports cursor play. For this pet, smoothly turn the face toward nearby pointer movement, pause as if noticing it, then settle. Limit displacement so the pet remains easy to click.
2. **Affection gives a legible reply.** Desktop Mate documents head-pat responses. A gentle pointer sweep can elicit a small lean/nuzzle, relaxed eyes, and a delayed settling of the side pieces. Nuzzling is our interpretation of the interaction, not a claimed source feature.
3. **An input produces an immediate, readable gesture.** Bongo Cat's key-to-tap loop supports clear cause and effect. A double click can greet with a side-piece wave; picking up or releasing can elicit a startled rebound. These specific gestures and triggers are design proposals.
4. **Quiet presence includes recovery and rest.** Desktop Mate describes unobtrusive companionship and moving aside when unused. Slow nodding/dozing and a soft wake-up provide lower-intensity contrast to energetic reactions. Dozing itself is a proposal, not a verified feature of the inspected products.

## Motion treatment

[Adobe's official animation-principles guide](https://www.adobe.com/creativecloud/animation/discover/principles-of-animation.html) explains anticipation, follow-through/overlapping action, ease in/out, secondary action, and timing.

Apply those principles to the existing jade core and rigid pieces:

- Before a wave or rebound, make a short preparation pose; retain an unmistakable main pose.
- Let the core initiate movement and the side pieces follow a little later; avoid moving every piece in lockstep.
- Decelerate into the pose, allow a restrained overshoot, then settle without an abrupt snap.
- Keep each jade piece rigid; convey weight through rotation, offset, timing, and attached highlights rather than rubber-like deformation.
- Give greeting, affection, surprise, and sleep distinct rhythms and expressions. Vary timing slightly while preserving readable intent.
- Prioritize interruption and return-to-idle continuity so interaction does not freeze or teleport the character.

The proposed action names are **greet**, **nuzzle**, **startle**, and **doze**. Their value must be evaluated in the running app; this note does not claim they are the four most popular actions.
