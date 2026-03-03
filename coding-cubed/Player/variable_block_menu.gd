"""
Developer: Donovan Thach, Daniel Martin
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends Control

var current_block = null
@onready var var1_input = $Var1Input
@onready var var2_input = $Var2Input
@onready var comparison = $Comparison

func open_for_block(block) -> void:
	# Get current block and set inputs for it's attributes.
	current_block = block
	var1_input.text = block.var1_name
	var2_input.text = block.var2_name
	comparison.text = block.compare
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _on_save_button_pressed() -> void:
	# Saves current values assigned to the block raycast collided with.
	if current_block:
		current_block.var1_name = var1_input.text
		current_block.var2_name = var2_input.text
		current_block.compare = comparison.text
	_close()

func _on_close_button_pressed() -> void:
	# Close the UI.
	_close()

func _close() -> void:
	# Closes the UI.
	visible = false
	current_block = null
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
