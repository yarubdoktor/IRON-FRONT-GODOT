extends Node3D
class_name StrategySquad

signal squad_defeated(squad: StrategySquad)

@export var team_id: int = 0
@export_enum("Infantry", "Tank", "Armored") var unit_type: int = 0
@export_range(1, 500, 1) var squad_size: int = 30
@export_range(1.0, 20.0, 0.1) var move_speed: float = 5.0
@export_range(1.0, 100.0, 0.5) var attack_range: float = 9.0
@export_range(0.1, 100.0, 0.1) var damage_per_second: float = 8.0
@export_range(1.0, 1000.0, 1.0) var hit_points_per_soldier: float = 20.0

var destination: Vector3
var has_destination: bool = false
var target_enemy: StrategySquad
var _attack_clock: float = 0.0
var _label: Label3D
var _initial_strength: int

func _ready() -> void:
	add_to_group("strategy_units")
	_initial_strength = maxi(squad_size, 1)
	destination = global_position
	_label = Label3D.new()
	_label.name = "SquadStrengthLabel"
	_label.position = Vector3(0.0, 2.4, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 48
	_label.outline_size = 8
	add_child(_label)
	_update_label()

func set_destination(world_position: Vector3) -> void:
	destination = world_position
	has_destination = true
	target_enemy = null

func engage(enemy: StrategySquad) -> void:
	if is_instance_valid(enemy) and enemy.team_id != team_id:
		target_enemy = enemy
		has_destination = false

func _physics_process(delta: float) -> void:
	if squad_size <= 0:
		return
	if is_instance_valid(target_enemy):
		var distance := global_position.distance_to(target_enemy.global_position)
		if distance > attack_range:
			global_position = global_position.move_toward(target_enemy.global_position, move_speed * delta)
		else:
			_attack_clock += delta
			if _attack_clock >= 1.0:
				_attack_clock -= 1.0
				target_enemy.apply_damage(damage_per_second)
	elif has_destination:
		global_position = global_position.move_toward(destination, move_speed * delta)
		if global_position.distance_to(destination) <= 0.15:
			has_destination = false

func apply_damage(amount: float) -> void:
	if squad_size <= 0:
		return
	var casualties := maxi(1, int(ceil(amount / maxf(hit_points_per_soldier, 1.0))))
	squad_size = maxi(0, squad_size - casualties)
	_update_label()
	if squad_size == 0:
		target_enemy = null
		squad_defeated.emit(self)
		queue_free()

func get_combat_strength() -> float:
	return float(squad_size) * damage_per_second / float(_initial_strength)

func _update_label() -> void:
	if is_instance_valid(_label):
		_label.text = str(squad_size)
