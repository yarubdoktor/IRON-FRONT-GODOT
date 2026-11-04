extends SceneTree

const CameraControllerScript = preload("res://scripts/camera/camera_controller.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var controller := CameraControllerScript.new()
	root.add_child(controller)
	await process_frame

	var start_position: Vector3 = controller.camera.position
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.position = Vector2(300.0, 300.0)
	touch_down.pressed = true
	controller._unhandled_input(touch_down)

	var single_drag := InputEventScreenDrag.new()
	single_drag.index = 0
	single_drag.position = Vector2(340.0, 320.0)
	single_drag.relative = Vector2(40.0, 20.0)
	controller._unhandled_input(single_drag)
	assert(not is_equal_approx(controller.camera.position.x, start_position.x), "Single-finger drag must pan the camera horizontally.")
	assert(not is_equal_approx(controller.camera.position.z, start_position.z), "Single-finger drag must pan the camera vertically.")

	var touch_two := InputEventScreenTouch.new()
	touch_two.index = 1
	touch_two.position = Vector2(500.0, 300.0)
	touch_two.pressed = true
	controller._unhandled_input(touch_two)
	var height_before_pinch: float = controller.camera.position.y

	var pinch_drag := InputEventScreenDrag.new()
	pinch_drag.index = 1
	pinch_drag.position = Vector2(540.0, 300.0)
	pinch_drag.relative = Vector2(40.0, 0.0)
	controller._unhandled_input(pinch_drag)
	assert(not is_equal_approx(controller.camera.position.y, height_before_pinch), "Two-finger pinch must zoom the camera.")

	var release_second := InputEventScreenTouch.new()
	release_second.index = 1
	release_second.pressed = false
	controller._unhandled_input(release_second)
	var after_pinch_release: Vector3 = controller.camera.position
	var remaining_drag := InputEventScreenDrag.new()
	remaining_drag.index = 0
	remaining_drag.position = Vector2(360.0, 330.0)
	remaining_drag.relative = Vector2(20.0, 10.0)
	controller._unhandled_input(remaining_drag)
	assert(not is_equal_approx(controller.camera.position.x, after_pinch_release.x), "The remaining finger must resume one-finger panning after pinch ends.")

	var release_first := InputEventScreenTouch.new()
	release_first.index = 0
	release_first.pressed = false
	controller._unhandled_input(release_first)
	assert(controller.touch_points.is_empty(), "Touch tracking must clear after all fingers are released.")

	print("IRON-FRONT camera touch tests: PASS")
	controller.queue_free()
	await process_frame
	quit(0)
