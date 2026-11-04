class_name CameraController
extends Node3D

const CAMERA_MIN_HEIGHT := 36.0
const CAMERA_MAX_HEIGHT := 76.0
const CAMERA_MIN_X := -38.0
const CAMERA_MAX_X := 38.0
const CAMERA_MIN_Z := 48.0
const CAMERA_MAX_Z := 84.0
const PAN_SENSITIVITY := 0.0015
const PINCH_SENSITIVITY := 0.12

var camera: Camera3D
var camera_dragging := false
var touch_points: Dictionary = {}

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "BattleCamera"
	camera.position = Vector3(0.0, 62.0, 68.0)
	camera.rotation_degrees = Vector3(-43.0, 0.0, 0.0)
	camera.current = true
	camera.fov = 48.0
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(-4.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(4.0)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			camera_dragging = event.pressed
	elif event is InputEventMouseMotion and camera_dragging:
		_pan_camera(event.relative)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_points[event.index] = event.position
		camera_dragging = true
	else:
		touch_points.erase(event.index)
		camera_dragging = not touch_points.is_empty()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not touch_points.has(event.index):
		touch_points[event.index] = event.position
		return

	if touch_points.size() >= 2:
		var old_distance: float = _touch_distance()
		touch_points[event.index] = event.position
		var new_distance: float = _touch_distance()
		if old_distance > 1.0 and new_distance > 1.0:
			_zoom_camera((old_distance - new_distance) * PINCH_SENSITIVITY)
	else:
		touch_points[event.index] = event.position
		_pan_camera(event.relative)

func _touch_distance() -> float:
	if touch_points.size() < 2:
		return 0.0
	var points: Array = touch_points.values()
	return Vector2(points[0]).distance_to(Vector2(points[1]))

func _pan_camera(relative: Vector2) -> void:
	if camera == null:
		return
	var pan_scale: float = camera.position.y * PAN_SENSITIVITY
	camera.position.x = clampf(camera.position.x - relative.x * pan_scale, CAMERA_MIN_X, CAMERA_MAX_X)
	camera.position.z = clampf(camera.position.z - relative.y * pan_scale, CAMERA_MIN_Z, CAMERA_MAX_Z)

func _zoom_camera(amount: float) -> void:
	if camera == null:
		return
	camera.position.y = clampf(camera.position.y + amount, CAMERA_MIN_HEIGHT, CAMERA_MAX_HEIGHT)
	camera.position.z = clampf(camera.position.z + amount * 0.45, CAMERA_MIN_Z, CAMERA_MAX_Z)
	camera.position.x = clampf(camera.position.x, CAMERA_MIN_X, CAMERA_MAX_X)
