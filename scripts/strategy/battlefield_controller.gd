extends Node3D
class_name StrategyBattlefieldController

@export var camera: Camera3D
@export var ground_collision_mask: int = 1
@export var selection_collision_mask: int = 1
@export_range(2.0, 80.0, 1.0) var auto_engage_distance: float = 14.0

var selected_squad: StrategySquad

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_world_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_world_tap(event.position)

func _physics_process(_delta: float) -> void:
	_auto_engage_squads()

func _handle_world_tap(screen_position: Vector2) -> void:
	if not is_instance_valid(camera):
		return
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 2000.0)
	query.collision_mask = selection_collision_mask | ground_collision_mask
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	var squad := _find_squad(collider)
	if is_instance_valid(squad):
		selected_squad = squad
		return
	if is_instance_valid(selected_squad):
		var point: Vector3 = hit.get("position", Vector3.ZERO)
		selected_squad.set_destination(point)

func _find_squad(object: Object) -> StrategySquad:
	var node := object as Node
	while is_instance_valid(node):
		if node is StrategySquad:
			return node as StrategySquad
		node = node.get_parent()
	return null

func _auto_engage_squads() -> void:
	var units := get_tree().get_nodes_in_group("strategy_units")
	for item in units:
		var squad := item as StrategySquad
		if not is_instance_valid(squad) or is_instance_valid(squad.target_enemy):
			continue
		var nearest: StrategySquad
		var nearest_distance := auto_engage_distance
		for candidate_item in units:
			var candidate := candidate_item as StrategySquad
			if not is_instance_valid(candidate) or candidate == squad or candidate.team_id == squad.team_id:
				continue
			var distance := squad.global_position.distance_to(candidate.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = candidate
		if is_instance_valid(nearest):
			squad.engage(nearest)
