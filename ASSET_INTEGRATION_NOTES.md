# IRON-FRONT — first imported 3D asset pass

This branch adds a small set of real GLB models to validate the runtime asset pipeline on mobile.

## Bundled assets
- tree_pine.glb.b64 — pine tree, from Kenney Nature Kit via syuhei176/ai-game-assets.
- rock_large.glb.b64 — large rock, from Kenney Nature Kit via syuhei176/ai-game-assets.
- building_house.glb.b64 — house, from Kenney City Kit via syuhei176/ai-game-assets.
- building_tower.glb.b64 — tower, from Kenney Tower Defense Kit via syuhei176/ai-game-assets.

Original source repository: https://github.com/syuhei176/ai-game-assets
Source pack and asset licence: Kenney CC0 1.0. Original models are public-domain/CC0; no attribution is required, but source is recorded here for traceability.

## Runtime loading
The model payloads are stored as base64 text and decoded with Godot's GLTFDocument at runtime. This avoids relying on editor import metadata for this initial phone-side test. If performance or startup time is not acceptable, the next pass should convert them to native GLB files in the editor import pipeline.

## Important scope
This is an environment/building art integration test, not the final military vehicle/unit pack. The military tank + 4x4 sampler is listed separately in the asset sourcing notes; it is CC BY 4.0 and requires attribution:
https://heyheythere.itch.io/low-poly-military-kit-free
Credit: Low-Poly Military Kit Free by heyheythere.
