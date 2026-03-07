"""
Developer: Coding Cubed Team
Start block: entry point that injects a signal into the flow graph
when the player interacts with it.
"""

extends FlowBlock

var raycast: RayCast3D
var player: Node = null
var _primary_output_path: NodePath = NodePath()

# Variable to prevent block breaking.
var is_locked: bool = true

@onready var _mesh: MeshInstance3D = $MeshInstance3D
var _base_color: Color = Color(0.9, 0.2, 0.2, 1.0)

func _ready() -> void:
	# FlowBlock handles breakable + signal_nodes membership + wire adjacency.
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
			mat.albedo_color = Color(0.351, 0.0, 0.057, 1.0)
			mesh.material_override = mat
	
	# Cache the starting material color for later restores.
	if _mesh and _mesh.material_override is StandardMaterial3D:
		var mat := _mesh.material_override as StandardMaterial3D
		_base_color = mat.albedo_color

func _unhandled_input(event: InputEvent) -> void:
	# Let the player trigger the start block by looking at it and pressing interact.
	if not raycast or not raycast.is_colliding():
		return
	if raycast.get_collider() != self:
		return
	if Input.is_action_just_pressed("interact"):
		receive_signal()

func receive_signal(run_id: int = -1, from_node: Node = null, step_id: int = 0) -> void:
	# Start block is a source node: only explicit interaction should start a run.
	# If a neighbor tries to signal back into Start, ignore it to prevent bounce loops.
	if run_id >= 0:
		return
	run_id = FlowBlock.claim_next_run_id()
	# Reset previous powered state so each interaction can run the graph again.
	_reset_signal_power_state()
	# Quick visual flash to show activation.
	_flash_visual()
	# Emit only through the cached primary output target for deterministic direction.
	var output_target := _resolve_primary_output_target()
	if output_target == null:
		return
	if SIGNAL_HOP_DELAY > 0.0:
		await get_tree().create_timer(SIGNAL_HOP_DELAY).timeout
	output_target.call_deferred("receive_signal", run_id, self, step_id + 1)

func _flash_visual() -> void:
	if _mesh == null:
		return
	var mat := _mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	# Set to bright green briefly, then restore base color.
	mat.albedo_color = Color(0.2, 1.0, 0.2, 1.0)
	await get_tree().create_timer(0.2).timeout
	mat.albedo_color = _base_color

func _reset_signal_power_state() -> void:
	var all_nodes = get_tree().get_nodes_in_group("signal_nodes")
	for node in all_nodes:
		if node.has_method("reset_signal_state"):
			node.call("reset_signal_state")
		else:
			for property in node.get_property_list():
				if property is Dictionary and property.get("name", "") == "powered":
					node.set("powered", false)
					break

func _resolve_primary_output_target() -> Node3D:
	# Reuse the previously selected output if it still exists and stays adjacent.
	if _primary_output_path != NodePath():
		var cached := get_node_or_null(_primary_output_path) as Node3D
		if cached != null and is_instance_valid(cached) and is_adjacent(cached) and cached.has_method("receive_signal"):
			return cached

	# Otherwise choose a deterministic first adjacent signal node and cache it.
	var candidates: Array[Node3D] = []
	var all_nodes = get_tree().get_nodes_in_group("signal_nodes")
	for node in all_nodes:
		if node == self:
			continue
		if not node is Node3D:
			continue
		var node_3d := node as Node3D
		if not node_3d.has_method("receive_signal"):
			continue
		if is_adjacent(node_3d):
			candidates.append(node_3d)

	if candidates.is_empty():
		_primary_output_path = NodePath()
		return null

	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return str(a.get_path()) < str(b.get_path())
	)

	var chosen := candidates[0]
	_primary_output_path = get_path_to(chosen)
	return chosen
