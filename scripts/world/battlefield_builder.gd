class_name BattlefieldBuilder
extends Node3D

const MAP_SIZE := Vector2(160.0, 80.0)
const BRIDGE_Z_POSITIONS: Array[float] = [-30.0, -15.0, 0.0, 15.0, 30.0]

func _ready() -> void:
	_create_lighting()
	_create_environment()
	_create_ground()
	_create_river_and_bridges()
	_create_terrain_details()
	_create_headquarters()
	_create_resource_sites()
	_create_player_buildings()

func _create_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 95.0
	add_child(sun)


func _create_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.19, 0.31, 0.43)
	sky_material.sky_horizon_color = Color(0.72, 0.76, 0.69)
	sky_material.ground_bottom_color = Color(0.16, 0.20, 0.17)
	sky_material.ground_horizon_color = Color(0.48, 0.52, 0.43)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.62, 0.57)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	world.environment = environment
	add_child(world)


func _create_ground() -> void:
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = MAP_SIZE
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.27, 0.36, 0.24)
	ground_material.roughness = 1.0
	var ground := MeshInstance3D.new()
	ground.name = "BattlefieldGround"
	ground.mesh = ground_mesh
	ground.material_override = ground_material
	ground.position.y = -0.35
	add_child(ground)
	_add_box("WestField", Vector3(67.0, 0.08, 80.0), Vector3(-46.5, -0.27, 0.0), Color(0.30, 0.39, 0.25))
	_add_box("EastField", Vector3(67.0, 0.08, 80.0), Vector3(46.5, -0.27, 0.0), Color(0.32, 0.37, 0.23))


func _create_river_and_bridges() -> void:
	_add_box("River", Vector3(8.0, 0.12, MAP_SIZE.y), Vector3(0.0, -0.20, 0.0), Color(0.10, 0.28, 0.38))
	for index in range(BRIDGE_Z_POSITIONS.size()):
		var bridge_z: float = BRIDGE_Z_POSITIONS[index]
		_add_box("Bridge_%02d" % index, Vector3(11.0, 0.38, 4.2), Vector3(0.0, 0.02, bridge_z), Color(0.40, 0.32, 0.22))
		for rail_side in [-1.0, 1.0]:
			_add_box("BridgeRail_%02d_%s" % [index, str(rail_side)], Vector3(10.8, 0.42, 0.18), Vector3(0.0, 0.35, bridge_z + rail_side * 1.85), Color(0.24, 0.20, 0.15))


func _create_terrain_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 160416
	_add_scatter(rng, 76, -77.0, -13.0, -38.0, 38.0, Color(0.17, 0.27, 0.17))
	_add_scatter(rng, 76, 13.0, 77.0, -38.0, 38.0, Color(0.19, 0.29, 0.18))
	for side in [-1.0, 1.0]:
		var side_value: float = float(side)
		for index in range(8):
			var x: float = side_value * (17.0 + float(index) * 4.0)
			_add_box("Road_%s_%02d" % [str(side_value), index], Vector3(2.4, 0.035, 7.0), Vector3(x, -0.17, 0.0), Color(0.39, 0.35, 0.27))
	for index in range(26):
		var x := rng.randf_range(-76.0, 76.0)
		var z := rng.randf_range(-37.0, 37.0)
		if absf(x) < 13.0 or (absf(x) < 25.0 and absf(z) < 8.0):
			continue
		_add_rock(Vector3(x, 0.0, z), rng.randf_range(0.45, 1.25), rng)


func _add_scatter(rng: RandomNumberGenerator, count: int, min_x: float, max_x: float, min_z: float, max_z: float, crown_color: Color) -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.23
	trunk_mesh.height = 1.8
	trunk_mesh.radial_segments = 6
	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.25, 0.17, 0.11)
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.05
	crown_mesh.height = 2.0
	crown_mesh.radial_segments = 7
	crown_mesh.rings = 4
	var crown_material := StandardMaterial3D.new()
	crown_material.albedo_color = crown_color
	crown_material.roughness = 1.0
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	trunks.mesh = trunk_mesh
	trunks.instance_count = count
	var crowns := MultiMesh.new()
	crowns.transform_format = MultiMesh.TRANSFORM_3D
	crowns.mesh = crown_mesh
	crowns.instance_count = count
	for index in range(count):
		var x := rng.randf_range(min_x, max_x)
		var z := rng.randf_range(min_z, max_z)
		if absf(x) < 14.0 or (absf(x) < 25.0 and absf(z) < 9.0):
			x = max_x if x > 0.0 else min_x
		var scale := rng.randf_range(0.72, 1.35)
		var position := Vector3(x, 0.85 * scale, z)
		trunks.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ONE * scale), position))
		crowns.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ONE * scale), position + Vector3(0.0, 1.55 * scale, 0.0)))
	var trunk_instance := MultiMeshInstance3D.new()
	trunk_instance.name = "ForestTrunks"
	trunk_instance.multimesh = trunks
	trunk_instance.material_override = trunk_material
	add_child(trunk_instance)
	var crown_instance := MultiMeshInstance3D.new()
	crown_instance.name = "ForestCanopies"
	crown_instance.multimesh = crowns
	crown_instance.material_override = crown_material
	add_child(crown_instance)


func _create_fort(origin: Vector3, team_color: Color, prefix: String) -> void:
	_add_box(prefix + "_Fortress_Base", Vector3(15.0, 0.8, 13.0), origin + Vector3(0.0, 0.25, 0.0), Color(0.34, 0.32, 0.27))
	_add_box(prefix + "_Keep", Vector3(5.0, 5.5, 5.0), origin + Vector3(0.0, 3.0, 0.0), team_color)
	_add_box(prefix + "_KeepRoof", Vector3(6.0, 0.7, 6.0), origin + Vector3(0.0, 6.1, 0.0), Color(0.24, 0.22, 0.19))
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			var tower_pos := origin + Vector3(side_x * 5.8, 2.0, side_z * 4.8)
			_add_cylinder(prefix + "_Tower", 1.25, 4.0, tower_pos, team_color)
			_add_cone(prefix + "_TowerRoof", 1.5, 1.8, tower_pos + Vector3(0.0, 2.8, 0.0), Color(0.22, 0.19, 0.17))
	_add_box(prefix + "_Gate", Vector3(3.0, 2.6, 0.45), origin + Vector3(0.0, 1.7, 6.5), Color(0.20, 0.17, 0.14))
	_add_box(prefix + "_Banner", Vector3(0.18, 3.0, 0.12), origin + Vector3(0.0, 7.8, -2.5), team_color)


func _add_rock(position: Vector3, scale: float, rng: RandomNumberGenerator) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 1.3
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.35, 0.31)
	material.roughness = 1.0
	var rock := MeshInstance3D.new()
	rock.mesh = mesh
	rock.material_override = material
	rock.position = position + Vector3(0.0, 0.35 * scale, 0.0)
	rock.scale = Vector3(scale * 1.2, scale * 0.65, scale)
	rock.rotation_degrees.y = rng.randf_range(0.0, 360.0)
	add_child(rock)


func _add_box(node_name: String, box_size: Vector3, world_position: Vector3, color: Color) -> void:
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	mesh_instance.position = world_position
	add_child(mesh_instance)


func _add_cylinder(node_name: String, radius: float, height: float, world_position: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.12
	mesh.height = height
	mesh.radial_segments = 8
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = world_position
	add_child(instance)


func _add_cone(node_name: String, radius: float, height: float, world_position: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = world_position
	add_child(instance)


func _create_headquarters() -> void:
	_create_fort(Vector3(-55.0, 0.0, 0.0), Color(0.47, 0.52, 0.39), "Player")
	_create_click_area("Player_HQ_Click", Vector3(-55.0, 2.5, 0.0), Vector3(17.0, 8.0, 15.0), {"id":"player_hq","title":"مركز القيادة","description":"المقر الرئيسي لقيادة قواتك وإدارة عملياتك.","action":"hq","team":"player"})
	_create_fort(Vector3(55.0, 0.0, 0.0), Color(0.48, 0.34, 0.29), "Enemy")
	_create_click_area("Enemy_HQ_Click", Vector3(55.0, 2.5, 0.0), Vector3(17.0, 8.0, 15.0), {"id":"enemy_hq","title":"مقر العدو","description":"مركز قيادة القوات المعادية.","action":"enemy","team":"enemy"})


func _create_resource_sites() -> void:
	var mine_positions: Array[Vector3] = [
		Vector3(-34.0, 0.0, -25.0), Vector3(-34.0, 0.0, -9.0),
		Vector3(-34.0, 0.0, 9.0), Vector3(-34.0, 0.0, 25.0),
		Vector3(34.0, 0.0, -25.0), Vector3(34.0, 0.0, -9.0),
		Vector3(34.0, 0.0, 9.0), Vector3(34.0, 0.0, 25.0)
	]
	for index in range(mine_positions.size()):
		var site_color := Color(0.72, 0.61, 0.32) if index < 4 else Color(0.62, 0.43, 0.34)
		_add_box("ResourceSite_%02d" % index, Vector3(4.2, 0.55, 4.2), mine_positions[index] + Vector3(0.0, 0.25, 0.0), Color(0.29, 0.27, 0.21))
		_add_cylinder("ResourcePile_%02d" % index, 1.25, 1.1, mine_positions[index] + Vector3(0.0, 1.05, 0.0), site_color)
		var is_player_mine: bool = index < 4
		var resource_kind: String = ["wood", "metal", "fuel", "stone"][index % 4]
		_create_click_area("ResourceSite_Click_%02d" % index, mine_positions[index] + Vector3(0.0, 1.0, 0.0), Vector3(5.0, 4.0, 5.0), {"id":"mine_%02d" % index,"title":"منجم الموارد","description":"موقع استخراج موارد يمكن لقواتك تأمينه وجمع موارده.","action":"mine","resource":resource_kind,"team":"player" if is_player_mine else "enemy"})


func _create_click_area(node_name: String, world_position: Vector3, box_size: Vector3, data: Dictionary) -> void:
	var area := Area3D.new()
	area.name = node_name
	area.position = world_position
	area.collision_layer = 1
	area.collision_mask = 0
	area.set_meta("building_data", data)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	shape.shape = box
	area.add_child(shape)
	add_child(area)


func _create_player_buildings() -> void:
	_create_functional_building("Player_Barracks", Vector3(-43.0, 0.0, 22.0), Color(0.39, 0.43, 0.34), "الثكنة العسكرية", "تدريب الجنود وإعداد وحدات المشاة.", "barracks")
	_create_functional_building("Player_VehiclePlant", Vector3(-43.0, 0.0, -22.0), Color(0.40, 0.38, 0.31), "مصنع المركبات", "إنتاج المركبات القتالية والدعم الميداني.", "factory")


func _create_functional_building(node_name: String, origin: Vector3, team_color: Color, title: String, description: String, action: String) -> void:
	_add_box(node_name + "_Foundation", Vector3(9.0, 0.55, 8.0), origin + Vector3(0.0, 0.28, 0.0), Color(0.25, 0.25, 0.22))
	_add_box(node_name + "_Main", Vector3(6.0, 3.8, 5.5), origin + Vector3(0.0, 2.35, 0.0), team_color)
	_add_box(node_name + "_Roof", Vector3(6.8, 0.55, 6.3), origin + Vector3(0.0, 4.55, 0.0), Color(0.20, 0.22, 0.20))
	_add_box(node_name + "_Door", Vector3(1.5, 2.0, 0.2), origin + Vector3(0.0, 1.55, 2.85), Color(0.13, 0.14, 0.13))
	_create_click_area(node_name + "_Click", origin + Vector3(0.0, 2.0, 0.0), Vector3(10.0, 6.0, 9.0), {"id":action,"title":title,"description":description,"action":action,"team":"player"})


func _add_rock(position: Vector3, scale: float, rng: RandomNumberGenerator) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 1.3
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.35, 0.31)
	material.roughness = 1.0
	var rock := MeshInstance3D.new()
	rock.mesh = mesh
	rock.material_override = material
	rock.position = position + Vector3(0.0, 0.35 * scale, 0.0)
	rock.scale = Vector3(scale * 1.2, scale * 0.65, scale)
	rock.rotation_degrees.y = rng.randf_range(0.0, 360.0)
	add_child(rock)


func _add_box(node_name: String, box_size: Vector3, world_position: Vector3, color: Color) -> void:
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	mesh_instance.position = world_position
	add_child(mesh_instance)


func _add_cylinder(node_name: String, radius: float, height: float, world_position: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.12
	mesh.height = height
	mesh.radial_segments = 8
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = world_position
	add_child(instance)


func _add_cone(node_name: String, radius: float, height: float, world_position: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = world_position
	add_child(instance)

