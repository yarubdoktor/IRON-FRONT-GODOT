class_name HUDController
extends CanvasLayer

signal select_all_requested
signal clear_selection_requested
signal building_action_requested(data: Dictionary)
signal building_upgrade_requested(data: Dictionary)
signal placement_requested(building_type: String)
signal cancel_placement_requested
signal rotate_placement_requested
signal save_requested
signal load_requested
signal rally_point_requested
signal cancel_rally_requested

const BUILD_MENU: Array[Dictionary] = [
	{"type":"barracks","title":"الثكنة العسكرية"},
	{"type":"power","title":"محطة الطاقة"},
	{"type":"refinery","title":"مصفاة الوقود"},
	{"type":"factory","title":"مصنع الدبابات"},
	{"type":"research","title":"مركز الأبحاث"},
	{"type":"watchtower","title":"أبراج المراقبة (4)"},
	{"type":"hospital","title":"المستشفى الميداني"},
	{"type":"ammo","title":"مستودع الذخيرة"},
	{"type":"vehicle_factory","title":"مصنع المركبات"},
	{"type":"airfield","title":"المطار العسكري"},
	{"type":"missile","title":"دفاع الصواريخ"},
	{"type":"wall","title":"الحواجز الدفاعية (10)"},
	{"type":"command","title":"مركز القيادة المتقدم"}
]

var building_data: Dictionary = {}
var action_button: Button
var upgrade_button: Button
var building_panel: PanelContainer
var message_label: Label
var resources_label: Label
var build_barracks_button: Button
var build_factory_button: Button
var build_buttons: Dictionary = {}
var select_button: Button
var clear_selection_button: Button
var cancel_build_button: Button
var rotate_build_button: Button
var rally_button: Button
var cancel_rally_button: Button

func _ready() -> void:
	_build_interface()

func _build_interface() -> void:
	var top := ColorRect.new()
	top.color = Color(0.055,0.075,0.085,0.96)
	top.anchor_right = 1.0
	top.offset_bottom = 68.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

	var title := Label.new()
	title.text = "IRON-FRONT  |  FIELD COMMAND"
	title.position = Vector2(18.0,5.0)
	title.add_theme_font_size_override("font_size",19)
	title.add_theme_color_override("font_color",Color(0.91,0.86,0.70))
	top.add_child(title)

	resources_label = Label.new()
	resources_label.position = Vector2(18.0,36.0)
	resources_label.add_theme_font_size_override("font_size",13)
	resources_label.add_theme_color_override("font_color",Color(0.77,0.84,0.77))
	top.add_child(resources_label)

	var controls := HBoxContainer.new()
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.offset_left = -670.0
	controls.offset_right = -10.0
	controls.offset_top = 9.0
	controls.offset_bottom = 57.0
	controls.alignment = BoxContainer.ALIGNMENT_END
	controls.add_theme_constant_override("separation",6)
	top.add_child(controls)

	cancel_build_button = _make_top_button("إلغاء البناء",108.0)
	cancel_build_button.visible = false
	cancel_build_button.pressed.connect(func(): cancel_placement_requested.emit())
	controls.add_child(cancel_build_button)

	rotate_build_button = _make_top_button("تدوير 90°",100.0)
	rotate_build_button.visible = false
	rotate_build_button.pressed.connect(func(): rotate_placement_requested.emit())
	controls.add_child(rotate_build_button)

	select_button = _make_top_button("تحديد الكل",128.0)
	select_button.pressed.connect(func(): select_all_requested.emit())
	controls.add_child(select_button)

	clear_selection_button = _make_top_button("إلغاء التحديد",112.0)
	clear_selection_button.pressed.connect(func(): clear_selection_requested.emit())
	controls.add_child(clear_selection_button)

	rally_button = _make_top_button("نقطة التجمع",112.0)
	rally_button.pressed.connect(func(): rally_point_requested.emit())
	controls.add_child(rally_button)

	cancel_rally_button = _make_top_button("إلغاء التجمع",112.0)
	cancel_rally_button.visible = false
	cancel_rally_button.pressed.connect(func(): cancel_rally_requested.emit())
	controls.add_child(cancel_rally_button)

	building_panel = PanelContainer.new()
	building_panel.anchor_left = 1.0
	building_panel.anchor_top = 0.0
	building_panel.anchor_right = 1.0
	building_panel.offset_left = -330.0
	building_panel.offset_right = -18.0
	building_panel.offset_top = 82.0
	building_panel.offset_bottom = 650.0
	building_panel.visible = false
	add_child(building_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",8)
	building_panel.add_child(content)

	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(func(): building_panel.visible = false)
	content.add_child(close_button)

	var name_label := Label.new()
	name_label.name = "BuildingTitle"
	name_label.add_theme_font_size_override("font_size",20)
	name_label.add_theme_color_override("font_color",Color(0.91,0.86,0.70))
	content.add_child(name_label)

	var description_label := Label.new()
	description_label.name = "BuildingDescription"
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description_label)

	var scroll := ScrollContainer.new()
	scroll.name = "BuildMenuScroll"
	scroll.custom_minimum_size = Vector2(280.0,420.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var build_list := VBoxContainer.new()
	build_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_list.add_theme_constant_override("separation",5)
	scroll.add_child(build_list)

	for item in BUILD_MENU:
		var kind: String = str(item.get("type",""))
		var build_button := Button.new()
		build_button.text = str(item.get("title",""))
		build_button.custom_minimum_size = Vector2(270.0,42.0)
		build_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		build_button.pressed.connect(_on_build_button_pressed.bind(kind))
		build_list.add_child(build_button)
		build_buttons[kind] = build_button
	if build_buttons.has("barracks"):
		build_barracks_button = build_buttons["barracks"]
	if build_buttons.has("factory"):
		build_factory_button = build_buttons["factory"]

	action_button = Button.new()
	action_button.text = "تنفيذ"
	action_button.pressed.connect(_on_action_pressed)
	content.add_child(action_button)

	upgrade_button = Button.new()
	upgrade_button.text = "ترقية المبنى"
	upgrade_button.pressed.connect(func(): building_upgrade_requested.emit(building_data))
	content.add_child(upgrade_button)

	message_label = Label.new()
	message_label.anchor_top = 1.0
	message_label.anchor_bottom = 1.0
	message_label.offset_left = 20.0
	message_label.offset_top = -48.0
	message_label.offset_right = 760.0
	message_label.offset_bottom = -12.0
	message_label.add_theme_color_override("font_color",Color(0.95,0.88,0.65))
	add_child(message_label)

func _make_top_button(button_text: String,button_width: float) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(button_width,40.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	return button

func _on_build_button_pressed(building_type: String) -> void:
	placement_requested.emit(building_type)

func set_selection_state(selected_count: int,total_count: int,all_selected: bool) -> void:
	select_button.text = "إلغاء الكل" if all_selected else "تحديد الكل"
	clear_selection_button.disabled = selected_count == 0
	if selected_count > 0:
		show_message("تم تحديد %d من %d وحدات." % [selected_count,total_count])

func set_placement_mode(active: bool) -> void:
	cancel_build_button.visible = active
	rotate_build_button.visible = active

func set_rally_mode(active: bool,rally_exists: bool) -> void:
	rally_button.text = "اختر موقع التجمع" if active else ("نقل نقطة التجمع" if rally_exists else "نقطة التجمع")
	cancel_rally_button.visible = active or rally_exists
	cancel_rally_button.text = "إلغاء التحديد" if active else "إلغاء التجمع"

func set_building_availability(availability: Dictionary) -> void:
	for item in BUILD_MENU:
		var kind: String = str(item.get("type",""))
		if not build_buttons.has(kind):
			continue
		var button: Button = build_buttons[kind]
		var available: bool = bool(availability.get(kind,false))
		button.disabled = not available
		var base_title: String = str(item.get("title",""))
		button.text = base_title if available else base_title + "  •  مكتمل / لا توجد ساحة"

func show_building(data: Dictionary,upgrade_cost: Dictionary = {},can_upgrade: bool = false,upgrade_benefit: String = "") -> void:
	building_data = data.duplicate(true)
	var content := building_panel.get_child(0) as VBoxContainer
	(content.get_node("BuildingTitle") as Label).text = str(data.get("title","مبنى"))
	(content.get_node("BuildingDescription") as Label).text = str(data.get("description",""))
	var action: String = str(data.get("action",""))
	var is_player_hq: bool = action == "hq" and str(data.get("team","")) == "player"
	(content.get_node("BuildMenuScroll") as ScrollContainer).visible = is_player_hq
	for item in BUILD_MENU:
		var kind: String = str(item.get("type",""))
		if build_buttons.has(kind):
			(build_buttons[kind] as Button).visible = is_player_hq
	action_button.visible = not is_player_hq
	match action:
		"mine": action_button.text = "تأمين الموقع وجمع الموارد"
		"barracks": action_button.text = "تدريب جندي"
		"factory": action_button.text = "إنتاج دبابة"
		"vehicle_factory": action_button.text = "إنتاج مركبة"
		"power": action_button.text = "تشغيل محطة الطاقة"
		"refinery": action_button.text = "معالجة الوقود"
		"research": action_button.text = "معلومات مركز الأبحاث"
		"watchtower": action_button.text = "معلومات برج المراقبة"
		"hospital": action_button.text = "خدمات المستشفى"
		"ammo": action_button.text = "تجهيز الذخيرة"
		"airfield": action_button.text = "معلومات المطار العسكري"
		"missile": action_button.text = "تفعيل الدفاع الجوي"
		"wall": action_button.text = "معلومات التحصين"
		"command": action_button.text = "تفعيل مركز القيادة"
		"hq": action_button.text = "معلومات مركز القيادة"
		_: action_button.text = "غير متاح"
	action_button.disabled = str(data.get("team","")) != "player" and action != "hq"
	var is_upgradeable: bool = str(data.get("team","")) == "player" and action != "hq" and action != "mine" and not str(data.get("id","")).is_empty()
	upgrade_button.visible = is_upgradeable
	if is_upgradeable:
		var level: int = int(data.get("level",1))
		var cost_text := _format_resource_cost(upgrade_cost)
		upgrade_button.text = "ترقية إلى المستوى %d  |  %s" % [level + 1,cost_text] if not upgrade_cost.is_empty() else "المبنى وصل للمستوى الأقصى"
		upgrade_button.disabled = not can_upgrade or upgrade_cost.is_empty()
		(content.get_node("BuildingDescription") as Label).text += "\nالمستوى الحالي: %d / 10\n%s" % [level,upgrade_benefit]
	building_panel.visible = true

func _format_resource_cost(cost: Dictionary) -> String:
	var labels := {"wood":"خشب","metal":"معدن","fuel":"وقود","stone":"حجر"}
	var parts: Array[String] = []
	for key in cost:
		parts.append("%s %d" % [str(labels.get(key,key)),int(cost[key])])
	return " - ".join(parts)

func _on_action_pressed() -> void:
	building_action_requested.emit(building_data)

func update_resources(values: Dictionary) -> void:
	resources_label.text = "خشب %d   معدن %d   وقود %d   حجر %d" % [int(values.get("wood",0)),int(values.get("metal",0)),int(values.get("fuel",0)),int(values.get("stone",0))]

func show_message(message: String) -> void:
	message_label.text = message
