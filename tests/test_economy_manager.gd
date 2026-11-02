extends SceneTree

const EconomyManagerScript = preload("res://scripts/systems/economy_manager.gd")
const BuildingPlacementManagerScript = preload("res://scripts/systems/building_placement_manager.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var economy := EconomyManagerScript.new()
	root.add_child(economy)
	await process_frame

	var initial_wood: int = int(economy.resources["wood"])
	var first_result: String = economy.perform_building_action({
		"action":"mine",
		"id":"test_mine_01",
		"resource":"wood",
		"team":"player"
	}, null)
	assert(int(economy.resources["wood"]) == initial_wood + 60, "First mine collection must grant exactly 60 wood.")
	assert(economy.secured_mines.has("test_mine_01"), "Collected mine must be marked secured.")

	var second_result: String = economy.perform_building_action({
		"action":"mine",
		"id":"test_mine_01",
		"resource":"wood",
		"team":"player"
	}, null)
	assert(int(economy.resources["wood"]) == initial_wood + 60, "A secured mine must not grant resources twice.")
	assert(second_result.contains("سابقاً"), "Repeated collection must explain that the mine was already secured.")

	var enemy_result: String = economy.perform_building_action({
		"action":"mine",
		"id":"enemy_mine",
		"resource":"metal",
		"team":"enemy"
	}, null)
	assert(int(economy.resources["metal"]) == 300, "Enemy mines must not grant player resources.")
	assert(enemy_result.contains("العدو"), "Enemy mine interaction must be rejected.")

	var invalid_result: String = economy.perform_building_action({
		"action":"mine",
		"id":"invalid_mine",
		"resource":"gold",
		"team":"player"
	}, null)
	assert(not economy.secured_mines.has("invalid_mine"), "Invalid resource types must not secure a mine.")
	assert(invalid_result.contains("غير صالح"), "Invalid resource types must be rejected.")

	var before_payment: int = int(economy.resources["wood"])
	assert(economy.can_afford_building("barracks"), "Initial resources should cover a barracks.")
	assert(economy.pay_building_cost("barracks"), "Barracks payment should succeed when affordable.")
	assert(int(economy.resources["wood"]) == before_payment - 120, "Barracks payment must deduct the exact wood cost.")
	assert(not economy.pay_building_cost("unknown_building"), "Unknown buildings must not be charged.")

	var building_manager := BuildingPlacementManagerScript.new()
	building_manager.configure(null, economy, [])
	root.add_child(building_manager)
	await process_frame
	assert(building_manager.can_build("barracks"), "A barracks should be buildable before one exists.")
	building_manager._create_building("barracks", Vector2(-60.0, -4.0))
	assert(not building_manager.can_build("barracks"), "A normal building type must be limited to one instance.")
	var protected_footprints: Array[Dictionary] = [
		{"center":Vector2(-55.0,0.0),"size":Vector2(23.0,15.0),"label":"HQ"},
		{"center":Vector2(-34.0,-25.0),"size":Vector2(5.0,5.0),"label":"mine"},
		{"center":Vector2(-34.0,-9.0),"size":Vector2(5.0,5.0),"label":"mine"},
		{"center":Vector2(-34.0,9.0),"size":Vector2(5.0,5.0),"label":"mine"},
		{"center":Vector2(-34.0,25.0),"size":Vector2(5.0,5.0),"label":"mine"}
	]
	var placement_manager := BuildingPlacementManagerScript.new()
	placement_manager.configure(null,economy,protected_footprints)
	root.add_child(placement_manager)
	await process_frame
	assert(not placement_manager._is_slot_available(Vector2(-55.0,0.0),Vector2(3.0,3.0)), "HQ footprint must block construction.")
	assert(not placement_manager._is_slot_available(Vector2(-34.0,9.0),Vector2(3.0,3.0)), "Resource-site footprint must block construction.")
	assert(placement_manager._is_slot_available(Vector2(-47.0,11.0),Vector2(4.5,4.5)), "A clear slot beside the HQ must remain usable.")
	assert(not placement_manager._is_slot_available(Vector2(-47.0,10.0),Vector2(4.5,4.5)), "Safety gap must block a footprint too close to the HQ.")
	assert(not placement_manager._is_slot_available(Vector2(-14.0,11.0),Vector2(4.5,4.5)), "Buildings must not be placed in the bridge approach district.")
	assert(not placement_manager._is_slot_available(Vector2(0.0,11.0),Vector2(4.5,4.5)), "Buildings must never cross into the river/bridge corridor.")
	assert(not placement_manager._is_slot_available(Vector2(20.0,11.0),Vector2(4.5,4.5)), "Buildings must never be placed near the enemy side.")
	placement_manager._create_building("power",Vector2(-47.0,11.0))
	assert(not placement_manager._is_slot_available(Vector2(-47.0,15.0),Vector2(4.5,4.5)), "New buildings must reserve their full footprint plus safety gap.")
	assert(placement_manager.can_build("barracks"), "At least one collision-free standard building slot must remain available.")


	for index in range(4):
		building_manager._create_building("watchtower", Vector2(-60.0 + float(index) * 3.0, 12.0))
	assert(not building_manager.can_build("watchtower"), "Watchtowers must stop at the configured limit of four.")

	for index in range(10):
		building_manager._create_building("wall", Vector2(-70.0 + float(index) * 2.0, 18.0))
	assert(not building_manager.can_build("wall"), "Defensive walls must stop at the configured limit of ten.")

	print("IRON-FRONT regression tests: PASS")
	print("Verified one-time mine rewards, ownership/resource validation, exact building costs, and building-type limits.")
	quit(0)
