class_name UnitManager
extends Node3D

var units: Array[Node3D] = []
var selected_all := false
var next_unit_id := 1

func _ready() -> void:
	for index in range(5):
		_create_unit(Vector3(-48.0 + float(index % 3) * 3.0, 0.0, 8.0 + float(index / 3) * 3.0), false)

func _create_unit(world_position: Vector3, vehicle: bool) -> void:
	var unit := Node3D.new()
	unit.name = ("Vehicle_" if vehicle else "Infantry_") + str(next_unit_id)
	next_unit_id += 1
	unit.position = world_position
	unit.set_meta("is_player_unit",true)
	unit.set_meta("is_vehicle",vehicle)
	var body_mesh := MeshInstance3D.new()
	if vehicle:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.5,1.0,3.6)
		body_mesh.mesh = mesh
		body_mesh.position.y = 0.75
	else:
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.48
		mesh.height = 1.8
		body_mesh.mesh = mesh
		body_mesh.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25,0.38,0.23) if not vehicle else Color(0.28,0.31,0.29)
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
	marker_material.albedo_color = Color(0.22,0.82,0.42,0.8)
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = marker_material
	marker.position.y = 0.08
	marker.visible = false
	unit.add_child(marker)
	unit.set_meta("selection_marker",marker)
	add_child(unit)
	units.append(unit)

func spawn_infantry() -> void:
	_create_unit(Vector3(-46.0,0.0,12.0),false)

func spawn_vehicle() -> void:
	_create_unit(Vector3(-40.0,0.0,-13.0),true)

func select_all() -> int:
	selected_all = true
	for unit in units:
		var marker: MeshInstance3D = unit.get_meta("selection_marker")
		marker.visible = true
	return units.size()

func move_selected_to(destination: Vector3) -> void:
	if not selected_all:
		return
	for index in range(units.size()):
		var row: int = int(index / 3)
		var col: int = index % 3
		var offset := Vector3(float(col - 1) * 2.2,0.0,float(row) * 2.2)
		var target: Vector3 = destination + offset
		var tween := create_tween()
		tween.tween_property(units[index],"position",target,1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func get_save_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for unit in units:
		data.append({"position":unit.position,"vehicle":bool(unit.get_meta("is_vehicle",false))})
	return data


func load_save_data(data: Array) -> void:
	for unit in units:
		unit.queue_free()
	units.clear()
	for item in data:
		if item is Dictionary:
			var position_value: Variant = item.get("position",Vector3(-48.0,0.0,8.0))
			if position_value is Vector3:
				_create_unit(position_value,bool(item.get("vehicle",false)))
	selected_all = false
