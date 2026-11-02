class_name InteractionController
extends Node

var camera: Camera3D
var hud: HUDController
var economy: EconomyManager
var unit_manager: UnitManager
var building_manager: BuildingPlacementManager
var persistence: PersistenceManager
var pointer_start := Vector2.ZERO
var pointer_is_down := false

func configure(camera_node: Camera3D, hud_node: HUDController, economy_node: EconomyManager, units_node: UnitManager, building_node: BuildingPlacementManager, persistence_node: PersistenceManager) -> void:
	camera = camera_node
	hud = hud_node
	economy = economy_node
	unit_manager = units_node
	building_manager = building_node
	persistence = persistence_node

func _ready() -> void:
	hud.select_all_requested.connect(_on_select_all)
	hud.building_action_requested.connect(_on_building_action)
	hud.placement_requested.connect(_on_placement_requested)
	hud.save_requested.connect(persistence.save_game)
	hud.load_requested.connect(persistence.load_game)
	economy.resources_changed.connect(hud.update_resources)
	hud.update_resources(economy.resources)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			pointer_start = event.position
			pointer_is_down = true
			building_manager.update_preview(event.position)
		elif pointer_is_down:
			if pointer_start.distance_to(event.position) < 14.0:
				_handle_tap(event.position)
			pointer_is_down = false
	elif event is InputEventScreenDrag:
		building_manager.update_preview(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_start = event.position
			pointer_is_down = true
			building_manager.update_preview(event.position)
		elif pointer_is_down:
			if pointer_start.distance_to(event.position) < 8.0:
				_handle_tap(event.position)
			pointer_is_down = false
	elif event is InputEventMouseMotion:
		building_manager.update_preview(event.position)

func _handle_tap(screen_position: Vector2) -> void:
	if _tap_hits_ui(screen_position):
		return
	if not building_manager.active_type.is_empty():
		hud.show_message(building_manager.confirm_placement(screen_position))
		return
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin,origin + direction * 250.0)
	query.collision_mask = 1
	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var collider: Object = result.get("collider")
		if collider is Area3D and collider.has_meta("building_data"):
			hud.show_building(collider.get_meta("building_data"))
			return
	if unit_manager.selected_all:
		var plane := Plane(Vector3.UP,0.0)
		var hit: Variant = plane.intersects_ray(origin,direction)
		if hit is Vector3:
			unit_manager.move_selected_to(hit)
			hud.show_message("تم إصدار أمر الحركة لجميع القوات المحددة.")

func _tap_hits_ui(point: Vector2) -> bool:
	var panel_rect := hud.building_panel.get_global_rect()
	if hud.building_panel.visible and panel_rect.has_point(point):
		return true
	return point.y < 66.0 and point.x > 0.0

func _on_select_all() -> void:
	var count: int = unit_manager.select_all()
	hud.show_message("تم تحديد %d وحدات. اضغط على الأرض لإصدار أمر الحركة." % count)

func _on_building_action(data: Dictionary) -> void:
	var result: String = economy.perform_building_action(data,unit_manager)
	hud.show_message(result)
	hud.building_panel.visible = false

func _on_placement_requested(building_type: String) -> void:
	if not economy.can_afford_building():
		hud.show_message("تحتاج إلى 120 خشباً و75 معدناً لبدء البناء.")
		return
	building_manager.begin_placement(building_type)
	hud.building_panel.visible = false
	hud.show_message("حرّك المؤشر واختر موقعاً صالحاً. الأخضر صالح والأحمر مرفوض.")
