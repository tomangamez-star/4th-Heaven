# 4TH HEAVEN v0.2.7 — Continuous Camera & Night Coverage

- Replaced stepped camera target snapshots with delayed, continuously updating turn follow.
- Reduced camera angular speed and added settle hysteresis so long turns remain fluid without small-input twitching.
- Redesigned the central building as a truly compact raster pavilion with human-scale doors and no baked ground shadow.
- Added a separate time-aware station shadow and tightened its physical collision footprint.
- Rebuilt streetlight distribution along every road segment with alternating sides and overlapping road-facing pools.

---

## Previous: v0.2.6 — Cinematic Driving & PNG Station

- Added delayed cinematic camera rotation with a 27-degree dead zone, held-turn detection and bounded angular speed.
- Added smooth 0.62-second camera blends when entering and exiting sideways vehicles.
- Reworked player steering around front and rear axle motion and added visibly articulated front wheels.
- Side contacts now discard only the blocked velocity component, allowing cars to slide apart instead of friction-locking.
- Replaced floating circular vehicle lamps with bumper-mounted light strips and beams originating at the car body.
- Staggered streetlights across opposite sides of the road for balanced two-lane illumination.
- Repositioned traffic signals squarely per incoming lane and baked distinct red/green raster states.
- Replaced the old vector central pavilion with a detailed transparent PNG transit station inspired by the original 4TH HEAVEN concept art.
- Split the station into below-character entrance art and an above-character roof layer, with fitted wall/entrance collisions.

---

## Previous: v0.2.5 — Raster Environment & Driver View

- Replaced procedural soil, streetlight bodies and traffic-signal bodies with polished top-down raster artwork.
- Streetlights and signals now rotate toward their road, render above passing actors, and collide only at their physical base.
- Left joystick now steers; dedicated Brake and Go pedals sit together on the right.
- Driving camera rotates with the vehicle so the controlled car remains screen-forward.
- Enlarged player and traffic collision bodies and added player-car awareness to traffic following.
- Removed the test NPC that paced endlessly across one zebra crossing.
- NPCs detect people and physical obstacles earlier and sidestep before contact.
- Web preview uses half-resolution road/soil tiles, reduced redraw rate and tighter activity culling; APK quality remains full.
- Added regression coverage for the new six-NPC population, avoidance and camera-safe driving.

---

## Previous: v0.2.4 — PNG Roads & Wheelbase Driving

- Added generated HD asphalt and paving artwork, baked into 17 connected PNG map chunks.
- Disabled the old vector oval, pavement and extension drawing layers while retaining their traffic/NPC route data.
- All road surfaces are united before external curbs are created; no join rectangles or internal border seams.
- Repositioned the parking entrance below the bays, with a clear reversing aisle.
- Nearby PNG chunks load around the active camera; distant sprites release their textures.
- Replaced fixed-rate rotation with speed/wheelbase steering, grip, gradual acceleration, coast drag and off-road slowdown.
- Opposite throttle brakes before reverse; stationary cars cannot pivot.
- Removed post-move car position clamping; swept collisions stop motion at obstacles.
- Named the player collider explicitly and disabled all player collision shapes on entry; added mutual driver/car collision exceptions.
- Detached the vehicle camera transform from car rotation, bounded camera lag to 48 units, and reset camera handoffs.
- Exit checks for a clear standing position and requires low speed.
- Added frame-by-frame driving tests for displacement, camera tracking, wall blocking, reverse and driver collision.
- Packaged files with their original directory paths preserved.

Validation covers automated behavior and the raster artwork overview. Mobile handling still needs device feedback.

---

## Previous: v0.2.3 — Seamless Roads & Controlled Driving

## Corrected

- Removed internal curb and asphalt outlines wherever the oval, junction and parking road connect.
- Unified the lane paint across the connected roads while leaving clean gaps through junction boxes and crosswalks.
- Rebuilt the parking entrance as a square seamless driveway instead of a rounded road cap/platform overlap.
- Reduced player-car speed and acceleration, softened high-speed steering and added stronger coast braking.
- Hard-locked the vehicle camera to the driven car and constrained the car to the playable world bounds.
- Cleared stale joystick and steering touches on enter/exit so the car can no longer launch unexpectedly.

## Preserved

- Existing district layout, traffic signalling, smart following and pedestrian yielding.
- Accepted central oval, lighting, vehicle scale, impact effects and character systems.

---

## Previous: v0.2.2 — District & Vehicle-Control Recovery

## Rebuilt

- Removed the oversized rectangular road and pavement construction from v0.2.1.
- Rebuilt both added sections with the oval's exact layered pavement, curb, asphalt and line proportions.
- Merged the east road directly through the oval edge instead of placing a disconnected map slab beside it.
- Replaced the giant beige parking platform with a compact rounded asphalt parking court.
- Simplified and re-aligned all four crosswalks around the corrected junction centre.

## Fixed

- Added four physical outer-world boundaries matching the complete 6000×4000 terrain.
- Expanded the walking and vehicle camera limits so neither can continue beyond a frozen camera.
- Added a dedicated vehicle camera; entering a car now keeps the car visible and transfers camera ownership correctly.
- Restores the player camera, player collision and walking HUD on exit.
- Added a true driving HUD: vertical joystick for forward/reverse, separate right-side left/right steering and Exit control.
- Removed Run, ragdoll and push controls while driving.

## Preserved

- Smart following distances, chain braking, pedestrian yielding and bright brake lamps from v0.2.1.
- The accepted central oval, plaza, night lighting, traffic impact and doodle systems.

---

## Previous: v0.2.1 — First District Expansion & Smart Traffic

## Added

- Added only two deliberate world sections beyond the central oval: an east four-way junction and a compact parking side street.
- Added zebra crossings, four visible traffic signals and an eight-second alternating signal cycle.
- Added one dedicated crossing NPC so cars must react to a real pedestrian in the road.
- Added the first parked player car with contextual enter/exit control, mobile driving and keyboard driving.
- Added one outer-section traffic car to exercise the new junction route.

## Improved

- Rebuilt following distance around the vehicles' visible lengths instead of their older compact hit areas.
- Added speed-dependent following gaps and lead-car speed propagation for smooth chain braking.
- Added forward pedestrian awareness with progressive slowing and a complete stop before contact.
- Added traffic-signal speed limits and strong brake-light flare whenever a vehicle slows or queues.

## Preserved

- Existing doodle impact collision, ragdoll hit response and impact effects.
- Central oval artwork, park/road lights, vehicle scale and wide night headlights.
- Six-NPC budget inside the original central segment; the crossing NPC belongs to the new section.

---

## Previous: v0.2.0 — Roadlight & Vehicle Proportion Lock

## Improved

- Increased car width slightly and length by approximately 25% without changing the accepted physical hitboxes.
- Made the bus visibly wider and longer than every car so it no longer reads as a stretched car.
- Expanded vehicle shadows and moved lamps to match the larger artwork.
- Rebuilt headlights as much broader, softer lane-covering beams.
- Preserved every park light, added two more park lights and added five dedicated road-facing streetlights.
- Projected the new roadside light pools inward across the asphalt while keeping their physical poles safely on the pavement.

## Preserved

- Accepted traffic collision and vehicle-hit mechanics.
- Night-only activation for streetlights, headlights and tail lights.
- Current impact ring, sparks, dust, suspension jolt and traffic-following logic.

---

## Previous: v0.1.9 — Night Traffic & Scale Polish

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
