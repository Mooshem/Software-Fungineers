extends GutTest

const PLAYER_SCENE := preload("res://Player/player.tscn")
const BLOCK_SCENE := preload("res://Blocks/block.tscn")

var _player: CharacterBody3D

func before_each() -> void:
	_player = PLAYER_SCENE.instantiate()
	get_tree().root.add_child(_player)

func after_each() -> void:
	# Ensure tests do not leave global paused/input state behind.
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(_player):
		_player.queue_free()
		_player = null

func test_change_hotbar_slot_wraps_from_zero_to_last() -> void:
	_player.selected_slot = 0
	_player.change_hotbar_slot(-1)
	assert_eq(_player.selected_slot, 2, "Scrolling below slot 0 should wrap to slot 2.")

func test_set_hotbar_slot_clamps_out_of_range_index() -> void:
	_player.set_hotbar_slot(99)
	assert_eq(_player.selected_slot, 2, "Slot index should clamp to the max slot.")

func test_apply_block_variant_assigns_selected_slot_color() -> void:
	var block := BLOCK_SCENE.instantiate()
	_player.apply_block_variant(block, 1)

	var mesh_instance := block.get_node_or_null("MeshInstance3D") as MeshInstance3D
	assert_not_null(mesh_instance, "Block scene should have MeshInstance3D for material override.")
	assert_not_null(mesh_instance.material_override, "Applying a block variant should set material_override.")

	var material := mesh_instance.material_override as StandardMaterial3D
	assert_not_null(material, "Override material should be StandardMaterial3D.")
	assert_eq(material.albedo_color, _player.HOTBAR_COLORS[1], "Variant color should match selected hotbar slot.")
	block.free()
