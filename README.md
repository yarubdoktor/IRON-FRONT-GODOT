# IRON-FRONT — Godot Rebuild

This repository is the native Godot 4 implementation of IRON-FRONT. The preserved web archive under `reference/` is a design reference only; it is not part of the runtime.

## Project baseline
- Engine: Godot 4.2.2 in CI.
- Renderer: Mobile.
- Main scene: `res://scenes/main.tscn`.
- Initial layout: landscape RTS battlefield.
- The battlefield and building models currently use procedural placeholder geometry. Final GLB art integration is a separate milestone.

## Implemented systems
- Procedural battlefield, river, bridges, forests, headquarters and resource sites.
- Camera drag and two-finger pinch zoom.
- Single-touch world interaction with multi-touch tap suppression.
- Contextual building selection and placement.
- Resource collection, passive production, construction and upgrade costs.
- Unit spawning, selection, movement orders and rally point.
- Save/load for resources, secured mines, building levels and placements, army state and rally point.

## Validation
GitHub Actions runs Godot import/script parsing, a headless main-scene launch, and regression tests for economy/building limits, camera gestures, interaction touch handling and persistence. Headless validation is not a substitute for visual inspection in the Godot editor or on an Android device.

## Development rules
- Keep `main.gd` as a small composition root.
- Keep each gameplay responsibility in its own manager.
- Work on an isolated feature branch; do not change `godot-rebuild` directly.
- Do not claim visual or Android validation unless it has actually been performed.
