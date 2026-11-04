# Building Placement and Save System

## Placement rules

- Standard construction uses 12 predefined sites in the player's west-side construction district.
- Defensive walls use a separate perimeter list of 12 positions; the configured wall limit is 10.
- Normal building types are limited to one instance each. Watchtowers are limited to four.
- Building footprints are defined per type in `BuildingPlacementManager.BUILDING_CATALOG`; they are not all a fixed 10 m x 9 m size.
- A 0.75 m safety gap is checked between full axis-aligned footprints.
- Standard buildings are constrained to X [-50, -17.5] and Z [-20, 20].
- Defensive wall positions are constrained to the perimeter lanes and kept away from the bridge and enemy side.
- Headquarters and resource-site footprints are reserved and cannot be overlapped.
- The preview turns green when the selected site is valid and red when blocked.
- Construction cost is selected by building type in `EconomyManager.BUILDING_COSTS`. A barracks costs 120 wood and 75 metal.

## Saved state

The file `user://iron_front_save.cfg` stores:
- Resource balances and secured mine identifiers.
- Building upgrade levels and placed building records (ID, type, center, rotation and level).
- Army unit positions and unit types.
- Rally point active state and coordinates.

Loading rebuilds placed buildings and units from the saved records and restores the economy and rally state. The runtime regression test verifies resource balances, mine ownership, building identity/level, army size/type and rally coordinates.
