class_name EconomyManager
extends Node

signal resources_changed(resources: Dictionary)

var resources: Dictionary = {"wood":500,"metal":300,"fuel":180,"stone":250}
var secured_mines: Dictionary = {}

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 8.0
	timer.autostart = true
	timer.timeout.connect(_produce_passive_resources)
	add_child(timer)

func perform_building_action(data: Dictionary, unit_manager: Node) -> String:
	var action: String = str(data.get("action",""))
	if action == "mine":
		if str(data.get("team","")) != "player":
			return "هذا الموقع تحت سيطرة العدو."
		var kind: String = str(data.get("resource","wood"))
		var amount: int = 60
		resources[kind] = int(resources.get(kind,0)) + amount
		secured_mines[str(data.get("id",""))] = true
		resources_changed.emit(resources.duplicate(true))
		return "تم جمع %d من %s." % [amount, _resource_name(kind)]
	if action == "barracks":
		var cost := {"wood":80,"metal":35}
		if not _can_afford(cost):
			return "الموارد غير كافية لتدريب جندي."
		_spend(cost)
		unit_manager.spawn_infantry()
		return "تم تدريب جندي جديد وإضافته إلى قواتك."
	if action == "factory":
		var cost := {"metal":70,"fuel":35}
		if not _can_afford(cost):
			return "الموارد غير كافية لإنتاج مركبة."
		_spend(cost)
		unit_manager.spawn_vehicle()
		return "تم إنتاج مركبة دعم جديدة."
	if action == "hq":
		return "مركز القيادة: راقب مواردك وقواتك ووسّع سيطرتك على الميدان."
	return "هذا مبنى تابع للعدو ولا يمكن إصدار أوامر إليه."

func _produce_passive_resources() -> void:
	for kind in ["wood","metal","fuel","stone"]:
		resources[kind] = int(resources.get(kind,0)) + (3 if kind == "wood" else 2)
	resources_changed.emit(resources.duplicate(true))

func can_afford_building() -> bool:
	return _can_afford({"wood":120,"metal":75})


func pay_building_cost() -> bool:
	if not can_afford_building():
		return false
	_spend({"wood":120,"metal":75})
	return true


func _can_afford(cost: Dictionary) -> bool:
	for key in cost:
		if int(resources.get(key,0)) < int(cost[key]):
			return false
	return true

func _spend(cost: Dictionary) -> void:
	for key in cost:
		resources[key] = int(resources.get(key,0)) - int(cost[key])
	resources_changed.emit(resources.duplicate(true))

func _resource_name(kind: String) -> String:
	match kind:
		"wood": return "الخشب"
		"metal": return "المعادن"
		"fuel": return "الوقود"
		"stone": return "الحجر"
	return kind
