# 4TH HEAVEN v0.1.2 — Pedestrian Traffic Test

## Added

- Visible layered pedestrian sidewalk with straight sections and rounded turns.
- Independent asphalt road with curbs and hand-painted lane markings.
- First procedural top-down vehicle with an authored looping road route.
- Smooth vehicle steering, corner slowdown and ragdoll impact.
- Three optimized NPCs on separate sidewalk lanes with varied speeds and pauses.
- Temporary NPC sidestepping when another pedestrian blocks the lane.
- Larger 6000×4000 soil testing world and bounded smooth player camera.
- Tighter near-camera activity manager for both pedestrians and traffic.

## Fixed

- Sidewalk and road now render above the soil instead of being hidden beneath it.
- Routed NPCs resume their route after push/ragdoll recovery.
- Procedural NPC visuals update at 30 FPS on Web while physics remains full-rate.

## Preserved

- Original player walk/run animation and handling.
- Six-part connected ragdoll system.
- Timed two-hand contextual NPC push.
- Physical crate and brick wall laboratory objects.
