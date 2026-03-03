class_name FlowBlock
extends StaticBody3D

func _ready() -> void:
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
