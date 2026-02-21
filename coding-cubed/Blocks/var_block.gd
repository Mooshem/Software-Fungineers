"""
Developer: Donovan Thach
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends StaticBody3D

# Environment variables to be initialized.
@onready var ui_display = $UIDisplay
var ui_visible: bool = false
var raycast: RayCast3D

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var raycast = player.get_node("Head/Camera3D/Raycast3D")


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
	
	if ui_visible:
		# Get the direction of the vector from raycast.
		var hit_normal = raycast.get_collision_normal()
		
		# Position 1 unit away from block in normal direction.
		ui_display.position = hit_normal
		
		# Make the UI face the player (opposite of raycast vector direction).
		var raycast_direction = -raycast.global_transform.basis.z
		ui_display.look_at(ui_display.global_position + raycast_direction)
		
