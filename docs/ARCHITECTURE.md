# IRON-FRONT Godot Architecture

The native Godot project is organized by responsibility. Keep `main.gd` as a small scene composition root; do not add gameplay systems or large world-generation routines to it.

## Runtime modules

- `scripts/main.gd`: creates and connects runtime modules only.
- `scripts/world/battlefield_builder.gd`: terrain, river, bridges, scenery, headquarters, resource sites and building click areas.
- `scripts/camera/camera_controller.gd`: camera movement, touch drag and pinch zoom.
- `scripts/systems/interaction_controller.gd`: screen picking, building selection, command routing.
- `scripts/systems/economy_manager.gd`: resource balances, passive income, mining and production costs.
- `scripts/systems/unit_manager.gd`: unit creation, selection and movement orders.
- `scripts/ui/hud_controller.gd`: compact top HUD, resource display, select-all control and contextual building panel.

## Interaction rules

- Buildings and resource sites are selected directly on the 3D battlefield.
- The contextual panel exposes only the selected building's relevant action.
- The top-right select-all command selects friendly units; tapping the terrain issues a move order.
- No bottom navigation/action bar is used.

## Engineering rules

- One responsibility per script; avoid monolithic scripts.
- Prefer typed variables and explicit return types in GDScript.
- Keep scene composition in `main.gd`; keep reusable gameplay logic in managers.
- New systems should be added as separate scripts under `systems/`, `world/`, `camera/`, or `ui/`.
- Keep mobile rendering and touch interaction as the baseline.
