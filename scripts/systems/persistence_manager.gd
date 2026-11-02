class_name PersistenceManager
extends Node

const SAVE_PATH := "user://iron_front_save.cfg"

var economy: EconomyManager
var building_manager: BuildingPlacementManager
var unit_manager: UnitManager
var hud: HUDController

func configure(economy_node: EconomyManager, building_node: BuildingPlacementManager, unit_node: UnitManager, hud_node: HUDController) -> void:
	economy = economy_node
	building_manager = building_node
	unit_manager = unit_node
	hud = hud_node

func _ready() -> void:
	call_deferred("load_game")

func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("economy","resources",economy.resources)
	config.set_value("economy","secured_mines",economy.secured_mines)
	config.set_value("buildings","placed",building_manager.get_save_data())
	config.set_value("units","army",unit_manager.get_save_data())
	config.set_value("rally","active",unit_manager.rally_active)
	config.set_value("rally","position",unit_manager.rally_position)
	var error: Error = config.save(SAVE_PATH)
	hud.show_message("تم حفظ تقدمك." if error == OK else "تعذر حفظ اللعبة. رمز الخطأ: %d" % error)

func load_game() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(SAVE_PATH)
	if error != OK:
		hud.show_message("لا يوجد حفظ سابق؛ بدأت معركة جديدة.")
		return
	var resources_value: Variant = config.get_value("economy","resources",economy.resources)
	if resources_value is Dictionary:
		economy.resources = resources_value.duplicate(true)
		economy.resources_changed.emit(economy.resources.duplicate(true))
	var secured_mines_value: Variant = config.get_value("economy","secured_mines",{})
	if secured_mines_value is Dictionary:
		economy.secured_mines = secured_mines_value.duplicate(true)
	else:
		economy.secured_mines = {}
	var buildings_value: Variant = config.get_value("buildings","placed",[])
	if buildings_value is Array:
		building_manager.load_save_data(buildings_value)
	var units_value: Variant = config.get_value("units","army",[])
	if units_value is Array:
		unit_manager.load_save_data(units_value)
	unit_manager.cancel_rally_point()
	if bool(config.get_value("rally","active",false)):
		var rally_value: Variant = config.get_value("rally","position",Vector3.ZERO)
		if rally_value is Vector3:
			unit_manager.set_rally_point(rally_value)
	hud.show_message("تم تحميل آخر تقدم محفوظ.")
