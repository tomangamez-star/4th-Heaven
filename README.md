# 4TH HEAVEN v0.1.6 — Street-Life Correction

Procedural pedestrian-world prototype for **4TH HEAVEN**.

## What is included

- True overhead landscape playfield on flat soil
- Fully code-drawn doodle character; no sprite sheets
- Large circular head, anime hair, visible clothed torso, arms and legs
- Smooth 360-degree walking and running
- Movement-driven stride, arm swing, wobble, bounce, turn lag and run posture
- Running-stop momentum tug without changing the approved walk/run timing
- Six-part spring ragdoll with launch, roll, slide and automatic recovery
- Temporary impact-burst test button above Run
- Permanent rounded doodle limb connectors
- Three optimized routed NPCs using the same procedural doodle rig
- Visible layered sidewalk with straight sections, corners and turns
- Independent asphalt road layer with its own filter-ready drawing
- First code-drawn vehicle following an authored traffic route
- Guaranteed populated opening camera with the road, pedestrians, car and props
- Properly proportioned two-lane central-loop road and two-person sidewalks
- Six pedestrians per camera-sized city segment
- Player-aware pedestrian stopping and soft side-step avoidance
- NPC walk, wait, sit, talk and gathering behaviour states
- Sparse route-aware benches, bus shelter, streetlights, bus sign and bin
- Physical collisions on every street prop and an open-front bus shelter
- Transparent blue shelter roof layered above visible doodles
- Classic animated conversation dots: (...) → (..) → (.) → (..) → (...)
- Unified prop-shadow silhouettes with the accepted directional sunlight
- Shared late-afternoon sunlight direction for characters, cars and street props
- Reusable behaviour destinations that return NPCs to their sidewalk routes
- Clean central loop with temporary laboratory props removed
- Vehicle corner slowdown and ragdoll impact
- Different NPC walking speeds, route directions and destination pauses
- Tighter near-camera activity culling for pedestrians and traffic
- Larger 6000×4000 soil world with smooth bounded camera follow
- Forced landscape Android presentation
- Context-sensitive directional NPC shove action
- Stylized procedural brick wall and top-down physics crate
- Timed two-hand push pose before NPC impact
- Native Android workflow with SDK, Java 17 and debug signing configured
- Mobile joystick and hold-to-run control
- Keyboard support: WASD/arrows, Shift or Space to run
- Smooth follow camera
- GitHub Pages preview workflow
- Manual milestone APK workflow

## Browser preview

Push the project contents to the root of a GitHub repository. In repository
Settings > Pages, select **GitHub Actions**, then run **Build and deploy 4TH
HEAVEN preview** or push to `main`.

## Scope

This build intentionally contains no buildings or full city art. Its
purpose is proving routed pedestrians, world layering, camera movement and
near-camera activity management before the city is built around them.
