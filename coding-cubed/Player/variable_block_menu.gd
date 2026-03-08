"""
Developer: Donovan Thach, Daniel Martin
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends Control

var current_block = null
@onready var var_name_input = $VarInput
@onready var val_input = $ValInput

func open_for_block(block, read_only: bool = false) -> void:
	# Get current block and set inputs for it's attributes.
	current_block = block
	var_name_input.text = block.var_name
	val_input.text = block.var_val
	
	# Disable inputs and hide save button if block is locked (read-only for unchangeables).
	var_name_input.editable = !read_only
	val_input.editable = !read_only
	$SaveButton.visible = !read_only
	
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_save_button_pressed() -> void:
	# Saves current values assigned to the block raycast collided with.
	if current_block:
		current_block.var_name = var_name_input.text
		current_block.var_val = val_input.text
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
