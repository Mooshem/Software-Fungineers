"""
Developer: Daniel Martin, Donovan Thach
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends FlowBlock

# Global variables to be set.
var raycast: RayCast3D
var player = null

#Power stuff
var powered := false
var _input_sources: Array[NodePath] = []
var _true_output_path: NodePath = NodePath()

# conditional variables
var var1_name: String = ""
var var2_name: String = ""
var compare: String = ">"

# Variable to prevent block breaking.
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
	
	# Disable editing for the UI (prevent changes in the block).
	menu.open_for_block(self, true)
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
	
	
# Signals
func receive_signal(run_id: int = -1, from_node: Node = null, step_id: int = 0) -> void:
	if not should_process_signal(run_id, step_id):
		return
	if from_node == null:
		return
	var source_path := get_path_to(from_node)
	if not _input_sources.has(source_path):
		_input_sources.append(source_path)
	flash_signal()
	powered = true
	if evaluate():
		_emit_signal_to_outputs(run_id, from_node, step_id)
		
func _emit_signal_to_outputs(run_id: int, from_node: Node = null, step_id: int = 0) -> void:
	var target := _resolve_true_output_target(from_node)
	if target == null:
		return
	if SIGNAL_HOP_DELAY > 0.0:
		await get_tree().create_timer(SIGNAL_HOP_DELAY).timeout
	target.call_deferred("receive_signal", run_id, self, step_id + 1)

func _resolve_true_output_target(from_node: Node = null) -> Node3D:
	# Reuse existing sticky target when still valid and still a legal true output.
	if _true_output_path != NodePath():
		var cached := get_node_or_null(_true_output_path) as Node3D
		if _is_valid_true_output(cached, from_node):
			return cached

	# Otherwise pick a deterministic target from current legal candidates.
	var candidates: Array[Node3D] = []
	var all_nodes = get_tree().get_nodes_in_group("signal_nodes")
	for node in all_nodes:
		if not node is Node3D:
			continue
		var node_3d := node as Node3D
		if _is_valid_true_output(node_3d, from_node):
			candidates.append(node_3d)

	if candidates.is_empty():
		_true_output_path = NodePath()
		return null

	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return str(a.get_path()) < str(b.get_path())
	)

	var chosen := candidates[0]
	_true_output_path = get_path_to(chosen)
	return chosen

func _is_valid_true_output(node_3d: Node3D, from_node: Node = null) -> bool:
	if node_3d == null:
		return false
	if node_3d == self:
		return false
	if from_node != null and node_3d == from_node:
		return false
	if not node_3d.has_method("receive_signal"):
		return false
	if not is_adjacent(node_3d):
		return false
	# Never emit to learned input-source sides.
	var node_path := get_path_to(node_3d)
	if _input_sources.has(node_path):
		return false
	return true

func reset_signal_state() -> void:
	super.reset_signal_state()
	_input_sources.clear()
	_true_output_path = NodePath()
		
			
	
			
