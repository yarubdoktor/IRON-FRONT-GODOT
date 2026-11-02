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
var rally_placement_mode := false

func configure(camera_node: Camera3D, hud_node: HUDController, economy_node: EconomyManager, units_node: UnitManager, building_node: BuildingPlacementManager, persistence_node: PersistenceManager) -> void:
	camera = camera_node
	hud = hud_node
	economy = economy_node
	unit_manager = units_node
	building_manager = building_node
	persistence = persistence_node

func _ready() -> void:
	hud.select_all_requested.connect(_on_select_all)
	hud.clear_selection_requested.connect(_on_clear_selection)
	hud.building_action_requested.connect(_on_building_action)
	hud.placement_requested.connect(_on_placement_requested)
	hud.cancel_placement_requested.connect(_on_cancel_placement)
	hud.rotate_placement_requested.connect(_on_rotate_placement)
	hud.save_requested.connect(persistence.save_game)
	hud.load_requested.connect(persistence.load_game)
	hud.rally_point_requested.connect(_on_rally_point_requested)
	hud.cancel_rally_requested.connect(_on_cancel_rally_requested)
	economy.resources_changed.connect(hud.update_resources)
	hud.update_resources(economy.resources)
	_update_selection_ui()

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
	if rally_placement_mode:
		var rally_origin: Vector3 = camera.project_ray_origin(screen_position)
		var rally_direction: Vector3 = camera.project_ray_normal(screen_position)
		var rally_hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(rally_origin, rally_direction)
		if rally_hit is Vector3:
			unit_manager.set_rally_point(rally_hit)
			rally_placement_mode = false
			hud.set_rally_mode(false, true)
			hud.show_message("تم تحديد نقطة التجمع. التعزيزات الجديدة ستتجه إليها تلقائياً.")
		else:
			hud.show_message("تعذر تحديد الموقع. اختر نقطة واضحة على أرض المعركة.")
		return
	if not building_manager.active_type.is_empty():
		var placement_result: String = building_manager.confirm_placement(screen_position)
		hud.show_message(placement_result)
		if building_manager.active_type.is_empty():
			hud.set_placement_mode(false)
		return

	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 250.0)
	query.collision_mask = 3
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var collider: Object = result.get("collider")
		if collider is Area3D:
			if collider.has_meta("is_player_unit"):
				var parent_unit := collider.get_parent() as Node3D
				if parent_unit != null:
					unit_manager.select_unit(parent_unit)
					_update_selection_ui()
					hud.show_message("تم تحديد الوحدة. المساحة الفارغة تصدر أمر الحركة.")
					return
			if collider.has_meta("building_data"):
				var building_data: Dictionary = collider.get_meta("building_data")
				if str(building_data.get("action", "")) == "hq" and str(building_data.get("team", "")) == "player":
					hud.set_building_availability(building_manager.can_build("barracks"), building_manager.can_build("factory"))
				hud.show_building(building_data)
				return

	if not unit_manager.selected_units.is_empty():
		var plane := Plane(Vector3.UP, 0.0)
		var hit: Variant = plane.intersects_ray(origin, direction)
		if hit is Vector3:
			unit_manager.move_selected_to(hit)
			hud.show_message("تم إصدار أمر الحركة للقوات المحددة.")

func _tap_hits_ui(point: Vector2) -> bool:
	var panel_rect := hud.building_panel.get_global_rect()
	if hud.building_panel.visible and panel_rect.has_point(point):
		return true
	return point.y < 66.0 and point.x > 0.0

func _on_select_all() -> void:
	var count: int = unit_manager.toggle_select_all()
	if count == 0:
		hud.show_message("تم إلغاء تحديد جميع القوات.")
	else:
		hud.show_message("تم تحديد %d وحدات. اضغط على الزر مرة أخرى لإلغاء التحديد." % count)
	_update_selection_ui()

func _on_clear_selection() -> void:
	unit_manager.clear_selection()
	_update_selection_ui()
	hud.show_message("تم إلغاء التحديد.")

func _update_selection_ui() -> void:
	hud.set_selection_state(unit_manager.selected_units.size(), unit_manager.units.size(), unit_manager.selected_all)

func _on_building_action(data: Dictionary) -> void:
	var result: String = economy.perform_building_action(data, unit_manager)
	hud.show_message(result)
	hud.building_panel.visible = false

func _on_placement_requested(building_type: String) -> void:
	if not economy.can_afford_building():
		hud.show_message("تحتاج إلى 120 خشباً و75 معدناً لبدء البناء.")
		return
	if not building_manager.begin_placement(building_type):
		hud.show_message(building_manager.building_limit_message(building_type))
		return
	hud.building_panel.visible = false
	hud.set_placement_mode(true)
	hud.show_message("اختر إحدى ساحات البناء المحددة. الأخضر صالح والأحمر غير صالح.")

func _on_rotate_placement() -> void:
	building_manager.rotate_placement()
	hud.show_message("تم تدوير المبنى 90 درجة. تحقق من صلاحية الموقع قبل التثبيت.")

func _on_cancel_placement() -> void:
	building_manager.cancel_placement()
	hud.set_placement_mode(false)
	hud.show_message("تم إلغاء وضع البناء.")

func _on_rally_point_requested() -> void:
	building_manager.cancel_placement()
	hud.set_placement_mode(false)
	rally_placement_mode = true
	hud.set_rally_mode(true, unit_manager.rally_active)
	hud.show_message("المس أرض المعركة لتحديد نقطة تجمع القوات.")

func _on_cancel_rally_requested() -> void:
	if rally_placement_mode:
		rally_placement_mode = false
		hud.set_rally_mode(false, unit_manager.rally_active)
		hud.show_message("تم إلغاء تحديد موقع نقطة التجمع.")
	elif unit_manager.rally_active:
		unit_manager.cancel_rally_point()
		hud.set_rally_mode(false, false)
		hud.show_message("تم إلغاء نقطة التجمع. القوات الموجودة لن تتحرك.")
