extends SceneTree

const EconomyManagerScript = preload("res://scripts/systems/economy_manager.gd")
const BuildingPlacementManagerScript = preload("res://scripts/systems/building_placement_manager.gd")
const UnitManagerScript = preload("res://scripts/systems/unit_manager.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var economy := EconomyManagerScript.new()
	root.add_child(economy)
	var units := UnitManagerScript.new()
	root.add_child(units)
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

	var upgrade_cost: Dictionary = economy.get_upgrade_cost("barracks","test_barracks_01")
	assert(not upgrade_cost.is_empty(), "A level-one barracks must have an upgrade cost.")
	assert(economy.can_upgrade_building("barracks","test_barracks_01"), "Initial resources should cover the first barracks upgrade.")
	assert(economy.upgrade_building("barracks","test_barracks_01"), "Affordable building upgrade should succeed.")
	assert(economy.get_building_level("test_barracks_01") == 2, "Successful upgrade must advance the building to level two.")
	var resources_before_failed_upgrade: Dictionary = economy.resources.duplicate(true)
	economy.resources = {"wood":0,"metal":0,"fuel":0,"stone":0}
	assert(not economy.upgrade_building("barracks","test_barracks_01"), "Upgrade must fail when resources are insufficient.")
	assert(economy.get_building_level("test_barracks_01") == 2, "Failed upgrade must not change the building level.")
	economy.resources = resources_before_failed_upgrade
	economy.set_building_levels({"max_level_building":10})
	assert(economy.get_upgrade_cost("barracks","max_level_building").is_empty(), "Maximum-level buildings must not expose another upgrade.")
	assert(not economy.upgrade_building("barracks","max_level_building"), "Maximum-level buildings must reject upgrades.")

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

	# Training actions must deduct the exact cost and create the expected unit.
	economy.resources = {"wood":500,"metal":300,"fuel":180,"stone":250}
	var infantry_before: int = units.units.size()
	var infantry_result: String = economy.perform_building_action({"action":"barracks","id":"training_barracks","team":"player"}, units)
	assert(units.units.size() == infantry_before + 1, "A successful barracks action must spawn one infantry unit.")
	assert(int(economy.resources["wood"]) == 420 and int(economy.resources["metal"]) == 265, "Infantry training must deduct 80 wood and 35 metal.")
	assert(infantry_result.contains("تدريب"), "Successful infantry training must return a confirmation.")

	var vehicles_before: int = units.units.size()
	var vehicle_result: String = economy.perform_building_action({"action":"factory","id":"training_factory","team":"player"}, units)
	assert(units.units.size() == vehicles_before + 1, "A successful factory action must spawn one vehicle.")
	assert(bool(units.units.back().get_meta("is_vehicle", false)), "Factory production must create a vehicle unit.")
	assert(int(economy.resources["metal"]) == 165 and int(economy.resources["fuel"]) == 135, "Vehicle production must deduct 100 metal and 45 fuel.")
	assert(vehicle_result.contains("دبابة"), "Successful factory production must return a confirmation.")

	var unit_count_before_failed_training: int = units.units.size()
	economy.resources = {"wood":0,"metal":0,"fuel":0,"stone":0}
	var failed_training_result: String = economy.perform_building_action({"action":"barracks","id":"training_barracks","team":"player"}, units)
	assert(units.units.size() == unit_count_before_failed_training, "Insufficient resources must not spawn a unit.")
	assert(failed_training_result.contains("غير كافية"), "Insufficient training resources must be reported.")

	var passive_before: Dictionary = economy.resources.duplicate(true)
	economy._produce_passive_resources()
	assert(int(economy.resources["wood"]) == int(passive_before["wood"]) + 3, "Passive production must add three wood.")
	assert(int(economy.resources["metal"]) == int(passive_before["metal"]) + 2, "Passive production must add two metal.")
	assert(int(economy.resources["fuel"]) == int(passive_before["fuel"]) + 2, "Passive production must add two fuel.")
	assert(int(economy.resources["stone"]) == int(passive_before["stone"]) + 2, "Passive production must add two stone.")

	print("IRON-FRONT regression tests: PASS")
	print("Verified mining, costs, upgrades, building limits, training, passive production and affordability.")
	building_manager.queue_free()
	placement_manager.queue_free()
	units.queue_free()
	economy.queue_free()
	await process_frame
	quit(0)
