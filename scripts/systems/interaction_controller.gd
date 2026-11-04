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

# Screen touches are tracked independently by finger index. A gesture that
# involved multiple fingers cannot become a world tap when one finger lifts.
var touch_points: Dictionary = {}
var touch_starts: Dictionary = {}
var active_touch_index: int = -1
var multi_touch_gesture: bool = false
var mouse_pointer_start := Vector2.ZERO
var mouse_pointer_is_down: bool = false

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
	hud.building_upgrade_requested.connect(_on_building_upgrade_requested)
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
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pointer_start = event.position
			mouse_pointer_is_down = true
			_update_build_preview(event.position)
		elif mouse_pointer_is_down:
			if mouse_pointer_start.distance_to(event.position) < 8.0:
				_handle_tap(event.position)
			mouse_pointer_is_down = false
	elif event is InputEventMouseMotion:
		_update_build_preview(event.position)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var touch_index: int = event.index
	if event.pressed:
		if touch_points.is_empty():
			multi_touch_gesture = false
			active_touch_index = touch_index
			pointer_start = event.position
			pointer_is_down = true
		else:
			multi_touch_gesture = true
			pointer_is_down = false
		touch_points[touch_index] = event.position
		touch_starts[touch_index] = event.position
		_update_build_preview(event.position)
		return

	if _is_single_touch_tap(touch_index, event.position):
		_handle_tap(event.position)

	touch_points.erase(touch_index)
	touch_starts.erase(touch_index)
	if touch_points.is_empty():
		active_touch_index = -1
		pointer_is_down = false
		multi_touch_gesture = false
	elif touch_points.size() == 1:
		# Keep the gesture marked as multi-touch until every finger is lifted.
		# This prevents the remaining finger's release from firing a tap.
		pointer_is_down = false

func _is_single_touch_tap(touch_index: int, screen_position: Vector2) -> bool:
	if touch_points.size() != 1 or not touch_points.has(touch_index) or not touch_starts.has(touch_index) or multi_touch_gesture:
		return false
	var start_position: Vector2 = touch_starts[touch_index]
	return start_position.distance_to(screen_position) < 14.0

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	var touch_index: int = event.index
	if not touch_points.has(touch_index):
		return
	touch_points[touch_index] = event.position
	if touch_points.size() == 1 and not multi_touch_gesture and touch_index == active_touch_index:
		_update_build_preview(event.position)

func _update_build_preview(screen_position: Vector2) -> void:
	if building_manager != null:
		building_manager.update_preview(screen_position)

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
				var action: String = str(building_data.get("action",""))
				if action == "hq" and str(building_data.get("team","")) == "player":
					hud.set_building_availability(building_manager.get_build_availability())
					hud.show_building(building_data)
					return
				if action != "mine" and str(building_data.get("team","")) == "player":
					var building_id: String = str(building_data.get("id",""))
					var building_type: String = str(building_data.get("building_type",action))
					var upgrade_cost: Dictionary = economy.get_upgrade_cost(building_type,building_id)
					var can_upgrade: bool = economy.can_upgrade_building(building_type,building_id)
					var benefit: String = economy.get_upgrade_benefit(building_type,int(building_data.get("level",1))+1)
					hud.show_building(building_data,upgrade_cost,can_upgrade,benefit)
					return
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

func _on_building_upgrade_requested(data: Dictionary) -> void:
	var building_id: String = str(data.get("id",""))
	var building_type: String = str(data.get("building_type",data.get("action","")))
	if not economy.upgrade_building(building_type,building_id):
		hud.show_message("تعذر الترقية: تحقق من الموارد أو مستوى المبنى.")
		return
	var new_level: int = economy.get_building_level(building_id)
	building_manager.update_building_level(building_id,new_level)
	var refreshed: Dictionary = data.duplicate(true)
	refreshed["level"] = new_level
	var next_cost: Dictionary = economy.get_upgrade_cost(building_type,building_id)
	var can_upgrade: bool = economy.can_upgrade_building(building_type,building_id)
	var benefit: String = economy.get_upgrade_benefit(building_type,new_level+1)
	hud.show_building(refreshed,next_cost,can_upgrade,benefit)
	hud.show_message("تمت ترقية %s إلى المستوى %d." % [str(data.get("title","المبنى")),new_level])

func _on_placement_requested(building_type: String) -> void:
	if not economy.can_afford_building(building_type):
		hud.show_message("الموارد غير كافية لبناء هذه المنشأة.")
		return
	if not building_manager.begin_placement(building_type):
		hud.show_message(building_manager.building_limit_message(building_type))
		return
	hud.building_panel.visible = false
	hud.set_placement_mode(true)
	hud.show_message("اختر إحدى ساحات البناء المتاحة. الحواجز الدفاعية تستخدم مواقع محيط القاعدة.")

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
