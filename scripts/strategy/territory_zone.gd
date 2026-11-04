extends Node3D
class_name StrategyTerritoryZone

signal ownership_changed(new_owner: int)

@export_range(2.0, 100.0, 1.0) var capture_radius: float = 24.0
@export_range(1.0, 120.0, 1.0) var capture_seconds: float = 12.0
@export var owner_team: int = -1

var capture_team: int = -1
var capture_progress: float = 0.0

func _process(delta: float) -> void:
	var counts: Dictionary = {}
	for item in get_tree().get_nodes_in_group("strategy_units"):
		var squad := item as StrategySquad
		if not is_instance_valid(squad) or squad.squad_size <= 0:
			continue
		if global_position.distance_to(squad.global_position) <= capture_radius:
			counts[squad.team_id] = int(counts.get(squad.team_id, 0)) + squad.squad_size

	if counts.is_empty():
		return

	var leading_team := -1
	var leading_count := 0
	var tied := false
	for key in counts.keys():
		var count := int(counts[key])
		if count > leading_count:
			leading_team = int(key)
			leading_count = count
			tied = false
		elif count == leading_count:
			tied = true

	if tied or leading_team == owner_team:
		return
	if capture_team != leading_team:
		capture_team = leading_team
		capture_progress = 0.0
	capture_progress = minf(capture_progress + delta, capture_seconds)
	if capture_progress >= capture_seconds:
		owner_team = capture_team
		capture_progress = 0.0
		ownership_changed.emit(owner_team)
