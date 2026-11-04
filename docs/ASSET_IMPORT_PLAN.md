# Battlefield Asset Integration Plan

## Confirmed source
- Repository: https://github.com/petroulacl/fps-buildings-env-kit
- Intended use: battlefield environment, buildings, modular structures, roads, vegetation, skyboxes and PBR ground materials.
- The source README describes the included assets as CC0/public-domain. Preserve the upstream README and any per-pack license files in the project when assets are imported.

## Important content boundary
The repository's military pack is 2D sprites/audio, not a library of 3D soldiers, tanks or armored vehicles. Do not treat those sprites as 3D battlefield units. A separately verified source is required for 3D military models.

## Import sequence
1. Inspect the upstream repository structure and license files.
2. Select a mobile-sized subset: a compact road kit, a small building set, 8–12 vegetation models, and a few ground material sets.
3. Import GLB/GLTF models into Godot and verify materials, scale, pivots and collision.
4. Create reusable scenes for buildings, roads, trees and terrain props.
5. Add LOD or distance-based visibility and collision simplification for mobile performance.
6. Only after the environment assets pass import checks, add separately licensed 3D infantry, tanks and armored vehicles.

## Mobile constraints
- Keep the active battlefield bounded and stream/instance props where practical.
- Avoid importing every source asset by default.
- Prefer GLB/GLTF, compressed textures and simplified collision meshes.
- Target the project's existing Godot 4 / GL Compatibility configuration until a device test justifies changing it.

## Current status
Planning only. No external asset files have been downloaded or imported by this commit.
