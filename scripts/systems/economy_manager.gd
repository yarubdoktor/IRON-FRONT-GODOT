class_name EconomyManager
extends Node

signal resources_changed(resources: Dictionary)
signal building_level_changed(building_id: String, new_level: int)

var resources: Dictionary = {"wood":500,"metal":300,"fuel":180,"stone":250}
var secured_mines: Dictionary = {}
var building_levels: Dictionary = {}

const MAX_BUILDING_LEVEL: int = 10
const VALID_RESOURCES: Array[String] = ["wood","metal","fuel","stone"]
const BUILDING_COSTS: Dictionary = {
	"barracks":{"wood":120,"metal":75},
	"power":{"wood":35,"metal":100,"stone":35},
	"refinery":{"wood":45,"metal":110,"fuel":30},
	"factory":{"wood":80,"metal":180,"fuel":80,"stone":35},
	"research":{"wood":80,"metal":130,"stone":50},
	"watchtower":{"wood":70,"metal":60},
	"hospital":{"wood":90,"metal":75,"fuel":20},
	"ammo":{"wood":35,"metal":110,"fuel":45},
	"vehicle_factory":{"wood":60,"metal":150,"fuel":60},
	"airfield":{"wood":90,"metal":200,"fuel":100,"stone":50},
	"missile":{"wood":50,"metal":170,"fuel":60,"stone":40},
	"wall":{"wood":45,"metal":30},
	"command":{"wood":90,"metal":110,"fuel":20}
}

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 8.0
	timer.autostart = true
	timer.timeout.connect(_produce_passive_resources)
	add_child(timer)

func perform_building_action(data: Dictionary,unit_manager: Node) -> String:
	var action: String = str(data.get("action",""))
	if action == "mine":
		if str(data.get("team","")) != "player":
			return "هذا الموقع تحت سيطرة العدو."
		var mine_id: String = str(data.get("id","")).strip_edges()
		if mine_id.is_empty():
			return "تعذر تحديد هوية موقع الموارد."
		if secured_mines.has(mine_id):
			return "تم تأمين هذا الموقع وجمع موارده سابقاً."
		var kind: String = str(data.get("resource","wood"))
		if not VALID_RESOURCES.has(kind):
			return "نوع المورد في هذا الموقع غير صالح."
		var amount: int = 60
		resources[kind] = int(resources.get(kind,0)) + amount
		secured_mines[mine_id] = true
		resources_changed.emit(resources.duplicate(true))
		return "تم جمع %d من %s." % [amount,_resource_name(kind)]
	match action:
		"barracks":
			var infantry_cost := _scaled_training_cost({"wood":80,"metal":35},str(data.get("id","")))
			if not _can_afford(infantry_cost):
				return "الموارد غير كافية لتدريب جندي."
			_spend(infantry_cost)
			unit_manager.spawn_infantry()
			return "تم تدريب جندي جديد وإضافته إلى قواتك."
		"factory":
			var tank_cost := _scaled_training_cost({"metal":100,"fuel":45},str(data.get("id","")))
			if not _can_afford(tank_cost):
				return "الموارد غير كافية لإنتاج دبابة."
			_spend(tank_cost)
			unit_manager.spawn_vehicle()
			return "تم تجهيز دبابة جديدة من مصنع الدبابات."
		"vehicle_factory":
			var vehicle_cost := _scaled_training_cost({"metal":70,"fuel":35},str(data.get("id","")))
			if not _can_afford(vehicle_cost):
				return "الموارد غير كافية لإنتاج مركبة."
			_spend(vehicle_cost)
			unit_manager.spawn_vehicle()
			return "تم إنتاج مركبة دعم جديدة."
		"power":
			resources["stone"] = int(resources.get("stone",0)) + _scaled_output(18,str(data.get("id","")))
			resources_changed.emit(resources.duplicate(true))
			return "محطة الطاقة تعمل. تمت إضافة 18 وحدة إلى مخزون الطاقة التمثيلي."
		"refinery":
			resources["fuel"] = int(resources.get("fuel",0)) + _scaled_output(35,str(data.get("id","")))
			resources_changed.emit(resources.duplicate(true))
			return "تمت معالجة 35 وحدة وقود."
		"ammo":
			resources["metal"] = int(resources.get("metal",0)) + _scaled_output(25,str(data.get("id","")))
			resources_changed.emit(resources.duplicate(true))
			return "تم تجهيز إمداد الذخيرة وإضافة مواد تشغيلية."
		"research":
			return "مركز الأبحاث جاهز. نظام التقنيات المتقدمة سيُربط في مرحلة الأبحاث."
		"watchtower":
			return "برج المراقبة جاهز. ربط الرصد والمدى الدفاعي يأتي مع نظام القتال."
		"hospital":
			return "المستشفى الميداني جاهز. نظام علاج الوحدات سيُربط مع نظام الصحة."
		"airfield":
			return "المطار العسكري جاهز. وحدات الطيران ستُفعّل ضمن مرحلة القوات الجوية."
		"missile":
			return "منظومة دفاع الصواريخ جاهزة. تفعيل الاشتباك الجوي مرتبط بنظام القتال."
		"wall":
			return "التحصين الدفاعي مثبت. سيُربط الضرر والتدمير مع نظام القتال."
		"command":
			resources["stone"] = int(resources.get("stone",0)) + _scaled_output(12,str(data.get("id","")))
			resources_changed.emit(resources.duplicate(true))
			return "مركز القيادة المتقدم يعمل. تمت إضافة 12 وحدة دعم."
		"hq":
			return "مركز القيادة: راقب مواردك وقواتك ووسّع منشآت القاعدة."
	return "هذا المبنى لا يملك أمراً متاحاً حالياً."

func _produce_passive_resources() -> void:
	for kind in VALID_RESOURCES:
		resources[kind] = int(resources.get(kind,0)) + (3 if kind == "wood" else 2)
	resources_changed.emit(resources.duplicate(true))

func can_afford_building(building_type: String = "barracks") -> bool:
	var cost: Dictionary = BUILDING_COSTS.get(building_type,{})
	return not cost.is_empty() and _can_afford(cost)

func pay_building_cost(building_type: String = "barracks") -> bool:
	var cost: Dictionary = BUILDING_COSTS.get(building_type,{})
	if cost.is_empty() or not _can_afford(cost):
		return false
	_spend(cost)
	return true

func get_building_level(building_id: String) -> int:
	return maxi(int(building_levels.get(building_id,1)),1)

func get_upgrade_cost(building_type: String, building_id: String) -> Dictionary:
	if not BUILDING_COSTS.has(building_type):
		return {}
	var current_level: int = get_building_level(building_id)
	if current_level >= MAX_BUILDING_LEVEL:
		return {}
	var base_cost: Dictionary = BUILDING_COSTS[building_type]
	var cost: Dictionary = {}
	for resource_name in base_cost:
		cost[resource_name] = ceili(float(base_cost[resource_name]) * 0.55 * float(current_level))
	return cost

func can_upgrade_building(building_type: String, building_id: String) -> bool:
	var cost: Dictionary = get_upgrade_cost(building_type,building_id)
	return not cost.is_empty() and _can_afford(cost)

func upgrade_building(building_type: String, building_id: String) -> bool:
	if building_id.strip_edges().is_empty():
		return false
	var current_level: int = get_building_level(building_id)
	if current_level >= MAX_BUILDING_LEVEL:
		return false
	var cost: Dictionary = get_upgrade_cost(building_type,building_id)
	if cost.is_empty() or not _can_afford(cost):
		return false
	_spend(cost)
	building_levels[building_id] = current_level + 1
	building_level_changed.emit(building_id,current_level + 1)
	return true

func set_building_levels(levels: Dictionary) -> void:
	building_levels.clear()
	for building_id in levels:
		var level: int = clampi(int(levels[building_id]),1,MAX_BUILDING_LEVEL)
		building_levels[str(building_id)] = level

func get_upgrade_benefit(building_type: String, next_level: int) -> String:
	match building_type:
		"barracks": return "خفض تكلفة تدريب القوات بنسبة 5% لكل مستوى إضافي، حتى 50%."
		"factory","vehicle_factory": return "خفض تكلفة إنتاج المركبات بنسبة 5% لكل مستوى إضافي، حتى 50%."
		"power","refinery","ammo","command": return "زيادة إنتاج الموارد بنسبة 5% لكل مستوى إضافي."
		"research","hospital","watchtower","missile","wall","airfield": return "رفع مستوى المنشأة؛ مزاياها التشغيلية المتخصصة ستُفعّل مع اكتمال نظامها."
	return "رفع مستوى المبنى وتحسين كفاءته ضمن النظام المتاح حالياً."

func _scaled_training_cost(base_cost: Dictionary, building_id: String) -> Dictionary:
	var level: int = get_building_level(building_id)
	var multiplier: float = maxf(0.5,1.0 - 0.05 * float(level - 1))
	var result: Dictionary = {}
	for resource_name in base_cost:
		result[resource_name] = ceili(float(base_cost[resource_name]) * multiplier)
	return result

func _scaled_output(base_amount: int, building_id: String) -> int:
	var level: int = get_building_level(building_id)
	return ceili(float(base_amount) * (1.0 + 0.05 * float(level - 1)))

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
