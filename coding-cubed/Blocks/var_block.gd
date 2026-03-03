"""
Developer: Donovan Thach, Daniel Martin
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends BreakableBlock

# Global variables to be set.
var raycast: RayCast3D
var var_name: String = ""
var var_val: String = ""
var player = null

func _ready() -> void:
	add_to_group("signal_nodes")
	call_deferred("_notify_adjacent_wires")
	super._ready()
	# Add to searchable list for other blocks.
	add_to_group("var_blocks")
	# Get the player node from Player scene.
	player = get_tree().get_first_node_in_group("player")
	if player:
		# Get the raycast from the player object.
		raycast = player.get_node("Head/Camera3D/RayCast3D")
		
func _unhandled_input(event: InputEvent) -> void:
	# If raycast doesn't exist, return.
	if !raycast or !raycast.is_colliding():
		return
	# If colliding object isn't var_block on raycast, then return.
	if raycast.get_collider() != self:
		return
	# If player interacts with block, open player menu.
	if Input.is_action_just_pressed("interact"):
		_open_player_menu()
		
func _open_player_menu() -> void:
	# Don't open if player object doesn't exist.
	if !player:
		return
		
	# Get the menu of the variable block open.
	var menu = player.get_node("CanvasLayer/VariableBlockMenu")
	menu.open_for_block(self)
<<<<<<< HEAD
	get_tree().paused = true
=======
	
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
>>>>>>> origin/main
