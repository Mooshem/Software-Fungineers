"""
Developer: Donovan Thach
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends StaticBody3D

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var raycast = player.get_node("Head/Camera3D/Raycast3D")


func _process(delta: float) -> void:
	
	pass
