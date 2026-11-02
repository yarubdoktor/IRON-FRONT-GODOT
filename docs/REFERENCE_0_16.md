# IRON-FRONT 0.16 — Reference Contract

The archive in `reference/` is retained as the untouched baseline.

Use it to inspect:
- visual identity, map proportions, battlefield layout, and UI behavior;
- unit/building types and their intended roles;
- economy, harvesting, production, combat, AI, and progression rules;
- source GLB inventory and licensing notes.

Do not copy the React/Three.js architecture into Godot. Reimplement behavior with native Godot scenes, nodes, resources, signals, and typed GDScript.

Do not modify or overwrite the reference archive. Any extracted assets must be copied into a separate Godot asset directory only after their paths, import settings, materials, and scale have been verified.

## Rebuild sequence
1. Native project foundation and battlefield blockout.
2. Camera and touch interaction.
3. Native UI and build placement.
4. Economy, resources, production, and unit selection.
5. Movement, combat, and opponent AI.
6. Save/load and balancing.
7. Verified GLB integration and final art pass.
