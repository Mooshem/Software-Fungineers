extends Control

const MAIN_MENU_SCENE := "res://Levels/main_menu.tscn"

const SETTINGS_MASTER_VOLUME_KEY := "game/settings/master_volume"
const SETTINGS_MUSIC_ENABLED_KEY := "game/settings/music_enabled"
const SETTINGS_HOTBAR_SCALE_KEY := "game/settings/hotbar_scale"

const FADE_DURATION := 0.25

@onready var master_volume_slider: HSlider = $MenuRoot/Panel/VBox/MasterVolumeHBox/MasterVolumeSlider
@onready var music_check_box: CheckBox = $MenuRoot/Panel/VBox/MusicHBox/MusicCheckBox
@onready var hotbar_size_option: OptionButton = $MenuRoot/Panel/VBox/HotbarSizeHBox/HotbarSizeOption
@onready var fade_overlay: ColorRect = $FadeOverlay

var _is_transitioning: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_init_hotbar_size_options()
	_load_settings()
	_fade_in()

func _init_hotbar_size_options() -> void:
	hotbar_size_option.clear()
	hotbar_size_option.add_item("Small", 0)
	hotbar_size_option.add_item("Medium", 1)
	hotbar_size_option.add_item("Large", 2)

func _load_settings() -> void:
	var master_volume: float = float(ProjectSettings.get_setting(SETTINGS_MASTER_VOLUME_KEY, 1.0))
	if typeof(master_volume) != TYPE_FLOAT:
		master_volume = 1.0
	master_volume_slider.value = clamp(master_volume, 0.0, 1.0)

	var music_enabled: bool = bool(ProjectSettings.get_setting(SETTINGS_MUSIC_ENABLED_KEY, true))
	if typeof(music_enabled) != TYPE_BOOL:
		music_enabled = true
	music_check_box.button_pressed = music_enabled

	var hotbar_scale: float = float(ProjectSettings.get_setting(SETTINGS_HOTBAR_SCALE_KEY, 1.0))
	if typeof(hotbar_scale) != TYPE_FLOAT:
		hotbar_scale = 1.0
	var index := 1
	if hotbar_scale <= 0.9:
		index = 0
	elif hotbar_scale >= 1.1:
		index = 2
	hotbar_size_option.select(index)

	_apply_master_volume(master_volume_slider.value)
	_apply_music_enabled(music_check_box.button_pressed)

func _save_setting(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save()

func _apply_master_volume(value: float) -> void:
	var safe_value: float = clampf(value, 0.0, 1.0)
	var db_value: float = lerpf(-30.0, 0.0, safe_value)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus != -1:
		AudioServer.set_bus_volume_db(master_bus, db_value)

func _apply_music_enabled(enabled: bool) -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_mute(music_bus, not enabled)

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

func _on_master_volume_value_changed(value: float) -> void:
	_apply_master_volume(value)
	_save_setting(SETTINGS_MASTER_VOLUME_KEY, value)

func _on_music_check_box_toggled(button_pressed: bool) -> void:
	_apply_music_enabled(button_pressed)
	_save_setting(SETTINGS_MUSIC_ENABLED_KEY, button_pressed)

func _on_hotbar_size_option_item_selected(index: int) -> void:
	var scale := 1.0
	if index == 0:
		scale = 0.85
	elif index == 2:
		scale = 1.2
	_save_setting(SETTINGS_HOTBAR_SCALE_KEY, scale)

func _on_back_button_pressed() -> void:
	_transition_to_scene(MAIN_MENU_SCENE)

