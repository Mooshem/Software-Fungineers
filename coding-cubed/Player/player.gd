"""
Developers: Donovan Thach, Cash Limberg
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
				https://docs.godotengine.org/en/4.4/classes/class_characterbody3d.html#description
				https://docs.godotengine.org/en/4.4/classes/class_canvaslayer.html
				https://docs.godotengine.org/en/4.4/classes/class_collisionshape3d.html
				https://docs.godotengine.org/en/4.4/tutorials/physics/collision_shapes_3d.html#primitive-collision-shapes
				https://docs.godotengine.org/en/4.4/tutorials/animation/animation_track_types.html#position-3d-rotation-3d-scale-3d-track
"""

extends CharacterBody3D

# References the Head node created in the scene.
@onready var head: Node3D = $Head
# Added by: Cash Limberg. 
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hotbar: HBoxContainer = $CanvasLayer/Hotbar
var BlockScene = preload("res://Blocks/block.tscn")

# Game modifiers for movement, jumping, and direction.
const SPEED = 5.0
const JUMP_VELOCITY = 5.5
const MOUSE_SENSITIVITY = 0.003
const HOTBAR_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.75, 0.95, 1.0, 1.0),
	Color(1.0, 0.82, 0.65, 1.0)
]
const HOTBAR_SLOT_COUNT: int = 3

# Timer used to sense how long left click is held.
var BREAK_TIMER: float = 0.0
# How long is required to break a block.
var BREAK_TIME: float = 0.75
var selected_slot: int = 0

func _ready() -> void:
	"""
	Capture the mouse cursor to prevent it from leaving the game window.
	"""
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_hotbar_visuals()

func _unhandled_input(event: InputEvent) -> void:
	"""
	Handle inputs from mouse rotation to change directional camera view.
	"""
	# Handle mouse motion for camera rotation.
	if event is InputEventMouseMotion:
		# Rotate the CharacterBody3D around the Y-axis (left/right).
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Rotate the Head node around the X-axis (up/down).
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		# Clamp the vertical rotation to prevent the camera from flipping over.
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_hotbar_slot(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_hotbar_slot(1)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_set_hotbar_slot(0)
		elif event.keycode == KEY_2:
			_set_hotbar_slot(1)
		elif event.keycode == KEY_3:
			_set_hotbar_slot(2)

	# Code added by: Cash Limberg
	if Input.is_action_just_pressed("place_block"):
		if ray.is_colliding():
			# Variables that contain information on where the player was looking at the time.
			var hit_position = ray.get_collision_point()
			var hit_normal = ray.get_collision_normal()

			# Takes the values of where the raycast saw the click occur to determine block placement.
			var place_position = Vector3(
				floor(hit_position.x + hit_normal.x * 0.5),
				floor(hit_position.y + hit_normal.y * 0.5),
				floor(hit_position.z + hit_normal.z * 0.5)
			)
			
			# Variables that contain information on player's position at the feet and head.
			var player_position = self.global_position.floor()
			var player_head_position = (self.global_position + Vector3(0, 1, 0)).floor()
			
			# If block is in player, don't place.
			if player_position != place_position and player_head_position != place_position:
				var block = BlockScene.instantiate()
				_apply_block_variant(block, selected_slot)
				block.set_meta("hotbar_slot", selected_slot)
				get_parent().add_child(block)
				block.global_position = place_position

"""
CODE GRAVEYARD

"""

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("break_block"):
		# Incrememt the timer using frames.
		BREAK_TIMER += delta
		
		if BREAK_TIMER >= BREAK_TIME and ray.is_colliding():
			# Get the target block.
			var target_block = ray.get_collider()
			if target_block and target_block.scene_file_path == "res://Blocks/block.tscn":
				# Remove the block from the current scene.
				target_block.queue_free()
				BREAK_TIMER = 0.0
	else:
		# Resets break timer.
		BREAK_TIMER = 0.0
			
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Maintain jumping while player is holding spacebar.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Exit mouse capture when UI Cancel (usually Escape) is pressed.
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Direction is now calculated relative to the character's current Y rotation.
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Running just doubles speed, done by holding down shift.
		if Input.is_action_pressed("running"):
			velocity.x = direction.x * SPEED * 2
			velocity.z = direction.z * SPEED * 2
		else:
			# Prevents player from sliding (temporary).
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _change_hotbar_slot(direction: int) -> void:
	selected_slot = posmod(selected_slot + direction, HOTBAR_SLOT_COUNT)
	_update_hotbar_visuals()

func _set_hotbar_slot(slot_index: int) -> void:
	selected_slot = clamp(slot_index, 0, HOTBAR_SLOT_COUNT - 1)
	_update_hotbar_visuals()

func _update_hotbar_visuals() -> void:
	if hotbar == null:
		return

	for i in range(hotbar.get_child_count()):
		var slot_panel := hotbar.get_child(i) as Panel
		if slot_panel == null:
			continue
		if i == selected_slot:
			slot_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			slot_panel.modulate = Color(0.65, 0.65, 0.65, 1.0)

func _apply_block_variant(block: Node, slot_index: int) -> void:
	var mesh_instance := block.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		return

	var source_material: Material = mesh_instance.get_active_material(0)
	if source_material == null and mesh_instance.mesh != null:
		source_material = mesh_instance.mesh.surface_get_material(0)

	var variant_material: StandardMaterial3D
	if source_material is StandardMaterial3D:
		variant_material = source_material.duplicate() as StandardMaterial3D
	else:
		variant_material = StandardMaterial3D.new()

	variant_material.albedo_color = HOTBAR_COLORS[slot_index]
	mesh_instance.material_override = variant_material
