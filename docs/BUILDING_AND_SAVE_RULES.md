# Building Placement and Save System

- Building placement uses a 2 m grid.
- Each new building reserves a 10 m x 9 m footprint.
- A 3 m safety gap is enforced from every existing building and resource site, using axis-aligned footprint checks.
- Placement is restricted to the player's west-side build zone and the map bounds; the river and enemy half are excluded.
- A translucent preview turns green when valid and red when blocked.
- Construction costs 120 wood and 75 metal.
- Placed buildings, army unit positions/types and resource balances are saved in user://iron_front_save.cfg.
- Existing headquarters, resource sites, barracks and vehicle plant are treated as reserved footprints.
