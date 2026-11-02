extends SceneTree

const EconomyManagerScript = preload("res://scripts/systems/economy_manager.gd")

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

	print("IRON-FRONT economy tests: PASS")
	print("Mine collection is one-time, enemy/invalid mines are rejected, and building costs are exact.")
	quit(0)
