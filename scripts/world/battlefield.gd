extends Node3D

const MAP_MIN_X: float = -34.0
const MAP_MAX_X: float = 120.0
const MAP_MIN_Z: float = -40.0
const MAP_MAX_Z: float = 40.0
const MAP_WIDTH: float = MAP_MAX_X - MAP_MIN_X
const MAP_DEPTH: float = MAP_MAX_Z - MAP_MIN_Z
const MAP_CENTER_X: float = (MAP_MIN_X + MAP_MAX_X) * 0.5
const MIRROR_X: float = 86.0
const RIVER_X: float = 52.0
const BRIDGE_Z: Array[float] = [-26.0, -12.0, 0.0, 12.0, 26.0]
const PLAYER_MINES: Array[Vector3] = [
	Vector3(6.0, 0.0, -11.0),
	Vector3(8.0, 0.0, 20.0),
	Vector3(-10.0, 0.0, -18.0),
	Vector3(26.0, 0.0, -12.0)
]

var _ground_material: StandardMaterial3D
var _water_material: StandardMaterial3D
var _bridge_material: StandardMaterial3D
var _gold_material: StandardMaterial3D
var _rock_material: StandardMaterial3D

func _ready() -> void:
	_create_materials()
	_create_ground()
	_create_river()
	_create_bridges()
	_create_mines()
	_create_headquarters_markers()
	_create_tree_placements()

func _create_materials() -> void:
	_ground_material = _material(Color(0.22, 0.31, 0.23), 0.0, 0.96)
	_water_material = _material(Color(0.10, 0.25, 0.27), 0.12, 0.3)
	_bridge_material = _material(Color(0.34, 0.29, 0.21), 0.0, 0.9)
	_gold_material = _material(Color(0.83, 0.65, 0.25), 0.58, 0.32)
	_rock_material = _material(Color(0.28, 0.29, 0.26), 0.0, 1.0)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var result: StandardMaterial3D = StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	return result

func _create_ground() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(MAP_WIDTH, MAP_DEPTH)
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "BattlefieldGround"
	ground.mesh = plane
	ground.material_override = _ground_material
	ground.position = Vector3(MAP_CENTER_X, 0.0, 0.0)
	add_child(ground)

func _create_river() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(2.6, MAP_DEPTH)
	var river: MeshInstance3D = MeshInstance3D.new()
	river.name = "CentralRiver"
	river.mesh = plane
	river.material_override = _water_material
	river.position = Vector3(RIVER_X, 0.035, 0.0)
	add_child(river)

	_add_box("WestRiverBank", Vector3(0.45, 0.16, MAP_DEPTH), Vector3(RIVER_X - 1.48, 0.02, 0.0), _rock_material)
	_add_box("EastRiverBank", Vector3(0.45, 0.16, MAP_DEPTH), Vector3(RIVER_X + 1.48, 0.02, 0.0), _rock_material)

func _create_bridges() -> void:
	for index: int in range(BRIDGE_Z.size()):
		var z: float = BRIDGE_Z[index]
		var deck: MeshInstance3D = _add_box(
			"Bridge_%02d" % index,
			Vector3(8.4, 0.34, 3.25),
			Vector3(RIVER_X, 0.22, z),
			_bridge_material
		)
		deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for plank_index: int in range(9):
			var x: float = RIVER_X - 3.7 + float(plank_index) * 0.92
			_add_box(
				"Bridge_%02d_Plank_%02d" % [index, plank_index],
				Vector3(0.075, 0.37, 3.28),
				Vector3(x, 0.25, z),
				_rock_material
			)

func _create_mines() -> void:
	for index: int in range(PLAYER_MINES.size()):
		var player_position: Vector3 = PLAYER_MINES[index]
		_create_mine("Player_Mine_%d" % (index + 1), player_position, false, index + 1)
		var enemy_position: Vector3 = Vector3(MIRROR_X - player_position.x, 0.0, -player_position.z)
		_create_mine("Enemy_Mine_%d" % (index + 1), enemy_position, true, index + 1)

func _create_mine(mine_name: String, world_position: Vector3, enemy: bool, mine_index: int) -> void:
	var mine: Node3D = Node3D.new()
	mine.name = mine_name
	mine.position = world_position
	add_child(mine)

	var rock_mesh: SphereMesh = SphereMesh.new()
	rock_mesh.radius = 1.05
	rock_mesh.height = 1.55
	var rock: MeshInstance3D = MeshInstance3D.new()
	rock.mesh = rock_mesh
	rock.material_override = _rock_material
	rock.scale = Vector3(1.2, 0.8, 1.0)
	rock.position.y = 0.62
	mine.add_child(rock)

	for crystal_index: int in range(3):
		var crystal_mesh: CylinderMesh = CylinderMesh.new()
		crystal_mesh.top_radius = 0.025
		crystal_mesh.bottom_radius = 0.22
		crystal_mesh.height = 0.72 + float(crystal_index) * 0.12
		crystal_mesh.radial_segments = 5
		var crystal: MeshInstance3D = MeshInstance3D.new()
		crystal.mesh = crystal_mesh
		crystal.material_override = _gold_material
		crystal.position = Vector3(-0.42 + float(crystal_index) * 0.4, 1.15, 0.1 if crystal_index == 1 else -0.22)
		crystal.rotation_degrees.z = -8.0 + float(crystal_index) * 9.0
		mine.add_child(crystal)

	var marker: Label3D = Label3D.new()
	marker.text = "MINE %02d%s" % [mine_index, "  •  ENEMY" if enemy else ""]
	marker.position = Vector3(0.0, 2.25, 0.0)
	marker.font_size = 32
	marker.modulate = Color(0.94, 0.78, 0.42) if not enemy else Color(0.91, 0.52, 0.42)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mine.add_child(marker)

func _create_headquarters_markers() -> void:
	_create_hq_marker("PLAYER_HQ", Vector3(-12.0, 0.0, 4.0), Color(0.72, 0.78, 0.55))
	_create_hq_marker("ENEMY_HQ", Vector3(98.0, 0.0, -4.0), Color(0.72, 0.38, 0.3))

func _create_hq_marker(marker_name: String, world_position: Vector3, color: Color) -> void:
	var base: MeshInstance3D = MeshInstance3D.new()
	base.name = marker_name
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 2.4
	cylinder.bottom_radius = 3.0
	cylinder.height = 0.3
	base.mesh = cylinder
	base.material_override = _material(color, 0.1, 0.75)
	base.position = world_position + Vector3(0.0, 0.16, 0.0)
	add_child(base)

	var mast: MeshInstance3D = MeshInstance3D.new()
	var pole: CylinderMesh = CylinderMesh.new()
	pole.top_radius = 0.06
	pole.bottom_radius = 0.08
	pole.height = 4.0
	mast.mesh = pole
	mast.material_override = _gold_material
	mast.position = world_position + Vector3(0.0, 2.2, 0.0)
	add_child(mast)

func _create_tree_placements() -> void:
	var placements: Array[Vector3] = [
		Vector3(-25, 0, -28), Vector3(-20, 0, -22), Vector3(-27, 0, -12),
		Vector3(-22, 0, 16), Vector3(-27, 0, 27), Vector3(-16, 0, 31),
		Vector3(0, 0, 29), Vector3(15, 0, 31), Vector3(24, 0, 26),
		Vector3(31, 0, -30), Vector3(37, 0, -22), Vector3(43, 0, 26),
		Vector3(64, 0, -30), Vector3(70, 0, -22), Vector3(74, 0, 29),
		Vector3(88, 0, 28), Vector3(105, 0, 27), Vector3(111, 0, 12),
		Vector3(109, 0, -25), Vector3(91, 0, -30), Vector3(15, 0, -30),
		Vector3(0, 0, -29), Vector3(58, 0, 31), Vector3(32, 0, 21)
	]
	for index: int in range(placements.size()):
		var tree_path: String = "res://assets/3d/nature/mature-oak.glb"
		if index % 3 == 1:
			tree_path = "res://assets/3d/nature/mature-sycamore.glb"
		elif index % 3 == 2:
			tree_path = "res://assets/3d/nature/mature-spruce.glb"
		_place_glb(tree_path, placements[index], 1.25 if index % 4 == 0 else 1.0)

func _place_glb(resource_path: String, world_position: Vector3, uniform_scale: float) -> void:
	if not ResourceLoader.exists(resource_path):
		return
	var packed_scene: PackedScene = load(resource_path) as PackedScene
	if packed_scene == null:
		return
	var instance: Node3D = packed_scene.instantiate() as Node3D
	if instance == null:
		return
	instance.position = world_position
	instance.scale = Vector3.ONE * uniform_scale
	add_child(instance)

func _add_box(box_name: String, box_size: Vector3, world_position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_resource: BoxMesh = BoxMesh.new()
	mesh_resource.size = box_size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = box_name
	instance.mesh = mesh_resource
	instance.material_override = material
	instance.position = world_position
	add_child(instance)
	return instance
