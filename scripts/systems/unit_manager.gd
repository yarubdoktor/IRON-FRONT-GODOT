class_name UnitManager
extends Node3D

const PLAYER_MIN_X: float = -77.0
const PLAYER_MAX_X: float = -9.0
const MAP_MIN_Z: float = -36.0
const MAP_MAX_Z: float = 36.0
const MOVE_SPEED: float = 4.0

var units: Array[Node3D] = []
var selected_units: Array[Node3D] = []
var selected_all := false
var next_unit_id := 1
var movement_id := 0
var pending_arrivals := 0
var rally_active := false
var rally_position := Vector3.ZERO
var rally_sequence := 0
var rally_marker: Node3D

func _ready() -> void:
	for index in range(5):
		_create_unit(Vector3(-48.0 + float(index % 3) * 3.0, 0.0, 8.0 + float(index / 3) * 3.0), false)

func _create_unit(world_position: Vector3, vehicle: bool) -> void:
	var unit := Node3D.new()
	unit.name = ("Vehicle_" if vehicle else "Infantry_") + str(next_unit_id)
	next_unit_id += 1
	unit.position = world_position
	unit.set_meta("is_player_unit", true)
	unit.set_meta("is_vehicle", vehicle)
	var body_mesh := MeshInstance3D.new()
	if vehicle:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.5, 1.0, 3.6)
		body_mesh.mesh = mesh
		body_mesh.position.y = 0.75
	else:
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.48
		mesh.height = 1.8
		body_mesh.mesh = mesh
		body_mesh.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.38, 0.23) if not vehicle else Color(0.28, 0.31, 0.29)
	body_mesh.material_override = material
	unit.add_child(body_mesh)

	var marker := MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 0.9
	ring.bottom_radius = 0.9
	ring.height = 0.06
	ring.radial_segments = 16
	marker.mesh = ring
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.22, 0.82, 0.42, 0.8)
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = marker_material
	marker.position.y = 0.08
	marker.visible = false
	unit.add_child(marker)
	unit.set_meta("selection_marker", marker)

	var click_area := Area3D.new()
	click_area.name = "UnitClickArea"
	click_area.position.y = 0.9
	click_area.collision_layer = 2
	click_area.collision_mask = 0
	click_area.set_meta("is_player_unit", true)
	var click_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.0 if vehicle else 0.85
	capsule.height = 2.8
	click_shape.shape = capsule
	click_area.add_child(click_shape)
	unit.add_child(click_area)
	add_child(unit)
	units.append(unit)

func spawn_infantry() -> void:
	_create_unit(Vector3(-46.0, 0.0, 12.0), false)
	_dispatch_reinforcement_to_rally(units[units.size() - 1])

func spawn_vehicle() -> void:
	_create_unit(Vector3(-40.0, 0.0, -13.0), true)
	_dispatch_reinforcement_to_rally(units[units.size() - 1])

func set_rally_point(world_position: Vector3) -> void:
	rally_position = Vector3(
		clampf(world_position.x, PLAYER_MIN_X, PLAYER_MAX_X),
		0.0,
		clampf(world_position.z, MAP_MIN_Z, MAP_MAX_Z)
	)
	rally_active = true
	if rally_marker == null:
		_create_rally_marker()
	rally_marker.position = rally_position
	rally_marker.visible = true

func cancel_rally_point() -> void:
	rally_active = false
	if rally_marker != null:
		rally_marker.visible = false

func _create_rally_marker() -> void:
	rally_marker = Node3D.new()
	rally_marker.name = "RallyPointMarker"
	var ground_ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 2.0
	ring_mesh.bottom_radius = 2.0
	ring_mesh.height = 0.10
	ring_mesh.radial_segments = 32
	ground_ring.mesh = ring_mesh
	ground_ring.position.y = 0.08
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(1.0, 0.66, 0.12, 0.92)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.8, 0.32, 0.04)
	ground_ring.material_override = ring_material
	rally_marker.add_child(ground_ring)
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.08
	pole_mesh.height = 3.2
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, 1.7, 0.0)
	pole.material_override = ring_material
	rally_marker.add_child(pole)
	var flag := MeshInstance3D.new()
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(1.25, 0.72, 0.08)
	flag.mesh = flag_mesh
	flag.position = Vector3(0.62, 2.85, 0.0)
	flag.material_override = ring_material
	rally_marker.add_child(flag)
	add_child(rally_marker)

func _dispatch_reinforcement_to_rally(unit: Node3D) -> void:
	if not rally_active or not is_instance_valid(unit):
		return
	rally_sequence += 1
	var index: int = rally_sequence - 1
	var col: int = index % 5
	var row: int = int(index / 5)
	var offset := Vector3(float(col - 2) * 2.4, 0.0, float(row) * 2.4)
	var target := Vector3(
		clampf(rally_position.x + offset.x, PLAYER_MIN_X, PLAYER_MAX_X),
		0.0,
		clampf(rally_position.z + offset.z, MAP_MIN_Z, MAP_MAX_Z)
	)
	var duration: float = maxf(unit.position.distance_to(target) / MOVE_SPEED, 0.5)
	var tween := create_tween()
	tween.tween_property(unit, "position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func toggle_select_all() -> int:
	if selected_all:
		clear_selection()
		return 0
	clear_selection()
	selected_all = true
	for unit in units:
		_set_unit_selected(unit, true)
	return selected_units.size()

func select_unit(unit: Node3D) -> void:
	if not is_instance_valid(unit) or not units.has(unit):
		return
	clear_selection()
	_set_unit_selected(unit, true)
	selected_all = false

func clear_selection() -> void:
	for unit in selected_units:
		if is_instance_valid(unit):
			_set_marker_visible(unit, false)
	selected_units.clear()
	selected_all = false

func _set_unit_selected(unit: Node3D, is_selected: bool) -> void:
	if is_selected:
		if not selected_units.has(unit):
			selected_units.append(unit)
	else:
		selected_units.erase(unit)
	_set_marker_visible(unit, is_selected)

func _set_marker_visible(unit: Node3D, is_visible: bool) -> void:
	var marker_value: Variant = unit.get_meta("selection_marker", null)
	if marker_value is MeshInstance3D:
		marker_value.visible = is_visible

func move_selected_to(destination: Vector3) -> void:
	if selected_units.is_empty():
		return
	movement_id += 1
	var this_movement: int = movement_id
	var moving_units: Array[Node3D] = selected_units.duplicate()
	pending_arrivals = 0
	var count: int = moving_units.size()
	for index in range(count):
		var unit: Node3D = moving_units[index]
		if not is_instance_valid(unit):
			continue
		var row: int = int(index / 3)
		var col: int = index % 3
		var offset := Vector3(float(col - 1) * 2.2, 0.0, float(row) * 2.2)
		var raw_target: Vector3 = destination + offset
		var target := Vector3(
			clampf(raw_target.x, PLAYER_MIN_X, PLAYER_MAX_X),
			0.0,
			clampf(raw_target.z, MAP_MIN_Z, MAP_MAX_Z)
		)
		var distance: float = unit.position.distance_to(target)
		if distance < 0.15:
			continue
		var duration: float = maxf(distance / MOVE_SPEED, 0.35)
		pending_arrivals += 1
		var tween := create_tween()
		tween.tween_property(unit, "position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(_on_unit_arrived.bind(this_movement))
	if pending_arrivals == 0:
		clear_selection()

func _on_unit_arrived(this_movement: int) -> void:
	if this_movement != movement_id:
		return
	pending_arrivals = maxi(pending_arrivals - 1, 0)
	if pending_arrivals == 0:
		clear_selection()

func get_save_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for unit in units:
		data.append({"position": unit.position, "vehicle": bool(unit.get_meta("is_vehicle", false))})
	return data

func load_save_data(data: Array) -> void:
	for unit in units:
		unit.queue_free()
	units.clear()
	selected_units.clear()
	selected_all = false
	for item in data:
		if item is Dictionary:
			var position_value: Variant = item.get("position", Vector3(-48.0, 0.0, 8.0))
			if position_value is Vector3:
				_create_unit(position_value, bool(item.get("vehicle", false)))
