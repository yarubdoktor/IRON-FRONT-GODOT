extends SceneTree

const EconomyManagerScript = preload("res://scripts/systems/economy_manager.gd")
const UnitManagerScript = preload("res://scripts/systems/unit_manager.gd")
const BuildingPlacementManagerScript = preload("res://scripts/systems/building_placement_manager.gd")
const PersistenceManagerScript = preload("res://scripts/systems/persistence_manager.gd")
const HUDControllerScript = preload("res://scripts/ui/hud_controller.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var economy := EconomyManagerScript.new()
	root.add_child(economy)
	var units := UnitManagerScript.new()
	root.add_child(units)
	var buildings := BuildingPlacementManagerScript.new()
	buildings.configure(null, economy, [])
	root.add_child(buildings)
	var hud := HUDControllerScript.new()
	root.add_child(hud)
	await process_frame

	var persistence := PersistenceManagerScript.new()
	persistence.configure(economy, buildings, units, hud)

	economy.resources = {"wood":777,"metal":555,"fuel":333,"stone":222}
	economy.secured_mines = {"mine_alpha":true,"mine_beta":true}
	economy.set_building_levels({"barracks_test":3})
	buildings._create_building("barracks", Vector2(-47.0,-17.0), 0.0, "barracks_test", 3)
	units.spawn_vehicle()
	units.set_rally_point(Vector3(-30.0,0.0,12.0))
	var saved_unit_count: int = units.units.size()
	var saved_rally_position: Vector3 = units.rally_position

	persistence.save_game()

	economy.resources = {"wood":1,"metal":1,"fuel":1,"stone":1}
	economy.secured_mines.clear()
	economy.building_levels.clear()
	buildings.load_save_data([])
	units.load_save_data([])
	units.cancel_rally_point()

	persistence.load_game()

	assert(economy.resources == {"wood":777,"metal":555,"fuel":333,"stone":222}, "Loading must restore all four resource balances exactly.")
	assert(economy.secured_mines == {"mine_alpha":true,"mine_beta":true}, "Loading must restore secured mine identifiers.")
	assert(economy.get_building_level("barracks_test") == 3, "Loading must restore building upgrade levels.")
	assert(buildings.placed_buildings.size() == 1, "Loading must recreate the saved building exactly once.")
	assert(str(buildings.placed_buildings[0].get("id","")) == "barracks_test", "The restored building must retain its stable ID.")
	assert(units.units.size() == saved_unit_count, "Loading must restore the saved army size.")
	assert(bool(units.units.back().get_meta("is_vehicle", false)), "Loading must preserve the saved vehicle type.")
	assert(units.rally_active, "Loading must restore an active rally point.")
	assert(units.rally_position.distance_to(saved_rally_position) < 0.01, "Loading must restore the rally coordinates.")

	print("IRON-FRONT persistence regression tests: PASS")
	persistence.free()
	hud.queue_free()
	buildings.queue_free()
	units.queue_free()
	economy.queue_free()
	await process_frame
	quit(0)
