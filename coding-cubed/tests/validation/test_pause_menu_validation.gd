extends GutTest

const PLAYER_SCENE := preload("res://Player/player.tscn")

var _player: CharacterBody3D

func before_each() -> void:
	_player = PLAYER_SCENE.instantiate()
	get_tree().root.add_child(_player)

func after_each() -> void:
	# Reset global engine state mutated by pause/resume behavior.
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(_player):
		_player.queue_free()
		_player = null

func test_pause_toggle_opens_overlay_and_pauses_game() -> void:
	_player._toggle_pause_menu()

	assert_true(_player._is_pause_menu_open(), "Pause menu should become visible when toggled open.")
	assert_true(get_tree().paused, "Tree should be paused while pause menu is open.")
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE, "Mouse should be released to interact with pause UI.")

func test_pause_toggle_twice_resumes_game_and_hides_overlay() -> void:
	_player._toggle_pause_menu()
	_player._toggle_pause_menu()

	assert_false(_player._is_pause_menu_open(), "Pause menu should close when toggled again.")
	assert_false(get_tree().paused, "Tree should resume when pause menu closes.")
	# In headless CI, mouse capture is unavailable and remains visible.
	# In desktop runtime, gameplay should recapture the mouse.
	if DisplayServer.get_name() == "headless":
		assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE, "Headless CI keeps mouse mode visible.")
	else:
		assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_CAPTURED, "Mouse should be recaptured for gameplay on resume.")

func test_settings_placeholder_message_can_show_and_hide() -> void:
	_player._pause_game()
	_player._on_settings_button_pressed()
	assert_true(_player.pause_settings_notice.visible, "Settings placeholder label should appear when Settings is pressed.")

	_player._on_pause_notice_timer_timeout()
	assert_false(_player.pause_settings_notice.visible, "Settings placeholder label should hide when notice timer completes.")
