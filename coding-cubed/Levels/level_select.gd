extends Control

const MAIN_MENU_SCENE := "res://Levels/main_menu.tscn"
const SANDBOX_SCENE := "res://Levels/sandbox.tscn"
const FADE_DURATION := 0.25

@onready var notice_label: Label = $Center/Panel/VBox/Notice
@onready var fade_overlay: ColorRect = $FadeOverlay
var _is_transitioning: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_fade_in()
	$Center/Panel/VBox/LevelOneButton.grab_focus()

func _on_level_one_button_pressed() -> void:
	_transition_to_scene(SANDBOX_SCENE)

func _on_level_two_button_pressed() -> void:
	notice_label.text = "Level 2 is a placeholder for now."

func _on_back_button_pressed() -> void:
	_transition_to_scene(MAIN_MENU_SCENE)

func _fade_in() -> void:
	fade_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, FADE_DURATION)

func _transition_to_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
