# v0.0.3 — Impact Laboratory

This patch expands the soil movement lab without changing the approved player
walking or running values.

## Added

- Rounded arm and leg connectors behind the existing hands and shoes.
- Top-right comparison toggle for switching connectors on/off live.
- First wandering NPC with a separate colour palette.
- Contextual Push control that appears only while the NPC is nearby.
- Directional medium-force NPC shove using the v0.0.2 ragdoll and recovery.
- Warm procedural brick wall with solid collision.
- Stylized wooden physics crate with inertia, friction, rotation and wall impact.
- Walking pushes the crate gently; running transfers a stronger impulse.

Running into the NPC does not trigger a ragdoll in this build. The player and
NPC collide normally; deliberate NPC impact remains tied to the Push control.

Desktop test keys: WASD/arrows, Shift/Space to run, R to self-ragdoll, E to
push when close.
