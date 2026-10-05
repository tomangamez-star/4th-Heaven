# 4TH HEAVEN v0.1.1 — Living World Test

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
- Six routed NPCs using the same procedural doodle rig
- Layered street-walk with straight sections, corners and turns
- Different NPC walking speeds, route directions and destination pauses
- Near-camera activity culling with a safe wake-up buffer
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

This build intentionally contains no buildings, vehicles or full city art. Its
purpose is proving routed pedestrians, world layering, camera movement and
near-camera activity management before the city is built around them.
