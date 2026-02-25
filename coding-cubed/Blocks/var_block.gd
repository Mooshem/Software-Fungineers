"""
Developer: Donovan Thach
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends StaticBody3D

# Environment variables to be initialized.
@onready var ui_display = $UIDisplay
@onready var ui_backDisplay = $UIBackDisplay
var ui_visible: bool = false
var raycast: RayCast3D
var var_name

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		raycast = player.get_node("Head/Camera3D/RayCast3D")
		
	# Set UI to invisible by default.
	if ui_display:
		ui_display.visible = false
	if ui_backDisplay:
		ui_backDisplay.visible = false


func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	handle_user_interaction(event)
	pass
	
func handle_user_interaction(event: InputEvent) -> void:
	"""Handles user inputs directed towards interacting with a block."""
	# Checks if during an interaction event if the player's raycast is colliding with a block.
	if !raycast or !raycast.is_colliding():
		return
		
	# Gets the current block that the player is looking at.
	var target_block = raycast.get_collider()
	if target_block != self:
		return
		
	# Handle interaction.
	if Input.is_action_just_pressed("interact"):
		toggle_ui()

func toggle_ui() -> void:
	if !ui_display:
		return
		
	ui_visible = !ui_visible
	ui_display.visible = ui_visible
	ui_backDisplay.visible = ui_visible
	
	if ui_visible:
		# Get the forward direction of the raycast.
		var raycast_direction = raycast.global_transform.basis.z
		
		# Get block center to open UI from.
		var block_center = global_position + Vector3(0.5, 0.5, 0.5)
		
		# Position the UI 1.25 units in the opposite direction to raycast point from block center.
		ui_display.global_position = block_center + (raycast_direction * 1.25)
		ui_backDisplay.global_position = block_center + (raycast_direction * 1.25)
		
		# Make UI face the player.
		ui_display.look_at(ui_display.global_position - raycast_direction)
		ui_backDisplay.look_at(ui_backDisplay.global_position + raycast_direction)
		
