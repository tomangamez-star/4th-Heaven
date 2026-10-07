# 4TH HEAVEN v0.1.5 — Living Streets Foundation

## Added

- Code-drawn benches, bus-stop shelters, streetlights, signs and bins.
- Shared world-light manager with one consistent late-afternoon shadow direction.
- NPC walk, wait, approach, sit and talk behaviour states.
- Bench seating and gathering destinations that NPCs can select near their route.
- An immediately visible sitter and two-person conversation in the opening segment.
- Sitting pose and small conversation bubble for readable overhead behaviour.

## Changed

- Removed the temporary brick wall and crate from the central-loop district.
- Doodle and vehicle shadows now use the shared world-light direction.
- Social NPCs resume their preserved sidewalk route after finishing an activity.

## Preserved

- Six-person segment budget and near-camera activity culling.
- Road, sidewalk, vehicle and doodle proportions.
- Movement, ragdolls, contextual push, route recovery and player avoidance.

---

## Previous: v0.1.4 — Central Loop Scale Test

## Added

- Six pedestrians as the official population budget for one active segment.
- Two walking lanes on each side of the central-loop pavement.
- Player-aware NPC stopping and soft side-step avoidance.

## Improved

- Widened the asphalt into two properly proportioned vehicle lanes.
- Widened both sidewalks to hold two doodles side-by-side.
- Enlarged the current car while preserving its accepted visual design.
- Moved the player spawn onto the widened sidewalk.

## Preserved

- The accepted oval/desert central-loop artwork and route shape.
- Path recovery after a pedestrian is pushed off the sidewalk.
- Movement, connected limbs, ragdolls, contextual push and activity culling.

---

## Previous: v0.1.3 — Visible World Fix

## Fixed

- Rebuilt the opening route so the road and sidewalk cross the spawn camera.
- Spawned three pedestrians and the first car on the visible opening stretch.
- Repositioned the wall and crate inside the initial landscape view.
- Explicitly activated the player camera and forced the first procedural draw.
- Bumped the Web cache key so phones cannot reuse the empty v0.1.2 export.
- Added a regression test that fails if the opening scene becomes empty again.

## Preserved

- Approved player movement, stopping, connected limbs and ragdoll behaviour.
- NPC lane walking, avoidance, contextual push and vehicle impact physics.

---

## Previous: v0.1.2 — Pedestrian Traffic Test

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
