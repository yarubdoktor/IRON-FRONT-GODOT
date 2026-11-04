extends SceneTree

const InteractionControllerScript = preload("res://scripts/systems/interaction_controller.gd")
const BuildingPlacementManagerScript = preload("res://scripts/systems/building_placement_manager.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var interaction := InteractionControllerScript.new()
	var building_manager := BuildingPlacementManagerScript.new()
	building_manager.configure(null, null, [])
	root.add_child(building_manager)
	await process_frame
	interaction.building_manager = building_manager

	# A two-finger gesture must never be interpreted as a world tap.
	var first_down := InputEventScreenTouch.new()
	first_down.index = 0
	first_down.position = Vector2(240.0, 360.0)
	first_down.pressed = true
	interaction._unhandled_input(first_down)
	assert(interaction.pointer_is_down, "The first finger should begin a potential single-finger gesture.")

	var second_down := InputEventScreenTouch.new()
	second_down.index = 1
	second_down.position = Vector2(520.0, 360.0)
	second_down.pressed = true
	interaction._unhandled_input(second_down)
	assert(interaction.touch_points.size() == 2, "Both finger indices must be tracked independently.")
	assert(interaction.multi_touch_gesture, "Adding a second finger must mark the gesture as multi-touch.")
	assert(not interaction.pointer_is_down, "A multi-touch gesture must cancel pending tap state.")

	var first_drag := InputEventScreenDrag.new()
	first_drag.index = 0
	first_drag.position = Vector2(250.0, 360.0)
	first_drag.relative = Vector2(10.0, 0.0)
	interaction._unhandled_input(first_drag)
	var second_drag := InputEventScreenDrag.new()
	second_drag.index = 1
	second_drag.position = Vector2(530.0, 360.0)
	second_drag.relative = Vector2(10.0, 0.0)
	interaction._unhandled_input(second_drag)

	var second_up := InputEventScreenTouch.new()
	second_up.index = 1
	second_up.position = Vector2(530.0, 360.0)
	second_up.pressed = false
	interaction._unhandled_input(second_up)
	assert(interaction.touch_points.size() == 1, "The remaining finger must stay tracked after the other finger lifts.")
	assert(interaction.multi_touch_gesture, "The gesture must remain multi-touch until all fingers are released.")
	assert(not interaction.pointer_is_down, "The remaining finger must not resume tap eligibility mid-gesture.")

	var first_up := InputEventScreenTouch.new()
	first_up.index = 0
	first_up.position = Vector2(250.0, 360.0)
	first_up.pressed = false
	interaction._unhandled_input(first_up)
	assert(interaction.touch_points.is_empty(), "All touch indices must be cleared after release.")
	assert(not interaction.multi_touch_gesture, "The multi-touch state must reset after every finger is released.")
	assert(not interaction.pointer_is_down, "No pointer may remain pressed after the gesture ends.")

	# A fresh single-finger tap must still be eligible after the pinch gesture.
	var fresh_down := InputEventScreenTouch.new()
	fresh_down.index = 2
	fresh_down.position = Vector2(300.0, 400.0)
	fresh_down.pressed = true
	interaction._unhandled_input(fresh_down)
	assert(interaction.pointer_is_down, "A new single-finger gesture should begin normally.")
	var fresh_up := InputEventScreenTouch.new()
	fresh_up.index = 2
	fresh_up.position = Vector2(301.0, 401.0)
	fresh_up.pressed = false
	# Do not invoke world picking in this isolated state test; verify the tracked
	# start point and release distance directly before clearing the gesture.
	assert(interaction.touch_starts.has(2), "The fresh finger start position must be recorded.")
	assert(interaction.touch_starts[2].distance_to(fresh_up.position) < 14.0, "A short fresh gesture should meet the tap movement threshold.")
	interaction._unhandled_input(fresh_up)
	assert(interaction.touch_points.is_empty(), "A fresh single-finger release must clear touch tracking.")

	print("IRON-FRONT interaction touch tests: PASS")
	quit(0)
