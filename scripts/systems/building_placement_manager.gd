class_name BuildingPlacementManager
extends Node3D

const SAFETY_GAP: float = 0.12
const PLAYER_MIN_X: float = -78.0
const PLAYER_MAX_X: float = -10.0
const MAP_MIN_Z: float = -37.0
const MAP_MAX_Z: float = 37.0

# The original 0.16 construction grid, translated from HQ (-12, 4)
# to the current native battlefield HQ (-55, 0).
const BUILD_SLOTS: Array[Vector2] = [
	Vector2(-61.0, -4.0), Vector2(-57.0, -4.0), Vector2(-53.0, -4.0), Vector2(-49.0, -4.0),
	Vector2(-61.0, 1.0), Vector2(-61.0, 4.5), Vector2(-57.0, 4.5), Vector2(-53.0, 4.5),
	Vector2(-49.0, 4.5), Vector2(-49.0, 0.5), Vector2(-64.0, -4.0), Vector2(-64.0, 0.0),
	Vector2(-64.0, 4.0), Vector2(-45.0, -4.0), Vector2(-45.0, 4.0)
]
const WALL_SLOTS: Array[Vector2] = [
	Vector2(-65.0, -7.4), Vector2(-62.0, -7.4), Vector2(-59.0, -7.4), Vector2(-56.0, -7.4),
	Vector2(-53.0, -7.4), Vector2(-50.0, -7.4), Vector2(-47.0, -7.4),
	Vector2(-65.0, 7.6), Vector2(-62.0, 7.6), Vector2(-59.0, 7.6), Vector2(-56.0, 7.6),
	Vector2(-53.0, 7.6), Vector2(-50.0, 7.6), Vector2(-47.0, 7.6),
	Vector2(-67.0, -5.0), Vector2(-67.0, -1.5), Vector2(-67.0, 1.0), Vector2(-67.0, 3.5),
	Vector2(-67.0, 6.0), Vector2(-44.0, -5.0), Vector2(-44.0, 6.0)
]
const BUILDING_CATALOG: Dictionary = {
	"barracks": {"title":"الثكنة العسكرية","description":"تدريب المشاة والقناصة والمهندسين.","size":Vector2(3.7,3.2),"model":"res://assets/3d/base/squad-tent.glb","fit":Vector3(3.7,2.2,3.2)},
	"power": {"title":"محطة الطاقة","description":"توليد الطاقة اللازمة لتشغيل منشآت القاعدة.","size":Vector2(2.8,2.5),"model":"res://assets/3d/base/generator-trailer.glb","fit":Vector3(2.8,2.0,2.5)},
	"refinery": {"title":"مصفاة الوقود","description":"معالجة الوقود وتجهيز احتياطي الإمداد.","size":Vector2(4.2,3.8),"model":"res://assets/3d/base/fuel-dump-berm.glb","fit":Vector3(4.2,2.4,3.8)},
	"factory": {"title":"مصنع الدبابات","description":"منشأة إنتاج الدبابات القتالية الثقيلة.","size":Vector2(4.0,4.0),"model":"res://assets/3d/base/camo-net-frame.glb","fit":Vector3(4.0,2.7,4.0),"decoration":"res://assets/3d/vehicles/main-battle-tank.glb"},
	"research": {"title":"مركز الأبحاث","description":"تطوير التقنيات العسكرية وتحسين كفاءة القوات.","size":Vector2(3.6,3.2),"model":"res://assets/3d/base/radar-trailer.glb","fit":Vector3(3.6,2.7,3.2)},
	"watchtower": {"title":"برج المراقبة","description":"نقطة مراقبة مرتفعة لرصد محيط القاعدة.","size":Vector2(2.0,2.0),"model":"res://assets/3d/base/guard-tower.glb","fit":Vector3(2.0,4.2,2.0)},
	"hospital": {"title":"المستشفى الميداني","description":"منشأة طبية لدعم القوات المتضررة.","size":Vector2(4.0,3.8),"model":"res://assets/3d/base/field-hospital-tent.glb","fit":Vector3(4.0,2.5,3.8)},
	"ammo": {"title":"مستودع الذخيرة","description":"تخزين وتجهيز ذخائر العمليات العسكرية.","size":Vector2(3.3,2.8),"model":"res://assets/3d/base/storage-container.glb","fit":Vector3(3.3,2.5,2.8)},
	"vehicle_factory": {"title":"مصنع المركبات","description":"إنتاج مركبات الاستطلاع والدعم والمدفعية المتحركة.","size":Vector2(3.6,3.2),"model":"res://assets/3d/base/field-office.glb","fit":Vector3(3.6,2.6,3.2),"decoration":"res://assets/3d/vehicles/armoured-car.glb"},
	"airfield": {"title":"المطار العسكري","description":"مهبط جوي وتجهيز منشآت الطيران والاستطلاع.","size":Vector2(4.5,4.5),"model":"res://assets/3d/base/helipad-marker.glb","fit":Vector3(4.5,0.45,4.5)},
	"missile": {"title":"دفاع الصواريخ","description":"منظومة دفاع جوي لحماية المجال المحيط بالقاعدة.","size":Vector2(3.9,3.0),"model":"res://assets/3d/base/mobile-rocket-launcher.glb","fit":Vector3(3.9,2.2,3.0)},
	"wall": {"title":"حاجز دفاعي","description":"قطعة تحصين قابلة للتدمير تسد ممرات الاقتحام.","size":Vector2(3.0,0.9),"model":"res://assets/3d/base/sandbag-wall-straight.glb","fit":Vector3(3.0,1.35,0.9)},
	"command": {"title":"مركز القيادة المتقدم","description":"مركز دعم يوسّع قدرات إدارة القاعدة.","size":Vector2(3.8,3.2),"model":"res://assets/3d/base/command-vehicle.glb","fit":Vector3(3.8,2.8,3.2)}
}
const MAX_BUILDINGS_PER_TYPE: Dictionary = {"watchtower":4,"wall":10}

var camera: Camera3D
var economy: EconomyManager
var active_type := ""
var preview: MeshInstance3D
var preview_material: StandardMaterial3D
var occupied: Array[Dictionary] = []
var initial_occupied_count: int = 0
var placed_buildings: Array[Dictionary] = []
var placed_nodes: Array[Node3D] = []
var current_position := Vector3.ZERO
var current_valid := false
var current_rotation_degrees := 0.0

func configure(camera_node: Camera3D, economy_node: EconomyManager, initial_footprints: Array[Dictionary]) -> void:
	camera = camera_node
	economy = economy_node
	for footprint in initial_footprints:
		occupied.append(footprint.duplicate(true))
	initial_occupied_count = occupied.size()

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
		var mesh := BoxMesh.new()
		mesh.size = Vector3(3.8, 0.12, 3.2)
		base.mesh = mesh
		base.position.y = 0.70
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.24, 0.29, 0.22, 0.78)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		base.material_override = material
		site.add_child(base)
		var edge_material := StandardMaterial3D.new()
		edge_material.albedo_color = Color(0.72, 0.62, 0.34, 0.95)
		edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_add_site_border(site, Vector3(3.8,0.1,0.12), Vector3(0.0,0.77,-1.6), edge_material)
		_add_site_border(site, Vector3(3.8,0.1,0.12), Vector3(0.0,0.77,1.6), edge_material)
		_add_site_border(site, Vector3(0.12,0.1,3.2), Vector3(-1.9,0.77,0.0), edge_material)
		_add_site_border(site, Vector3(0.12,0.1,3.2), Vector3(1.9,0.77,0.0), edge_material)
		var label := Label3D.new()
		label.text = "موقع بناء %02d" % (index + 1)
		label.position = Vector3(0.0,0.95,-2.0)
		label.font_size = 22
		label.modulate = Color(0.88,0.78,0.52,0.9)
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
	mesh.size = Vector3(3.8, 2.5, 3.2)
	preview.mesh = mesh
	preview.position.y = 1.25
	preview_material = StandardMaterial3D.new()
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material.albedo_color = Color(0.2,0.9,0.35,0.48)
	preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview.material_override = preview_material
	preview.visible = false
	add_child(preview)

func get_building_types() -> Array[String]:
	var result: Array[String] = []
	for key in BUILDING_CATALOG.keys():
		result.append(str(key))
	return result

func get_build_availability() -> Dictionary:
	var result: Dictionary = {}
	for kind in BUILDING_CATALOG.keys():
		result[str(kind)] = can_build(str(kind))
	return result

func can_build(building_type: String) -> bool:
	if not BUILDING_CATALOG.has(building_type):
		return false
	var maximum: int = int(MAX_BUILDINGS_PER_TYPE.get(building_type, 1))
	var count := 0
	for record in placed_buildings:
		if str(record.get("type","")) == building_type:
			count += 1
	if count >= maximum:
		return false
	if building_type == "wall":
		return _first_free_slot(WALL_SLOTS) != null
	return _first_free_slot(BUILD_SLOTS) != null

func building_limit_message(building_type: String) -> String:
	if building_type == "watchtower":
		return "تم بناء الأبراج الأربعة المسموح بها."
	if building_type == "wall":
		return "وصلت إلى الحد الأقصى للتحصينات الدفاعية."
	var spec: Dictionary = BUILDING_CATALOG.get(building_type,{})
	return "تم بناء %s بالفعل أو لا توجد ساحة فارغة." % str(spec.get("title","هذا المبنى"))

func begin_placement(building_type: String) -> bool:
	if not can_build(building_type):
		return false
	active_type = building_type
	current_rotation_degrees = 0.0
	preview.rotation_degrees.y = 0.0
	var spec: Dictionary = BUILDING_CATALOG[building_type]
	var footprint: Vector2 = spec.get("size",Vector2(3.8,3.2))
	preview.mesh = BoxMesh.new()
	(preview.mesh as BoxMesh).size = Vector3(footprint.x,2.5,footprint.y)
	preview.position.y = 1.25
	preview.visible = true
	_set_preview_valid(false)
	return true

func rotate_placement() -> void:
	if active_type.is_empty() or active_type == "wall":
		return
	current_rotation_degrees = fposmod(current_rotation_degrees + 90.0,360.0)
	preview.rotation_degrees.y = current_rotation_degrees
	var spec: Dictionary = BUILDING_CATALOG[active_type]
	var size: Vector2 = spec.get("size",Vector2(3.8,3.2))
	if int(current_rotation_degrees) % 180 != 0:
		size = Vector2(size.y,size.x)
	current_valid = _is_slot_available(Vector2(current_position.x,current_position.z),size)
	_set_preview_valid(current_valid)

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
	var pool: Array[Vector2] = WALL_SLOTS if active_type == "wall" else BUILD_SLOTS
	var slot_position: Variant = _find_nearest_build_slot(Vector2(world_position.x,world_position.z),pool)
	if slot_position is Vector2:
		current_position = Vector3(slot_position.x,0.0,slot_position.y)
		var spec: Dictionary = BUILDING_CATALOG[active_type]
		var size: Vector2 = spec.get("size",Vector2(3.8,3.2))
		if int(current_rotation_degrees) % 180 != 0:
			size = Vector2(size.y,size.x)
		current_valid = _is_slot_available(slot_position,size)
	else:
		current_position = Vector3(world_position.x,0.0,world_position.z)
		current_valid = false
	preview.position = current_position + Vector3(0.0,1.97,0.0)
	_set_preview_valid(current_valid)

func _find_nearest_build_slot(world_position: Vector2,pool: Array[Vector2]) -> Variant:
	var nearest: Vector2 = Vector2.ZERO
	var nearest_distance: float = 999999.0
	for slot in pool:
		var distance: float = world_position.distance_to(slot)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = slot
	return nearest if nearest_distance <= 5.5 else null

func _first_free_slot(pool: Array[Vector2]) -> Variant:
	for slot in pool:
		var used := false
		for record in placed_buildings:
			if Vector2(record.get("center",Vector2.ZERO)).distance_to(slot) < 0.25:
				used = true
				break
		if not used:
			return slot
	return null

func _is_slot_available(center: Vector2,size: Vector2) -> bool:
	if center.x-size.x*0.5 < PLAYER_MIN_X or center.x+size.x*0.5 > PLAYER_MAX_X:
		return false
	if center.y-size.y*0.5 < MAP_MIN_Z or center.y+size.y*0.5 > MAP_MAX_Z:
		return false
	for record in placed_buildings:
		var other_center: Vector2 = record.get("center",Vector2.ZERO)
		if other_center.distance_to(center) < 0.25:
			return false
	return true

func confirm_placement(screen_position: Vector2) -> String:
	if active_type.is_empty():
		return ""
	if not can_build(active_type):
		var message := building_limit_message(active_type)
		cancel_placement()
		return message
	update_preview(screen_position)
	if not current_valid:
		return "الموقع غير صالح. اختر إحدى ساحات البناء الخالية."
	if not economy.can_afford_building(active_type):
		return "الموارد غير كافية لبناء هذه المنشأة."
	if not economy.pay_building_cost(active_type):
		return "تعذر خصم تكلفة البناء."
	var position := Vector2(current_position.x,current_position.z)
	_create_building(active_type,position,current_rotation_degrees)
	var title: String = str(BUILDING_CATALOG[active_type].get("title",active_type))
	cancel_placement()
	return "بدأ إنشاء %s بنجاح." % title

func _screen_to_ground(screen_position: Vector2) -> Variant:
	var ray_origin: Vector3 = camera.project_ray_origin(screen_position)
	var ray_direction: Vector3 = camera.project_ray_normal(screen_position)
	return Plane(Vector3.UP,0.0).intersects_ray(ray_origin,ray_direction)

func _set_preview_valid(is_valid: bool) -> void:
	preview_material.albedo_color = Color(0.18,0.92,0.34,0.48) if is_valid else Color(0.95,0.18,0.12,0.48)

func _create_building(building_type: String,center: Vector2,rotation_degrees: float = 0.0) -> void:
	var spec: Dictionary = BUILDING_CATALOG.get(building_type,{})
	var node := Node3D.new()
	node.name = "Placed_" + building_type + "_" + str(placed_buildings.size()+1)
	node.position = Vector3(center.x,0.72,center.y)
	node.rotation_degrees.y = rotation_degrees
	var is_wall: bool = building_type == "wall"
	var pad := MeshInstance3D.new()
	var pad_mesh := BoxMesh.new()
	var size: Vector2 = spec.get("size",Vector2(3.8,3.2))
	pad_mesh.size = Vector3(size.x,0.18,size.y)
	pad.mesh = pad_mesh
	pad.position.y = 0.09
	var pad_material := StandardMaterial3D.new()
	pad_material.albedo_color = Color(0.27,0.29,0.24) if not is_wall else Color(0.25,0.24,0.20)
	pad.material_override = pad_material
	node.add_child(pad)
	var model_path: String = str(spec.get("model",""))
	_add_fitted_model(node,model_path,spec.get("fit",Vector3(3.5,2.5,3.0)))
	var decoration_path: String = str(spec.get("decoration",""))
	if not decoration_path.is_empty():
		var decoration := Node3D.new()
		decoration.position = Vector3(1.25,0.0,1.2)
		node.add_child(decoration)
		_add_fitted_model(decoration,decoration_path,Vector3(1.8,1.5,2.2))
	var area := Area3D.new()
	area.name = "BuildingClickArea"
	area.position.y = 1.4
	area.collision_layer = 1
	area.collision_mask = 0
	area.set_meta("building_data",{"id":building_type,"title":str(spec.get("title","مبنى")),"description":str(spec.get("description","")),"action":building_type,"team":"player"})
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(size.x,2.0),4.5,maxf(size.y,2.0))
	collision.shape = shape
	area.add_child(collision)
	node.add_child(area)
	add_child(node)
	placed_nodes.append(node)
	placed_buildings.append({"type":building_type,"center":center,"rotation":rotation_degrees})
	occupied.append({"center":center,"size":size,"label":building_type})

func _add_fitted_model(parent: Node3D,resource_path: String,max_size: Vector3) -> void:
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
		return
	var packed: PackedScene = load(resource_path) as PackedScene
	if packed == null:
		return
	var instance: Node3D = packed.instantiate() as Node3D
	if instance == null:
		return
	parent.add_child(instance)
	var combined := AABB()
	var has_bounds := false
	var visuals: Array[Node] = []
	_collect_visuals(instance,visuals)
	for visual_node in visuals:
		var visual := visual_node as VisualInstance3D
		if visual == null:
			continue
		var relative: Transform3D = instance.global_transform.affine_inverse() * visual.global_transform
		var transformed: AABB = relative * visual.get_aabb()
		if not has_bounds:
			combined = transformed
			has_bounds = true
		else:
			combined = combined.merge(transformed)
	if not has_bounds:
		return
	var dimensions: Vector3 = combined.size
	var fit: float = minf(max_size.x/maxf(dimensions.x,0.001),minf(max_size.y/maxf(dimensions.y,0.001),max_size.z/maxf(dimensions.z,0.001)))
	instance.scale = Vector3.ONE * fit
	instance.position = Vector3(-combined.get_center().x*fit,-combined.position.y*fit,-combined.get_center().z*fit)

func _collect_visuals(root: Node,output: Array[Node]) -> void:
	for child in root.get_children():
		if child is VisualInstance3D:
			output.append(child)
		_collect_visuals(child,output)

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
	while occupied.size() > initial_occupied_count:
		occupied.pop_back()
	var restored_counts: Dictionary = {}
	for record in data:
		if not record is Dictionary:
			continue
		var center_value: Variant = record.get("center",Vector2.ZERO)
		if not center_value is Vector2:
			continue
		var kind: String = str(record.get("type",""))
		var maximum: int = int(MAX_BUILDINGS_PER_TYPE.get(kind,1))
		var restored: int = int(restored_counts.get(kind,0))
		if BUILDING_CATALOG.has(kind) and restored < maximum:
			_create_building(kind,center_value,float(record.get("rotation",0.0)))
			restored_counts[kind] = restored + 1
