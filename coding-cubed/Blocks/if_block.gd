"""
Developer: Daniel Martin
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends BreakableBlock

# Global variables to be set.
var raycast: RayCast3D
var player = null
var var1_name: String = ""
var var2_name: String = ""
var compare: String = ">"

func _ready() -> void:
	super._ready()
	player = get_tree().get_first_node_in_group("player")
	if player:
		raycast = player.get_node("Head/Camera3D/RayCast3D")

func _unhandled_input(event: InputEvent) -> void:
	if !raycast or !raycast.is_colliding():
		return
	if raycast.get_collider() != self:
		return
	if Input.is_action_just_pressed("interact"):
		_open_if_menu()

func _open_if_menu() -> void:
	if !player:
		return
	var menu = player.get_node("CanvasLayer/IfBlockMenu")
	menu.open_for_block(self)
	get_tree().paused = true

# DO THIS WHEN SIGNAL IS RECIEVED, IF RETURN TRUE, OUTPUT A SIGNAL
func evaluate() -> bool:
	"""Finds the two variable blocks by name and compares their values."""
	var val_a = _get_var_value(var1_name)
	var val_b = _get_var_value(var2_name)

	if val_a == null or val_b == null:
		push_warning("IfBlock: could not find one or both variables.")
		return false

	# Attempt numeric comparison, fall back to string
	if val_a.is_valid_float() and val_b.is_valid_float():
		var a = float(val_a)
		var b = float(val_b)
		match compare:
			">":  return a > b
			"<":  return a < b
			">=": return a >= b
			"<=": return a <= b
			"==": return a == b
			"!=": return a != b
	else:
		match compare:
			"==": return val_a == val_b
			"!=": return val_a != val_b

	return false

func _get_var_value(name: String) -> String:
	"""Searches the scene for a variable block with a matching var_name."""
	if name == "":
		return ""
	# Search all nodes for var blocks with matching name
	for node in get_tree().get_nodes_in_group("var_blocks"):
		if node.var_name == name:
			return node.var_val
	push_warning("IfBlock: no variable block found with name '%s'" % name)
	return ""
