"""
Developer
"""

extends FlowBlock

var raycast: RayCast3D
var var_name: String = ""
var var_val: String = ""
var player = null

func _ready() -> void:
	super._ready()
	add_to_group("var_blocks")
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
		_open_player_menu()

func _open_player_menu() -> void:
	if !player:
		return
	var menu = player.get_node("CanvasLayer/VariableBlockMenu")
	
	# Disable editing for the UI (prevent changes in the block).
	menu.open_for_block(self, true)
	get_tree().paused = true
