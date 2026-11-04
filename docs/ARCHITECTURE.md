# IRON-FRONT Godot Architecture

Keep `main.gd` as a small composition root. Runtime systems are created and connected there; gameplay behavior belongs in dedicated modules.

## Runtime modules

- `scripts/main.gd`: creates and connects runtime modules.
- `scripts/world/battlefield_builder.gd`: terrain, river, bridges, scenery, headquarters, resource sites and initial reserved footprints.
- `scripts/camera/camera_controller.gd`: camera movement, single-finger pan and two-finger pinch zoom.
- `scripts/systems/interaction_controller.gd`: touch/mouse gesture tracking, screen picking, building selection, placement confirmation and command routing.
- `scripts/systems/building_placement_manager.gd`: construction slots, footprint collision checks, previews, building instances and placement save data.
- `scripts/systems/economy_manager.gd`: resource balances, passive income, mining, construction/training costs and upgrades.
- `scripts/systems/unit_manager.gd`: unit creation, selection, movement orders and rally point.
- `scripts/systems/persistence_manager.gd`: ConfigFile save/load for economy, buildings, units and rally state.
- `scripts/ui/hud_controller.gd`: resource display, selection controls and contextual building panel.

## Interaction rules

- One finger can select or interact with the world; a multi-finger gesture must never be interpreted as a world tap.
- Camera panning and pinch zoom are handled by the camera controller.
- Buildings and resource sites are selected directly on the 3D battlefield.
- The contextual panel exposes the selected building's relevant action.
- Selecting friendly units and tapping open terrain issues a movement order.
- The rally point is applied to newly spawned reinforcements.

## Engineering rules

- One responsibility per script; avoid monolithic scripts.
- Prefer typed variables and explicit return types in GDScript.
- Keep mobile rendering and touch interaction as the baseline.
- Regression tests must cover behavior changed by each milestone.
- A successful headless workflow does not prove visual quality or Android-device compatibility.
