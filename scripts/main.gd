extends Node3D

const MAP_SIZE := Vector2(160.0, 80.0)
const BRIDGE_Z_POSITIONS: Array[float] = [-30.0, -15.0, 0.0, 15.0, 30.0]
const CAMERA_MIN_HEIGHT := 28.0
const CAMERA_MAX_HEIGHT := 92.0

var camera: Camera3D
var camera_dragging := false
var last_pointer := Vector2.ZERO
var touch_points: Dictionary = {}
var status_label: Label
var selected_mode := "SELECT"

func _ready() -> void:
	_create_camera()
	_create_lighting()
	_create_environment()
	_create_ground()
	_create_river_and_bridges()
	_create_terrain_details()
	_create_headquarters()
	_create_resource_sites()
	_create_hud()


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "BattleCamera"
	camera.position = Vector3(0.0, 62.0, 68.0)
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
		for index in range(8):
			var x := side * (17.0 + float(index) * 4.0)
			_add_box("Road_%s_%02d" % [str(side), index], Vector3(2.4, 0.035, 7.0), Vector3(x, -0.17, 0.0), Color(0.39, 0.35, 0.27))
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


func _create_headquarters() -> void:
	_create_fort(Vector3(-55.0, 0.0, 0.0), Color(0.47, 0.52, 0.39), "Player")
	_create_fort(Vector3(55.0, 0.0, 0.0), Color(0.48, 0.34, 0.29), "Enemy")


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


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BattleHUD"
	add_child(layer)
	var top := ColorRect.new()
	top.color = Color(0.055, 0.075, 0.085, 0.92)
	top.anchor_right = 1.0
	top.offset_bottom = 62.0
	layer.add_child(top)
	var title := Label.new()
	title.text = "IRON-FRONT   |   FIELD COMMAND"
	title.position = Vector2(24.0, 15.0)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.91, 0.86, 0.70))
	top.add_child(title)
	status_label = Label.new()
	status_label.text = "TACTICAL VIEW  •  READY"
	status_label.anchor_left = 1.0
	status_label.anchor_right = 1.0
	status_label.offset_left = -310.0
	status_label.offset_right = -22.0
	status_label.offset_top = 19.0
	status_label.add_theme_color_override("font_color", Color(0.78, 0.85, 0.78))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(status_label)
	var bottom := ColorRect.new()
	bottom.color = Color(0.055, 0.075, 0.085, 0.94)
	bottom.anchor_top = 1.0
	bottom.anchor_right = 1.0
	bottom.offset_top = -76.0
	layer.add_child(bottom)
	var command := Label.new()
	command.text = "SELECT     BUILD     UNITS     RESEARCH     •     DRAG TO MOVE  /  PINCH TO ZOOM"
	command.position = Vector2(24.0, -51.0)
	command.anchor_top = 1.0
	command.anchor_bottom = 1.0
	command.add_theme_font_size_override("font_size", 17)
	command.add_theme_color_override("font_color", Color(0.86, 0.84, 0.76))
	bottom.add_child(command)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			last_pointer = event.position
		else:
			touch_points.erase(event.index)
	elif event is InputEventScreenDrag:
		if touch_points.size() >= 2:
			var old_distance := _touch_distance()
			touch_points[event.index] = event.position
			var new_distance := _touch_distance()
			if old_distance > 1.0 and new_distance > 1.0:
				_zoom_camera((old_distance - new_distance) * 0.12)
		else:
			touch_points[event.index] = event.position
			_pan_camera(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(-4.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(4.0)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			camera_dragging = event.pressed
			last_pointer = event.position
	elif event is InputEventMouseMotion and camera_dragging:
		_pan_camera(event.relative)


func _touch_distance() -> float:
	if touch_points.size() < 2:
		return 0.0
	var points: Array = touch_points.values()
	return points[0].distance_to(points[1])


func _pan_camera(relative: Vector2) -> void:
	var pan_scale := camera.position.y * 0.0015
	camera.position.x -= relative.x * pan_scale
	camera.position.z -= relative.y * pan_scale
	camera.position.x = clampf(camera.position.x, -65.0, 65.0)
	camera.position.z = clampf(camera.position.z, 20.0, 100.0)


func _zoom_camera(amount: float) -> void:
	camera.position.y = clampf(camera.position.y + amount, CAMERA_MIN_HEIGHT, CAMERA_MAX_HEIGHT)
	camera.position.z = clampf(camera.position.z + amount * 0.7, 28.0, 110.0)


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
