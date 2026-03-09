"""
Developer: Coding Cubed Team
Increment block: updates a named variable by a step each time it receives a signal.
"""

extends FlowBlock

var raycast: RayCast3D
var player = null
var powered := false

var target_var_name: String = "i"
var increment_by: int = 1

# Varaible to prevent block breaking.
var is_locked: bool = true

func _ready() -> void:
	super._ready()
	player = get_tree().get_first_node_in_group("player")
	if player:
		raycast = player.get_node("Head/Camera3D/RayCast3D")
		
	# Gray shift to denote unchangability in game.
	var mesh = $MeshInstance3D
	if mesh:
		var existing = mesh.get_active_material(0)
		if existing is StandardMaterial3D:
			var mat = existing.duplicate() as StandardMaterial3D
			mat.albedo_color = Color(0.489, 0.489, 0.489, 1.0)
			mesh.material_override = mat

func _unhandled_input(event: InputEvent) -> void:
	if not raycast or not raycast.is_colliding():
		return
	if raycast.get_collider() != self:
		return
	if Input.is_action_just_pressed("interact"):
		_open_increment_menu()

func _open_increment_menu() -> void:
	if not player:
		return
	var menu = player.get_node("CanvasLayer/IncrementBlockMenu")
	
	# Disable editing for the UI (prevent changes in the block).
	menu.open_for_block(self, true)
	get_tree().paused = true

func receive_signal(run_id: int = -1, from_node: Node = null, step_id: int = 0) -> void:
	if not should_process_signal(run_id, step_id):
		return
	flash_signal()
	powered = true
	_increment_target_variable()
	emit_signal_to_adjacent_with_run(run_id, from_node, step_id)

func _increment_target_variable() -> void:
	if target_var_name.strip_edges() == "":
		return

	for node in get_tree().get_nodes_in_group("var_blocks"):
		if not node:
			continue
		if not ("var_name" in node and "var_val" in node):
			continue
		if str(node.var_name) != target_var_name:
			continue

		var current_text := str(node.var_val).strip_edges()
		var current_value := 0.0
		if current_text != "" and current_text.is_valid_float():
			current_value = float(current_text)
		var new_value := current_value + float(increment_by)
		if abs(new_value - round(new_value)) < 0.0001:
			node.var_val = str(int(round(new_value)))
		else:
			node.var_val = str(new_value)
		return
