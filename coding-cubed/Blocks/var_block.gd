"""
Developer: Donovan Thach
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends StaticBody3D

var raycast: RayCast3D

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var raycast = player.get_node("Head/Camera3D/Raycast3D")


func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	handle_user_interaction(event)
	pass
	
func handle_user_interaction(event: InputEvent) -> void:
	var target_block = raycast.get_collider()
	if !raycast:
		return
	else:
		if Input.is_action_just_pressed("interact") and target_block.scene_file_path == "Block/var_block.tscn":
			print("Working")
			return
	pass
