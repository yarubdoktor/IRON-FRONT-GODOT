extends Node3D

const BattlefieldBuilderScript = preload("res://scripts/world/battlefield_builder.gd")
const CameraControllerScript = preload("res://scripts/camera/camera_controller.gd")
const EconomyManagerScript = preload("res://scripts/systems/economy_manager.gd")
const UnitManagerScript = preload("res://scripts/systems/unit_manager.gd")
const BuildingPlacementScript = preload("res://scripts/systems/building_placement_manager.gd")
const PersistenceManagerScript = preload("res://scripts/systems/persistence_manager.gd")
const HUDControllerScript = preload("res://scripts/ui/hud_controller.gd")
const InteractionControllerScript = preload("res://scripts/systems/interaction_controller.gd")

func _ready() -> void:
	var battlefield := BattlefieldBuilderScript.new()
	battlefield.name = "Battlefield"
	add_child(battlefield)
	var camera_controller := CameraControllerScript.new()
	camera_controller.name = "CameraController"
	add_child(camera_controller)
	var economy := EconomyManagerScript.new()
	economy.name = "EconomyManager"
	add_child(economy)
	var units := UnitManagerScript.new()
	units.name = "UnitManager"
	add_child(units)
	var building_manager := BuildingPlacementScript.new()
	building_manager.name = "BuildingPlacementManager"
	building_manager.configure(camera_controller.camera,economy,battlefield.get_initial_footprints())
	add_child(building_manager)
	var hud := HUDControllerScript.new()
	hud.name = "HUDController"
	add_child(hud)
	var persistence := PersistenceManagerScript.new()
	persistence.name = "PersistenceManager"
	persistence.configure(economy,building_manager,units,hud)
	add_child(persistence)
	var interaction := InteractionControllerScript.new()
	interaction.name = "InteractionController"
	interaction.configure(camera_controller.camera,hud,economy,units,building_manager,persistence)
	add_child(interaction)
