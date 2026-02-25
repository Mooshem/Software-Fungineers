extends GutTest

# Every test function must start with 'test_'

var player_scene = preload("res://Player/player.tscn")  # adjust path if needed
var player

#Example test that should always pass to make sure testing flow works
func test_example():
	assert_eq(1 + 1, 2, "1 + 1 = 2")

func before_each():
	player = CharacterBody3D.new()
	player.set_script(preload("res://Player/player.gd"))
	
	# Add required child nodes
	var head = Node3D.new()
	head.name = "Head"
	
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	head.add_child(camera)
	
	var ray = RayCast3D.new()
	ray.name = "RayCast3D"
	camera.add_child(ray)

	player.add_child(head)
	
	# Hotbar is trickier since it's a UI node under a CanvasLayer
	var canvas = CanvasLayer.new()
	canvas.name = "CanvasLayer"
	var hotbar = HBoxContainer.new()
	hotbar.name = "Hotbar"
	canvas.add_child(hotbar)
	player.add_child(canvas)
	
	add_child_autofree(player)

func test_initial_hotbar_slot():
	assert_eq(player.selected_slot, 0, "Player should start on slot 0")
	
func test_set_hotbar_slot():
	player.set_hotbar_slot(1)
	assert_eq(player.selected_slot, 1, "Slot should be set to 1")

func test_set_hotbar_slot_clamps_below_zero():
	player.set_hotbar_slot(-1)
	assert_eq(player.selected_slot, 0, "Slot should clamp to 0")

func test_set_hotbar_slot_clamps_above_max():
	player.set_hotbar_slot(99)
	assert_eq(player.selected_slot, player.HOTBAR_SLOT_COUNT - 1, "Slot should clamp to max")

func test_change_hotbar_slot_increments():
	player.selected_slot = 0
	player.change_hotbar_slot(1)
	assert_eq(player.selected_slot, 1, "Slot should increment by 1")

func test_change_hotbar_slot_wraps_forward():
	player.selected_slot = 2
	player.change_hotbar_slot(1)
	assert_eq(player.selected_slot, 0, "Slot should wrap around to 0")

func test_change_hotbar_slot_wraps_backward():
	player.selected_slot = 0
	player.change_hotbar_slot(-1)
	assert_eq(player.selected_slot, player.HOTBAR_SLOT_COUNT - 1, "Slot should wrap to max")
