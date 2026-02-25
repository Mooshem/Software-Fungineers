###
# Cash Limberg
###

extends Node3D

const MAX_CONNECTIONS := 2
var connections: Array[Node3D] = []
var powered := false
var preferred_dir := Vector3.ZERO

var _end_base_rot: Vector3
var _straight_base_rot: Vector3
var _corner_base_rot: Vector3

func _ready():
	add_to_group("signal_nodes")
	_end_base_rot = $wire_end.rotation_degrees
	_straight_base_rot = $wire_straight.rotation_degrees
	_corner_base_rot = $wire_corner.rotation_degrees
	call_deferred("initialize_connections")

# =========================
# CONNECTION DISCOVERY
# =========================

func initialize_connections():
	"""
	Only the newly placed wire drives connection building.
	It finds adjacent wires that still have room, links both sides,
	then tells neighbors to refresh their visuals only.
	"""
	var all_nodes = get_tree().get_nodes_in_group("signal_nodes")
	var priority_nodes: Array[Node3D] = []
	var other_nodes: Array[Node3D] = []

	for node in all_nodes:
		if not node is Node3D:
			continue
		var node_3d := node as Node3D
		if node_3d == self or connections.has(node_3d):
			continue
		if not is_adjacent(node_3d):
			continue
		if preferred_dir != Vector3.ZERO and _get_grid_dir_to(node_3d).dot(preferred_dir) > 0.5:
			priority_nodes.append(node_3d)
		else:
			other_nodes.append(node_3d)

	_try_connect_candidates(priority_nodes)
	_try_connect_candidates(other_nodes)

	update_visuals()

	# Tell neighbors to redraw now that connections are settled
	for node in connections:
		if node.has_method("refresh_visuals"):
			node.refresh_visuals()

func request_connection(requester: Node3D) -> bool:
	"""
	Called by a newly placed neighbor asking to connect.
	Returns true and adds the connection if there's room.
	Never triggers a recursive scan — only updates visuals.
	"""
	if connections.size() >= MAX_CONNECTIONS:
		return false
	if connections.has(requester):
		return false
	connections.append(requester)
	return true

func refresh_visuals():
	"""Called externally to redraw after connections change."""
	update_visuals()

func set_preferred_dir(raw_dir: Vector3) -> void:
	var flat_dir := raw_dir
	flat_dir.y = 0
	if flat_dir.length_squared() < 0.0001:
		preferred_dir = Vector3.ZERO
		return
	if abs(flat_dir.x) > abs(flat_dir.z):
		preferred_dir = Vector3(sign(flat_dir.x), 0, 0)
	else:
		preferred_dir = Vector3(0, 0, sign(flat_dir.z))
	update_visuals()

func is_adjacent(node: Node3D) -> bool:
	var delta = node.global_position - global_position
	delta.y = 0
	var t = 0.1
	return (
		(abs(delta.x - 1.0) < t and abs(delta.z) < t) or
		(abs(delta.x + 1.0) < t and abs(delta.z) < t) or
		(abs(delta.z - 1.0) < t and abs(delta.x) < t) or
		(abs(delta.z + 1.0) < t and abs(delta.x) < t)
	)

# =========================
# SIGNAL PROPAGATION
# =========================

func receive_signal():
	if powered:
		return
	powered = true
	for node in connections:
		if node.has_method("receive_signal"):
			node.call_deferred("receive_signal")

# =========================
# VISUALS
# =========================

func update_visuals():
	$wire_end.visible = false
	$wire_straight.visible = false
	$wire_corner.visible = false

	match connections.size():
		0:
			$wire_end.visible = true
			if preferred_dir == Vector3.ZERO:
				$wire_end.rotation_degrees = _end_base_rot
			else:
				_rotate_end_toward(preferred_dir)

		1:
			$wire_end.visible = true
			_rotate_end()

		2:
			var d1 = _get_grid_dir_to(connections[0])
			var d2 = _get_grid_dir_to(connections[1])
			if d1.dot(d2) < -0.5:
				$wire_straight.visible = true
				_rotate_straight(d1)
			else:
				$wire_corner.visible = true
				_rotate_corner(d1, d2)

# =========================
# DIRECTION HELPERS
# =========================

func _get_grid_dir_to(node: Node3D) -> Vector3:
	var delta = node.global_position - global_position
	delta.y = 0
	if abs(delta.x) > abs(delta.z):
		return Vector3(sign(delta.x), 0, 0)
	else:
		return Vector3(0, 0, sign(delta.z))

func _dir_key(dir: Vector3) -> String:
	return "%d,%d" % [int(dir.x), int(dir.z)]

# =========================
# ROTATION
# =========================

func _rotate_end():
	var grid_dir = _get_grid_dir_to(connections[0])
	_rotate_end_toward(grid_dir)

func _rotate_end_toward(grid_dir: Vector3):
	var y_offset: float
	match _dir_key(grid_dir):
		"0,1":  y_offset = 0.0
		"1,0":  y_offset = 90.0
		"0,-1": y_offset = 180.0
		"-1,0": y_offset = 270.0
		_:      y_offset = 0.0
	$wire_end.rotation_degrees = Vector3(_end_base_rot.x, _end_base_rot.y + y_offset, _end_base_rot.z)

func _rotate_straight(d1: Vector3):
	var y_offset = 90.0 if abs(d1.x) > 0.5 else 0.0
	$wire_straight.rotation_degrees = Vector3(_straight_base_rot.x, _straight_base_rot.y + y_offset, _straight_base_rot.z)

func _rotate_corner(d1: Vector3, d2: Vector3):
	var k1 = _dir_key(d1)
	var k2 = _dir_key(d2)
	var combined = (k1 + "|" + k2) if k1 < k2 else (k2 + "|" + k1)
	var y_offset: float
	match combined:
		"0,1|1,0":   y_offset = 0.0
		"0,-1|1,0":  y_offset = 90.0
		"-1,0|0,-1": y_offset = 180.0
		"-1,0|0,1":  y_offset = 270.0
		_:
			y_offset = 0.0
			print("Wire: unhandled corner: ", combined)
	$wire_corner.rotation_degrees = Vector3(_corner_base_rot.x, _corner_base_rot.y + y_offset, _corner_base_rot.z)

func _try_connect_candidates(candidates: Array[Node3D]) -> void:
	for node in candidates:
		if connections.size() >= MAX_CONNECTIONS:
			return
		if not node.has_method("request_connection"):
			continue
		if node.call("request_connection", self):
			connections.append(node)
