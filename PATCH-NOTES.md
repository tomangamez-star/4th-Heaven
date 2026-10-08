# 4TH HEAVEN v0.1.9 — Night Traffic & Scale Polish

## Corrected

- Enlarged cars by roughly 35% and the city bus by roughly 32%.
- Resized every vehicle collision body and shadow to the visible PNG proportions.
- Replaced the hand-shaped lawn with the exact inner-pavement route boundary.
- Removed both grass-over-pavement overlap and exposed central soil gaps.

## Improved

- Rebuilt streetlights as readable bases, arms, lamp housings and bright lenses.
- Added real radial Godot light sources that remain visible through the Night grade.
- Strengthened vehicle headlight cones and added independent live head/tail lights.
- Added impact rings, sparks, dust, immediate braking and a small suspension jolt when traffic hits a doodle.

## Preserved

- Accepted Afternoon, Evening and Night atmosphere colours.
- PNG vehicle artwork, traffic-following logic, bus braking and opposite lane direction.
- Continuous NPC paths, stuck recovery, station design and performance culling.

---

## Previous: v0.1.8 — Central District & Traffic Polish

## Added

- One detailed transparent top-down car asset with red, blue and gold variants.
- A separate long Japanese-style city bus asset.
- Three cars and one bus across correctly directed traffic lanes.
- Physical vehicle bodies, forward traffic sensing, safe spacing and queue braking.
- Bus-specific speed, stopping distance, collision length and impact strength.
- Subtle moving suspension wobble, turning lean, braking dip and live directional shadows.
- Night headlights layered independently from the PNG artwork.
- NPC blocked-destination detection and automatic nearest-route recovery.

## Corrected

- Removed automatic stops at every pedestrian route node.
- Reduced random activity frequency and removed meaningless pavement waiting.
- Moved gathering points away from the station and moved sitting points clear of benches.
- Reset NPC activities and routes after ragdoll recovery.
- Rebuilt the station as a roof-dominant true eagle-eye structure.
- Fitted the grass beneath the complete inner oval to eliminate exposed soil strips.
- Rebalanced Evening from strong tan/yellow to a softer neutral warm grade.

## Preserved

- Peak Afternoon and Night lighting states.
- Existing player movement, ragdolls, NPC interactions, road scale and performance culling.

---

## Previous: v0.1.7 — Central Station & Lighting Lab

## Added

- A layered green plaza filling the central oval without touching the road layer.
- Wide stone paths linking the north and south sidewalks through the plaza.
- A small Japanese-inspired station pavilion with a visibly locked future-subway gate.
- Four trees, six bushes and restrained flower details with physical collisions.
- Above-character pavilion roof and tree-canopy rendering.
- Morning, afternoon, evening and night lighting presets.
- Four temporary phone-friendly time-state buttons with smooth transitions.
- State-specific world colour grading, shadow direction, shadow length and strength.
- Night window glow and warm active streetlights.

## Preserved

- The accepted afternoon directional shadow appearance.
- Road independence, two-person sidewalks, sparse furniture, shelter layering and collisions.
- Existing movement, ragdolls, NPC behaviour, traffic and performance budget.
- Current car artwork for its dedicated follow-up redesign.

---

## Previous: v0.1.6 — Street-Life Correction

## Corrected

- Replaced fixed prop coordinates with route-aware open-space placement.
- Reduced the furniture count to three benches, one shelter, three lights, one bin and one bus sign.
- Kept both pedestrian lanes clear and moved social gathering points entirely off the road.
- Added collisions to benches, shelter walls, bins, lights and signs.
- Split the shelter into a below-character base and above-character transparent blue-glass roof.
- Replaced the unclear sign blocks with a recognizable bus silhouette.
- Combined each pole-and-top shadow into one silhouette to remove transparent overlap seams.
- Animated the full-sized conversation bubble through (...) → (..) → (.) → (..) → (...).

## Preserved

- The accepted directional late-afternoon shadows for future day/night lighting.
- Existing movement, ragdolls, traffic, road scale, NPC path recovery and performance budget.

---

## Previous: v0.1.5 — Living Streets Foundation

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
