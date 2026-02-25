extends GutTest

const SANDBOX_SCENE := preload("res://Levels/sandbox.tscn")
const MAIN_MENU_SCENE := preload("res://Levels/main_menu.tscn")

var _sandbox: Node
var _menu: Control

func before_each() -> void:
	_sandbox = SANDBOX_SCENE.instantiate()
	get_tree().root.add_child(_sandbox)
	_menu = MAIN_MENU_SCENE.instantiate()
	get_tree().root.add_child(_menu)

func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(_sandbox):
		_sandbox.queue_free()
		_sandbox = null
	if is_instance_valid(_menu):
		_menu.queue_free()
		_menu = null

func test_sandbox_scene_has_player_with_pause_menu_nodes() -> void:
	var player := _sandbox.get_node_or_null("Player")
	assert_not_null(player, "Sandbox scene should contain a Player instance.")

	assert_not_null(player.get_node_or_null("CanvasLayer/PauseMenu"), "Pause menu overlay should be wired into player UI.")
	assert_not_null(player.get_node_or_null("CanvasLayer/PauseFadeOverlay"), "Pause fade overlay should exist for transitions.")
	assert_not_null(player.get_node_or_null("CanvasLayer/PauseNoticeTimer"), "Pause settings timer should exist.")

func test_main_menu_disables_background_player_processing() -> void:
	assert_not_null(_menu.background_player, "Main menu background should include sandbox Player reference.")
	assert_eq(
		_menu.background_player.process_mode,
		Node.PROCESS_MODE_DISABLED,
		"Background player should be disabled to prevent input/pause side effects in menu."
	)

func test_main_menu_settings_notice_visibility_flow() -> void:
	_menu._on_settings_button_pressed()
	assert_true(_menu.settings_notice.visible, "Pressing Settings in main menu should show placeholder notice.")
	assert_true(_menu.notice_timer.time_left > 0.0, "Notice timer should start after Settings is pressed.")

	_menu._on_notice_timer_timeout()
	assert_false(_menu.settings_notice.visible, "Notice should hide when timer callback runs.")
