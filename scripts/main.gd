extends Node3D

const HEADER_TEXT: String = "IRON-FRONT  |  GODOT 4"
const STATUS_TEXT: String = "اختر فرقة عسكرية ثم اضغط على الأرض لإصدار أمر الحركة  •  العدو يشتبك تلقائياً"

func _ready() -> void:
	_build_hud()

func _build_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "PrototypeHUD"
	add_child(layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var header: PanelContainer = PanelContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 14.0
	header.offset_top = 14.0
	header.offset_right = -14.0
	header.offset_bottom = 92.0
	root.add_child(header)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	header.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)

	var title: Label = Label.new()
	title.text = HEADER_TEXT
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(0.88, 0.78, 0.53))
	column.add_child(title)

	var resources: Label = Label.new()
	resources.text = "STEEL  8,000     FUEL  4,000     POWER  2,500     AMMO  3,000"
	resources.add_theme_font_size_override("font_size", 13)
	resources.add_theme_color_override("font_color", Color(0.84, 0.88, 0.81))
	column.add_child(resources)

	var status: Label = Label.new()
	status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_left = 18.0
	status.offset_right = -18.0
	status.offset_top = -58.0
	status.offset_bottom = -14.0
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.text = STATUS_TEXT
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66))
	root.add_child(status)
