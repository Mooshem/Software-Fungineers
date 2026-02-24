extends Control

const LEVEL_SELECT_SCENE := "res://Levels/level_select.tscn"
const SANDBOX_SCENE := "res://Levels/sandbox.tscn"
const FADE_DURATION := 0.25
const BACKGROUND_YAW_SPEED := 0.12
const BACKGROUND_SWAY_SPEED := 0.8
const BACKGROUND_SWAY_AMOUNT := 0.08

@onready var levels_button: Button = $MenuRoot/Panel/VBox/LevelsButton
@onready var sandbox_button: Button = $MenuRoot/Panel/VBox/SandboxButton
@onready var settings_button: Button = $MenuRoot/Panel/VBox/SettingsButton
@onready var quit_button: Button = $MenuRoot/Panel/VBox/QuitButton
@onready var settings_notice: Label = $MenuRoot/SettingsNotice
@onready var notice_timer: Timer = $NoticeTimer
@onready var hover_sfx: AudioStreamPlayer = $HoverSfx
@onready var click_sfx: AudioStreamPlayer = $ClickSfx
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var background_player: CharacterBody3D = $BackgroundViewportContainer/SubViewport/BackgroundWorld/Player
@onready var background_head: Node3D = $BackgroundViewportContainer/SubViewport/BackgroundWorld/Player/Head
@onready var background_player_ui: CanvasLayer = $BackgroundViewportContainer/SubViewport/BackgroundWorld/Player/CanvasLayer

var _is_transitioning: bool = false
var _camera_time: float = 0.0
var _base_head_rotation_x: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_wire_button_effects(levels_button)
	_wire_button_effects(sandbox_button)
	_wire_button_effects(settings_button)
	_wire_button_effects(quit_button)
	if background_player_ui != null:
		background_player_ui.visible = false
	if background_head != null:
		_base_head_rotation_x = background_head.rotation.x
	_fade_in()
	levels_button.grab_focus()

func _process(delta: float) -> void:
	_camera_time += delta
	if background_player != null:
		background_player.rotation.y += BACKGROUND_YAW_SPEED * delta
	if background_head != null:
		background_head.rotation.x = _base_head_rotation_x + sin(_camera_time * BACKGROUND_SWAY_SPEED) * BACKGROUND_SWAY_AMOUNT

func _wire_button_effects(button: Button) -> void:
	_center_button_pivot(button)
	button.resized.connect(func() -> void:
		_center_button_pivot(button)
	)
	button.mouse_entered.connect(func() -> void:
		_play_hover_sfx()
		_animate_button_scale(button, Vector2(1.05, 1.05))
	)
	button.mouse_exited.connect(func() -> void:
		_animate_button_scale(button, Vector2.ONE)
	)
	button.pressed.connect(func() -> void:
		_play_click_sfx()
	)

func _animate_button_scale(button: Button, target_scale: Vector2) -> void:
	_center_button_pivot(button)
	var tween := create_tween()
	tween.tween_property(button, "scale", target_scale, 0.1)

func _center_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5

func _play_hover_sfx() -> void:
	if hover_sfx.stream != null:
		hover_sfx.play()

func _play_click_sfx() -> void:
	if click_sfx.stream != null:
		click_sfx.play()

func _on_levels_button_pressed() -> void:
	_transition_to_scene(LEVEL_SELECT_SCENE)

func _on_sandbox_button_pressed() -> void:
	_transition_to_scene(SANDBOX_SCENE)

func _on_settings_button_pressed() -> void:
	settings_notice.visible = true
	notice_timer.start()

func _on_quit_button_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished
	get_tree().quit()

func _on_notice_timer_timeout() -> void:
	settings_notice.visible = false

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
