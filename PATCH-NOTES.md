# v0.0.2 — Momentum and Ragdoll Test

The first 4TH HEAVEN prototype establishes the Android-safe Godot/Web pipeline
and the game's procedural circular-character language.

Test these points in the browser preview:

1. The head remains the dominant readable circle.
2. Clothing, arms and alternating legs remain visible from overhead.
3. Walking feels relaxed rather than like sliding.
4. Holding Run raises/advances the head and increases stride and arm motion.
5. Starting, stopping and sharp turns retain a small amount of momentum.
6. Controls remain reachable and unobtrusive in landscape orientation.

## Added

- A short procedural forward tug after releasing the controls at running speed.
- Temporary impact-burst button above Run.
- Physics-driven loose head, body, arms and legs connected by spring constraints.
- Forward launch, sliding, rotation, damping and automatic recovery.
- Desktop ragdoll test key: `R`.

The original v0.0.1 walking, running, acceleration and camera values remain
unchanged.
