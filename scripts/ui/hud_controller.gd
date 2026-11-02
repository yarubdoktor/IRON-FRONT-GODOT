class_name HUDController
extends CanvasLayer

signal select_all_requested
signal building_action_requested(data: Dictionary)
signal placement_requested(building_type: String)
signal save_requested
signal load_requested

var building_data: Dictionary = {}
var action_button: Button
var building_panel: PanelContainer
var message_label: Label
var resources_label: Label
var build_barracks_button: Button
var build_factory_button: Button

func _ready() -> void:
	_build_interface()

func _build_interface() -> void:
	var top := ColorRect.new()
	top.color = Color(0.055,0.075,0.085,0.92)
	top.anchor_right = 1.0
	top.offset_bottom = 64.0
	add_child(top)
	var title := Label.new()
	title.text = "IRON-FRONT  |  FIELD COMMAND"
	title.position = Vector2(20,8)
	title.add_theme_font_size_override("font_size",21)
	title.add_theme_color_override("font_color",Color(0.91,0.86,0.70))
	top.add_child(title)
	resources_label = Label.new()
	resources_label.position = Vector2(20,37)
	resources_label.add_theme_font_size_override("font_size",14)
	resources_label.add_theme_color_override("font_color",Color(0.77,0.84,0.77))
	top.add_child(resources_label)
	var select_button := Button.new()
	select_button.text = "تحديد كل القوات"
	select_button.anchor_left = 1.0
	select_button.anchor_right = 1.0
	select_button.offset_left = -220.0
	select_button.offset_right = -18.0
	select_button.offset_top = 12.0
	select_button.offset_bottom = 52.0
	select_button.pressed.connect(func(): select_all_requested.emit())
	top.add_child(select_button)
	var save_button := Button.new()
	save_button.text = "حفظ"
	save_button.position = Vector2(690.0,12.0)
	save_button.size = Vector2(76.0,40.0)
	save_button.pressed.connect(func(): save_requested.emit())
	top.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "تحميل"
	load_button.position = Vector2(774.0,12.0)
	load_button.size = Vector2(76.0,40.0)
	load_button.pressed.connect(func(): load_requested.emit())
	top.add_child(load_button)
	building_panel = PanelContainer.new()
	building_panel.anchor_left = 1.0
	building_panel.anchor_top = 0.0
	building_panel.anchor_right = 1.0
	building_panel.offset_left = -300.0
	building_panel.offset_right = -18.0
	building_panel.offset_top = 82.0
	building_panel.offset_bottom = 390.0
	building_panel.visible = false
	add_child(building_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
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
	build_barracks_button = Button.new()
	build_barracks_button.text = "بدء بناء ثكنة"
	build_barracks_button.pressed.connect(func(): placement_requested.emit("barracks"))
	content.add_child(build_barracks_button)
	build_factory_button = Button.new()
	build_factory_button.text = "بدء بناء مصنع مركبات"
	build_factory_button.pressed.connect(func(): placement_requested.emit("factory"))
	content.add_child(build_factory_button)
	action_button = Button.new()
	action_button.text = "تنفيذ"
	action_button.pressed.connect(_on_action_pressed)
	content.add_child(action_button)
	message_label = Label.new()
	message_label.anchor_top = 1.0
	message_label.anchor_bottom = 1.0
	message_label.offset_left = 20.0
	message_label.offset_top = -48.0
	message_label.offset_right = 600.0
	message_label.offset_bottom = -12.0
	message_label.add_theme_color_override("font_color",Color(0.95,0.88,0.65))
	add_child(message_label)

func show_building(data: Dictionary) -> void:
	building_data = data.duplicate(true)
	var content := building_panel.get_child(0) as VBoxContainer
	(content.get_node("BuildingTitle") as Label).text = str(data.get("title","مبنى"))
	(content.get_node("BuildingDescription") as Label).text = str(data.get("description",""))
	var action: String = str(data.get("action",""))
	build_barracks_button.visible = action == "hq" and str(data.get("team","")) == "player"
	build_factory_button.visible = build_barracks_button.visible
	match action:
		"mine": action_button.text = "تأمين الموقع وجمع الموارد"
		"barracks": action_button.text = "تدريب جندي  |  80 خشب + 35 معدن"
		"factory": action_button.text = "إنتاج مركبة  |  70 معدن + 35 وقود"
		"hq": action_button.text = "معلومات مركز القيادة"
		_: action_button.text = "غير متاح"
	action_button.disabled = str(data.get("team","")) != "player" and action != "hq"
	building_panel.visible = true

func _on_action_pressed() -> void:
	building_action_requested.emit(building_data)

func update_resources(values: Dictionary) -> void:
	resources_label.text = "خشب %d   معدن %d   وقود %d   حجر %d" % [int(values.get("wood",0)),int(values.get("metal",0)),int(values.get("fuel",0)),int(values.get("stone",0))]

func show_message(message: String) -> void:
	message_label.text = message
