extends Node3D

const MAP_SIZE := Vector2(160.0, 80.0)
const RIVER_WIDTH := 8.0
const BRIDGE_Z_POSITIONS: Array[float] = [-30.0, -15.0, 0.0, 15.0, 30.0]

func _ready() -> void:
	_create_camera()
	_create_lighting()
	_create_ground()
	_create_river_and_bridges()
	_create_headquarters()
	_create_resource_markers()


func _create_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "BattleCamera"
	camera.position = Vector3(0.0, 58.0, 62.0)
	camera.rotation_degrees = Vector3(-43.0, 0.0, 0.0)
	camera.current = true
	camera.fov = 48.0
	add_child(camera)


func _create_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)


func _create_ground() -> void:
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = MAP_SIZE
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.24, 0.34, 0.22)
	ground_material.roughness = 1.0
	var ground := MeshInstance3D.new()
	ground.name = "BattlefieldGround"
	ground.mesh = ground_mesh
	ground.material_override = ground_material
	ground.position.y = -0.35
	add_child(ground)


func _create_river_and_bridges() -> void:
	_add_box("River", Vector3(RIVER_WIDTH, 0.12, MAP_SIZE.y), Vector3(0.0, -0.20, 0.0), Color(0.12, 0.31, 0.43))
	for index in range(BRIDGE_Z_POSITIONS.size()):
		var bridge_z: float = BRIDGE_Z_POSITIONS[index]
		_add_box("Bridge_%02d" % index, Vector3(RIVER_WIDTH + 3.0, 0.35, 4.2), Vector3(0.0, 0.05, bridge_z), Color(0.43, 0.37, 0.27))


func _create_headquarters() -> void:
	_add_box("Player_HQ_Base", Vector3(12.0, 1.0, 10.0), Vector3(-55.0, 0.2, 0.0), Color(0.30, 0.39, 0.28))
	_add_box("Enemy_HQ_Base", Vector3(12.0, 1.0, 10.0), Vector3(55.0, 0.2, 0.0), Color(0.43, 0.27, 0.23))
	_add_box("Player_HQ_Marker", Vector3(3.0, 5.0, 3.0), Vector3(-55.0, 3.0, 0.0), Color(0.72, 0.78, 0.54))
	_add_box("Enemy_HQ_Marker", Vector3(3.0, 5.0, 3.0), Vector3(55.0, 3.0, 0.0), Color(0.78, 0.48, 0.38))


func _create_resource_markers() -> void:
	var mine_positions: Array[Vector3] = [
		Vector3(-34.0, 0.1, -25.0),
		Vector3(-34.0, 0.1, -9.0),
		Vector3(-34.0, 0.1, 9.0),
		Vector3(-34.0, 0.1, 25.0),
		Vector3(34.0, 0.1, -25.0),
		Vector3(34.0, 0.1, -9.0),
		Vector3(34.0, 0.1, 9.0),
		Vector3(34.0, 0.1, 25.0)
	]
	for index in range(mine_positions.size()):
		var marker_color := Color(0.72, 0.61, 0.32) if index < 4 else Color(0.62, 0.43, 0.34)
		_add_box("ResourceSite_%02d" % index, Vector3(3.0, 1.0, 3.0), mine_positions[index], marker_color)


func _add_box(node_name: String, box_size: Vector3, world_position: Vector3, color: Color) -> void:
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	mesh_instance.position = world_position
	add_child(mesh_instance)
