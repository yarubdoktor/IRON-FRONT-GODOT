extends Node3D

@export var min_distance: float = 28.0
@export var max_distance: float = 112.0
@export var pan_sensitivity: float = 0.0022
@export var orbit_sensitivity: float = 0.006

@onready var camera: Camera3D = $Camera3D

var _distance: float = 62.0
var _yaw: float = 0.0
var _pitch: float = 0.66
var _mouse_pan: bool = false
var _mouse_orbit: bool = false
var _touch_positions: Dictionary = {}

func _ready() -> void:
	_apply_camera()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		_mouse_pan = event.pressed
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_mouse_orbit = event.pressed
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(-4.0)
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(4.0)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _mouse_pan:
		_pan(event.relative)
	elif _mouse_orbit:
		_yaw -= event.relative.x * orbit_sensitivity
		_apply_camera()

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_positions[event.index] = event.position
	else:
		_touch_positions.erase(event.index)

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _touch_positions.has(event.index):
		return
	var old_distance: float = _pinch_distance()
	_touch_positions[event.index] = event.position
	if _touch_positions.size() == 1:
		_pan(event.relative * 0.65)
	elif _touch_positions.size() >= 2:
		var new_distance: float = _pinch_distance()
		if old_distance > 0.0 and new_distance > 0.0:
			_zoom((old_distance - new_distance) * 0.035)

func _pinch_distance() -> float:
	if _touch_positions.size() < 2:
		return 0.0
	var keys: Array = _touch_positions.keys()
	var first: Vector2 = _touch_positions[keys[0]]
	var second: Vector2 = _touch_positions[keys[1]]
	return first.distance_to(second)

func _zoom(amount: float) -> void:
	_distance = clampf(_distance + amount, min_distance, max_distance)
	_apply_camera()

func _pan(screen_delta: Vector2) -> void:
	var right: Vector3 = camera.global_transform.basis.x
	var forward: Vector3 = -camera.global_transform.basis.z
	right.y = 0.0
	forward.y = 0.0
	right = right.normalized()
	forward = forward.normalized()
	global_position += (-right * screen_delta.x - forward * screen_delta.y) * (_distance * pan_sensitivity)
	global_position.x = clampf(global_position.x, -34.0, 120.0)
	global_position.z = clampf(global_position.z, -40.0, 40.0)

func _apply_camera() -> void:
	if camera == null:
		return
	var horizontal: float = cos(_pitch) * _distance
	camera.position = Vector3(sin(_yaw) * horizontal, sin(_pitch) * _distance, cos(_yaw) * horizontal)
	camera.look_at(Vector3.ZERO, Vector3.UP)
