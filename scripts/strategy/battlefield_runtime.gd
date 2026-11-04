extends Node3D
class_name BattlefieldRuntime

const UNIT_SCRIPT: Script = preload("res://scripts/strategy/squad_unit.gd")
const CONTROLLER_SCRIPT: Script = preload("res://scripts/strategy/battlefield_controller.gd")
const ZONE_SCRIPT: Script = preload("res://scripts/strategy/territory_zone.gd")

@export var player_color: Color = Color(0.18, 0.48, 0.78)
@export var enemy_color: Color = Color(0.78, 0.22, 0.16)

func _ready() -> void:
	_create_ground_collision()
	_create_orders_controller()
	_create_demo_squads()
	_create_capture_zone()

func _create_ground_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "BattlefieldGroundCollider"
	body.collision_layer = 1
	body.position = Vector3(43.0, -0.18, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120.0, 0.3, 84.0)
	shape.shape = box
	body.add_child(shape)
	add_child(body)

func _create_orders_controller() -> void:
	var controller := Node3D.new()
	controller.name = "OrdersController"
	controller.set_script(CONTROLLER_SCRIPT)
	controller.set("camera", get_node_or_null("../../CameraRig/Camera3D"))
	add_child(controller)

func _create_demo_squads() -> void:
	_spawn_squad("Blue_Infantry_01", 0, 0, Vector3(-16.0, 0.0, -7.0), 36, player_color, 0)
	_spawn_squad("Blue_Tank_01", 0, 1, Vector3(-20.0, 0.0, 3.0), 8, Color(0.22, 0.42, 0.68), 1)
	_spawn_squad("Blue_Armored_01", 0, 2, Vector3(-8.0, 0.0, 13.0), 12, Color(0.28, 0.56, 0.82), 2)
	_spawn_squad("Red_Infantry_01", 1, 0, Vector3(99.0, 0.0, 7.0), 34, enemy_color, 0)
	_spawn_squad("Red_Tank_01", 1, 1, Vector3(103.0, 0.0, -4.0), 7, Color(0.65, 0.2, 0.16), 1)
	_spawn_squad("Red_Armored_01", 1, 2, Vector3(91.0, 0.0, -14.0), 10, Color(0.82, 0.34, 0.22), 2)

func _spawn_squad(unit_name: String, team: int, kind: int, world_spawn_position: Vector3, count: int, tint: Color, visual_kind: int) -> void:
	var squad := Node3D.new()
	squad.name = unit_name
	squad.set_script(UNIT_SCRIPT)
	squad.set("team_id", team)
	squad.set("unit_type", kind)
	squad.set("squad_size", count)
	squad.set("move_speed", 4.5 if kind == 0 else 6.0)
	squad.position = world_spawn_position
	add_child(squad)

	var body := StaticBody3D.new()
	body.name = "SelectableBody"
	body.collision_layer = 1
	body.collision_mask = 0
	squad.add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.35
	capsule.height = 2.5
	collision.shape = capsule
	collision.position.y = 1.0
	body.add_child(collision)

	if visual_kind == 0:
		for index in range(5):
			var soldier := MeshInstance3D.new()
			var mesh := CapsuleMesh.new()
			mesh.radius = 0.32
			mesh.height = 1.55
			soldier.mesh = mesh
			soldier.material_override = _unit_material(tint.lightened(0.08 if index % 2 == 0 else 0.0))
			soldier.position = Vector3(float(index % 3) * 0.78 - 0.75, 0.8, (float(index) / 3.0) * 0.82 - 0.35)
			squad.add_child(soldier)
	elif visual_kind == 1:
		var hull := MeshInstance3D.new()
		var hull_mesh := BoxMesh.new()
		hull_mesh.size = Vector3(2.6, 0.8, 3.6)
		hull.mesh = hull_mesh
		hull.material_override = _unit_material(tint)
		hull.position.y = 0.72
		squad.add_child(hull)
		var turret := MeshInstance3D.new()
		var turret_mesh := CylinderMesh.new()
		turret_mesh.top_radius = 0.62
		turret_mesh.bottom_radius = 0.72
		turret_mesh.height = 0.55
		turret.mesh = turret_mesh
		turret.material_override = _unit_material(tint.darkened(0.18))
		turret.position.y = 1.3
		squad.add_child(turret)
		var barrel := MeshInstance3D.new()
		var barrel_mesh := CylinderMesh.new()
		barrel_mesh.top_radius = 0.09
		barrel_mesh.bottom_radius = 0.13
		barrel_mesh.height = 1.7
		barrel.mesh = barrel_mesh
		barrel.material_override = _unit_material(Color(0.12, 0.14, 0.13))
		barrel.position = Vector3(0.0, 1.38, -1.0)
		barrel.rotation_degrees.x = 90.0
		squad.add_child(barrel)
	else:
		var vehicle := MeshInstance3D.new()
		var vehicle_mesh := BoxMesh.new()
		vehicle_mesh.size = Vector3(2.35, 1.2, 3.0)
		vehicle.mesh = vehicle_mesh
		vehicle.material_override = _unit_material(tint)
		vehicle.position.y = 0.72
		squad.add_child(vehicle)

func _create_capture_zone() -> void:
	var zone := Node3D.new()
	zone.name = "CentralCaptureZone"
	zone.set_script(ZONE_SCRIPT)
	zone.position = Vector3(43.0, 0.0, 0.0)
	zone.set("capture_radius", 17.0)
	zone.set("capture_seconds", 10.0)
	add_child(zone)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 15.8
	torus.outer_radius = 16.3
	ring.mesh = torus
	ring.material_override = _unit_material(Color(0.85, 0.69, 0.25, 0.75))
	ring.position.y = 0.12
	zone.add_child(ring)

	var marker := Label3D.new()
	marker.text = "NEUTRAL CONTROL POINT"
	marker.position.y = 2.0
	marker.font_size = 32
	marker.modulate = Color(0.98, 0.82, 0.4)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	zone.add_child(marker)

func _unit_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
