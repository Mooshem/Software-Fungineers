"""
Developer: Coding Cubed Team
Increment block configuration UI.
"""

extends Control

var current_block = null
@onready var target_var_input = $TargetVarInput
@onready var step_input = $StepInput

func open_for_block(block) -> void:
	current_block = block
	target_var_input.text = str(block.target_var_name)
	step_input.text = str(block.increment_by)
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_save_button_pressed() -> void:
	if current_block:
		current_block.target_var_name = target_var_input.text.strip_edges()
		var step_text: String = step_input.text.strip_edges()
		if step_text == "" or not step_text.is_valid_int():
			current_block.increment_by = 1
		else:
			current_block.increment_by = int(step_text)
	_close()

func _on_close_button_pressed() -> void:
	_close()

func _close() -> void:
	visible = false
	current_block = null
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
