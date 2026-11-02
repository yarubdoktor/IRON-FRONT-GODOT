# IRON-FRONT — Godot Rebuild

This branch is a clean, native Godot 4 rebuild of IRON-FRONT.

## Source of truth
- The original web game archive is preserved unchanged at `reference/IRON-FRONT-0.16-MORE-MINES-SOURCE.zip`.
- The web source is a design and gameplay reference only. Its React/Three.js runtime is not part of this Godot project.
- No original GLB assets are loaded by the initial blockout. Asset integration starts only after the native project structure and systems are stable.

## Project
- Engine: Godot 4.x
- Renderer: Mobile
- Initial orientation: landscape, suited to an RTS battlefield
- Main scene: `res://scenes/main.tscn`

## Current scope
The first clean baseline contains a procedural battlefield blockout, camera, lighting, river and bridge layout, headquarters markers, and resource-site markers. These are temporary native primitives, not final art or gameplay systems.

## Development rule
Each milestone must pass a clean Godot import, script parse, and headless scene launch before the next system is added. Do not treat a successful GitHub workflow as proof of in-editor visual quality; the scene must also be inspected in Godot.
