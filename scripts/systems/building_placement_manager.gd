class_name BuildingPlacementManager
extends Node3D

const GRID_SIZE: float = 2.0
const SAFETY_GAP: float = 3.0
const BUILDING_SIZE := Vector2(10.0, 9.0)
const MAX_BUILDINGS_PER_TYPE: Dictionary = {"barracks": 1, "factory": 1}
const PLAYER_MIN_X: float = -78.0
const PLAYER_MAX_X: float = -10.0
const MAP_MIN_Z: float = -37.0
const MAP_MAX_Z: float = 37.0
const BUILD_SLOTS: Array[Vector2] = [
	Vector2(-71.0, -31.0),
	Vector2(-71.0, -19.0),
	Vector2(-71.0, 19.0),
	Vector2(-71.0, 31.0)
]

var camera: Camera3D
var economy: EconomyManager
var active_type := ""
var preview: MeshInstance3D
var preview_material: StandardMaterial3D
var occupied: Array[Dictionary] = []
var placed_buildings: Array[Dictionary] = []
var placed_nodes: Array[Node3D] = []
var current_position := Vector3.ZERO
var current_valid := false

func configure(camera_node: Camera3D, economy_node: EconomyManager, initial_footprints: Array[Dictionary]) -> void:
	camera = camera_node
	economy = economy_node
	for footprint in initial_footprints:
		occupied.append(footprint.duplicate(true))

func _ready() -> void:
	_create_build_slots()
	_create_preview()

func _create_build_slots() -> void:
	for index in range(BUILD_SLOTS.size()):
		var center: Vector2 = BUILD_SLOTS[index]
		var site := Node3D.new()
		site.name = "ConstructionSite_%02d" % (index + 1)
		site.position = Vector3(center.x, 0.0, center.y)
		add_child(site)

		var base := MeshInstance3D.new()
		var base_mesh := BoxMesh.new()
		base_mesh.size = Vector3(BUILDING_SIZE.x, 0.14, BUILDING_SIZE.y)
		base.mesh = base_mesh
		base.position.y = -0.19
		var base_material := StandardMaterial3D.new()
		base_material.albedo_color = Color(0.18, 0.24, 0.19, 0.82)
		base_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		base_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		base.material_override = base_material
		site.add_child(base)

		var border_material := StandardMaterial3D.new()
		border_material.albedo_color = Color(0.72, 0.62, 0.34, 0.95)
		border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_add_site_border(site, Vector3(BUILDING_SIZE.x, 0.12, 0.18), Vector3(0.0, -0.08, -BUILDING_SIZE.y * 0.5), border_material)
		_add_site_border(site, Vector3(BUILDING_SIZE.x, 0.12, 0.18), Vector3(0.0, -0.08, BUILDING_SIZE.y * 0.5), border_material)
		_add_site_border(site, Vector3(0.18, 0.12, BUILDING_SIZE.y), Vector3(-BUILDING_SIZE.x * 0.5, -0.08, 0.0), border_material)
		_add_site_border(site, Vector3(0.18, 0.12, BUILDING_SIZE.y), Vector3(BUILDING_SIZE.x * 0.5, -0.08, 0.0), border_material)

		var label := Label3D.new()
		label.text = "BUILD SITE %02d" % (index + 1)
		label.position = Vector3(0.0, 0.16, -BUILDING_SIZE.y * 0.5 - 1.0)
		label.font_size = 28
		label.modulate = Color(0.88, 0.78, 0.52, 0.9)
		label.no_depth_test = true
		site.add_child(label)

func _add_site_border(parent: Node3D, size: Vector3, local_position: Vector3, material: Material) -> void:
	var edge := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	edge.mesh = mesh
	edge.position = local_position
	edge.material_override = material
	parent.add_child(edge)

func _create_preview() -> void:
	preview = MeshInstance3D.new()
	preview.name = "BuildingPlacementPreview"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(BUILDING_SIZE.x, 3.8, BUILDING_SIZE.y)
	preview.mesh = mesh
	preview.position.y = 1.9
	preview_material = StandardMaterial3D.new()
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material.albedo_color = Color(0.2, 0.9, 0.35, 0.48)
	preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview.material_override = preview_material
	preview.visible = false
	add_child(preview)

func can_build(building_type: String) -> bool:
	var maximum: int = int(MAX_BUILDINGS_PER_TYPE.get(building_type, 1))
	var count := 0
	for record in placed_buildings:
		if str(record.get("type", "")) == building_type:
			count += 1
	return count < maximum

func building_limit_message(building_type: String) -> String:
	match building_type:
		"barracks": return "لا يمكنك بناء أكثر من ثكنة واحدة. الثكنة الحالية موجودة بالفعل."
		"factory": return "لا يمكنك بناء أكثر من مصنع مركبات واحد. المصنع الحالي موجود بالفعل."
	return "وصلت إلى الحد الأقصى لهذا النوع من المباني."

func begin_placement(building_type: String) -> bool:
	if not can_build(building_type):
		return false
	active_type = building_type
	preview.visible = true
	_set_preview_valid(false)
	return true

func cancel_placement() -> void:
	active_type = ""
	preview.visible = false
	current_valid = false

func update_preview(screen_position: Vector2) -> void:
	if active_type.is_empty():
		return
	var world_position: Variant = _screen_to_ground(screen_position)
	if not world_position is Vector3:
		return
	var slot_position: Variant = _find_nearest_build_slot(Vector2(world_position.x, world_position.z))
	if slot_position is Vector2:
		current_position = Vector3(slot_position.x, 0.0, slot_position.y)
		current_valid = _is_valid_position(slot_position, BUILDING_SIZE)
	else:
		current_position = _snap_position(world_position)
		current_valid = false
	preview.position = current_position + Vector3(0.0, 1.9, 0.0)
	_set_preview_valid(current_valid)

func _find_nearest_build_slot(world_position: Vector2) -> Variant:
	var nearest: Vector2 = Vector2.ZERO
	var nearest_distance: float = 999999.0
	for slot in BUILD_SLOTS:
		var distance: float = world_position.distance_to(slot)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = slot
	if nearest_distance <= 8.0:
		return nearest
	return null

func confirm_placement(screen_position: Vector2) -> String:
	if active_type.is_empty():
		return ""
	if not can_build(active_type):
		var limit_message := building_limit_message(active_type)
		cancel_placement()
		return limit_message
	update_preview(screen_position)
	if not current_valid:
		return "الموقع غير صالح. المس إحدى ساحات البناء الأربع المحددة."
	if not economy.can_afford_building():
		return "الموارد غير كافية. البناء يحتاج 120 خشباً و75 معدناً."
	if not economy.pay_building_cost():
		return "تعذر خصم تكلفة البناء."
	var position := Vector2(current_position.x, current_position.z)
	_create_building(active_type, position)
	cancel_placement()
	return "تم إنشاء المبنى في ساحة البناء بنجاح."

func _screen_to_ground(screen_position: Vector2) -> Variant:
	var ray_origin: Vector3 = camera.project_ray_origin(screen_position)
	var ray_direction: Vector3 = camera.project_ray_normal(screen_position)
	return Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)

func _snap_position(world_position: Vector3) -> Vector3:
	return Vector3(roundf(world_position.x / GRID_SIZE) * GRID_SIZE, 0.0, roundf(world_position.z / GRID_SIZE) * GRID_SIZE)

func _is_valid_position(center: Vector2, size: Vector2) -> bool:
	var half := size * 0.5
	if center.x - half.x < PLAYER_MIN_X or center.x + half.x > PLAYER_MAX_X:
		return false
	if center.y - half.y < MAP_MIN_Z or center.y + half.y > MAP_MAX_Z:
		return false
	for item in occupied:
		var other_center: Vector2 = item.get("center", Vector2.ZERO)
		var other_size: Vector2 = item.get("size", Vector2.ZERO)
		var min_distance_x: float = half.x + other_size.x * 0.5 + SAFETY_GAP
		var min_distance_z: float = half.y + other_size.y * 0.5 + SAFETY_GAP
		if absf(center.x - other_center.x) < min_distance_x and absf(center.y - other_center.y) < min_distance_z:
			return false
	return true

func _set_preview_valid(is_valid: bool) -> void:
	preview_material.albedo_color = Color(0.18, 0.92, 0.34, 0.48) if is_valid else Color(0.95, 0.18, 0.12, 0.48)

func _create_building(building_type: String, center: Vector2) -> void:
	var node := Node3D.new()
	node.name = "Placed_" + building_type + "_" + str(placed_buildings.size() + 1)
	node.position = Vector3(center.x, 0.0, center.y)

	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(BUILDING_SIZE.x, 0.55, BUILDING_SIZE.y)
	base.mesh = base_mesh
	base.position.y = 0.28
	var base_material := StandardMaterial3D.new()
	base_material.albedo_color = Color(0.27, 0.28, 0.24)
	base.material_override = base_material
	node.add_child(base)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(6.0, 3.8, 5.5)
	body.mesh = body_mesh
	body.position.y = 2.35
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.38, 0.45, 0.34) if building_type == "barracks" else Color(0.43, 0.39, 0.30)
	body.material_override = body_material
	node.add_child(body)

	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(6.8, 0.55, 6.3)
	roof.mesh = roof_mesh
	roof.position.y = 4.55
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.19, 0.22, 0.18)
	roof.material_override = roof_material
	node.add_child(roof)

	var area := Area3D.new()
	area.position.y = 2.0
	area.collision_layer = 1
	area.collision_mask = 0
	area.set_meta("building_data", {
		"id": building_type,
		"title": "الثكنة العسكرية" if building_type == "barracks" else "مصنع المركبات",
		"description": "منشأة جديدة قابلة للتشغيل من خلال لوحة المبنى.",
		"action": building_type,
		"team": "player"
	})
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(BUILDING_SIZE.x, 6.0, BUILDING_SIZE.y)
	collision.shape = shape
	area.add_child(collision)
	node.add_child(area)

	add_child(node)
	placed_nodes.append(node)
	var record := {"type": building_type, "center": center}
	placed_buildings.append(record)
	occupied.append({"center": center, "size": BUILDING_SIZE, "label": building_type})

func get_save_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in placed_buildings:
		result.append(record.duplicate(true))
	return result

func load_save_data(data: Array) -> void:
	for node in placed_nodes:
		node.queue_free()
	placed_nodes.clear()
	placed_buildings.clear()
	var base_count: int = 12
	while occupied.size() > base_count:
		occupied.pop_back()
	var restored_counts: Dictionary = {}
	for record in data:
		if record is Dictionary:
			var center_value: Variant = record.get("center", Vector2.ZERO)
			if center_value is Vector2:
				var kind: String = str(record.get("type", "barracks"))
				var maximum: int = int(MAX_BUILDINGS_PER_TYPE.get(kind, 1))
				var restored: int = int(restored_counts.get(kind, 0))
				if restored < maximum:
					_create_building(kind, center_value)
					restored_counts[kind] = restored + 1
