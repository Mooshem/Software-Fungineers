class_name FlowBlock
extends BreakableBlock

const SIGNAL_HOP_DELAY := 0.25
static var _next_run_id: int = 1
var _last_run_id_processed: int = -1
var _last_signal_key: String = ""

static func claim_next_run_id() -> int:
	var run_id := _next_run_id
	_next_run_id += 1
	return run_id

func _ready() -> void:
	super._ready()
	add_to_group("signal_nodes")
	call_deferred("_notify_adjacent_wires")

func _notify_adjacent_wires() -> void:
	var all_nodes = get_tree().get_nodes_in_group("signal_nodes")
	for node in all_nodes:
		if node == self:
			continue
		if not node is Node3D:
			continue
		var node_3d := node as Node3D
		
		# Check if the next node is a wire and is adjacent.
		if node_3d.has_method("initialize_connections") and node_3d.has_method("is_adjacent"):
			if node_3d.call("is_adjacent", self):
				node_3d.call("initialize_connections")
	
func request_connection(requester: Node3D) -> bool:
	return true

func is_adjacent(node: Node3D) -> bool:
	var delta := node.global_position - global_position
	delta.y = 0
	var t := 0.1
	return (
		(abs(delta.x - 1.0) < t and abs(delta.z) < t) or
		(abs(delta.x + 1.0) < t and abs(delta.z) < t) or
		(abs(delta.z - 1.0) < t and abs(delta.x) < t) or
		(abs(delta.z + 1.0) < t and abs(delta.x) < t)
	)

func emit_signal_to_adjacent() -> void:
	emit_signal_to_adjacent_with_run(-1, null, 0)

func emit_signal_to_adjacent_with_run(run_id: int, from_node: Node = null, step_id: int = 0) -> void:
	var all_nodes = get_tree().get_nodes_in_group("signal_nodes")
	for node in all_nodes:
		if node == self:
			continue
		if from_node != null and node == from_node:
			continue
		if not node is Node3D:
			continue
		var node_3d := node as Node3D
		if not node_3d.has_method("receive_signal"):
			continue
		if is_adjacent(node_3d):
			if SIGNAL_HOP_DELAY > 0.0:
				await get_tree().create_timer(SIGNAL_HOP_DELAY).timeout
			node_3d.call_deferred("receive_signal", run_id, self, step_id + 1)

func should_process_run(run_id: int) -> bool:
	if run_id < 0:
		return true
	if _last_run_id_processed == run_id:
		return false
	_last_run_id_processed = run_id
	return true

func should_process_signal(run_id: int, step_id: int) -> bool:
	var key := "%d:%d" % [run_id, step_id]
	if _last_signal_key == key:
		return false
	_last_signal_key = key
	return true

func reset_signal_state() -> void:
	_last_run_id_processed = -1
	_last_signal_key = ""
	for property in get_property_list():
		if property is Dictionary and property.get("name", "") == "powered":
			set("powered", false)
			break

func flash_signal(mesh_path: NodePath = NodePath("MeshInstance3D"), flash_duration: float = 0.15) -> void:
	var mesh := get_node_or_null(mesh_path) as MeshInstance3D
	if mesh == null:
		return
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	var base := mat.albedo_color
	mat.albedo_color = base.lerp(Color(0.2, 1.0, 0.2, 1.0), 0.8)
	await get_tree().create_timer(flash_duration).timeout
	mat.albedo_color = base
