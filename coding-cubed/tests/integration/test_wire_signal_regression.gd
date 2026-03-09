extends GutTest

const PLAYER_SCENE := preload("res://Player/player.tscn")
const WIRE_SCENE := preload("res://Blocks/wire.tscn")
const START_BLOCK_SCENE := preload("res://Blocks/start_block.tscn")

var _world: Node3D
var _player: CharacterBody3D

func before_each() -> void:
	_world = Node3D.new()
	get_tree().root.add_child(_world)

	_player = PLAYER_SCENE.instantiate()
	_world.add_child(_player)

func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(_world):
		_world.queue_free()
		_world = null
		_player = null

func test_start_block_can_replace_wire_in_same_cell() -> void:
	var target_cell := Vector3(2, 0, 0)
	var wire := WIRE_SCENE.instantiate()
	_world.add_child(wire)
	wire.global_position = target_cell
	await get_tree().process_frame

	var existing := _player._get_block_at_cell(target_cell)
	assert_eq(existing, wire, "Player helper should detect the placed wire in the target cell.")
	assert_true(_player._is_wire_scene(existing), "Replacement should only be allowed when the existing block is a wire.")

	existing.queue_free()
	await get_tree().process_frame

	var start_block := START_BLOCK_SCENE.instantiate()
	_world.add_child(start_block)
	start_block.global_position = target_cell
	await get_tree().process_frame

	var occupant := _player._get_block_at_cell(target_cell)
	assert_eq(occupant, start_block, "After replacement, the start block should occupy the wire's former cell.")
	assert_false(is_instance_valid(wire), "The old wire should be gone after replacement.")

func test_wire_update_visuals_prunes_freed_connections() -> void:
	var wire := WIRE_SCENE.instantiate()
	var removed_neighbor := WIRE_SCENE.instantiate()
	_world.add_child(wire)
	_world.add_child(removed_neighbor)
	wire.global_position = Vector3.ZERO
	removed_neighbor.global_position = Vector3(10, 0, 0)
	await get_tree().process_frame

	wire.connections = [removed_neighbor]
	removed_neighbor.queue_free()
	await get_tree().process_frame

	wire.update_visuals()

	assert_eq(wire.connections.size(), 0, "Updating visuals should prune freed wire references instead of leaving stale connections behind.")
