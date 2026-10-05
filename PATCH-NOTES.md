# v0.1.0 — Native Foundation Milestone

This milestone prepares the same 4TH HEAVEN build for direct Web-versus-APK
performance comparison while cleaning up the Impact Laboratory presentation.

## Presentation fixes

- Doodle limb connectors are now permanent and the comparison toggle is gone.
- Player and NPC collision radius now matches their visible footprint, stopping
  ordinary head/body overlap.
- The short crate always renders below doodle characters.
- Brick rows are trimmed to remain inside the wall's already-correct collider.
- Player temporarily takes interaction depth only during the push pose.

## Push animation

- Push now begins with a quick forward lean and two-hand extension.
- NPC impact occurs at visual contact instead of immediately on button press.
- Arms retract before normal movement control returns.
- Running into an NPC still causes only normal physical collision.

## Android export repair

- Installs and configures Java 17.
- Installs Android command-line tools, platform 34 and build-tools 34.0.0.
- Configures Godot's Android SDK and Java SDK paths.
- Creates a temporary debug signing keystore on the runner.
- Validates the exported APK archive before uploading the artifact.

The approved v0.0.1 walking and running values remain unchanged. No speculative
performance reduction was applied before testing the native APK.
