"""
Developer: Donovan Thach
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
var BlockScene = preload("res://block.tscn")



const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

func _ready() -> void:
	# Capture the mouse cursor to prevent it from leaving the game window.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse motion for camera rotation.
	if event is InputEventMouseMotion:
		# Rotate the CharacterBody3D around the Y-axis (left/right).
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Rotate the Head node around the X-axis (up/down).
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		# Clamp the vertical rotation to prevent the camera from flipping over.
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

		# Code added by: Cash Limberg
		#This below if is for placing blocks
		if Input.is_action_just_pressed("place_block"):
			if ray.is_colliding():
				var hit_position = ray.get_collision_point()
				var hit_normal = ray.get_collision_normal()

				# Offset outward from surface
				var place_position = hit_position + hit_normal
				
				# Snap to whole numbers for grid alignment
				place_position = place_position.round()

				var block = BlockScene.instantiate()
				block.global_position = place_position

				get_tree().current_scene.add_child(block)


func _physics_process(delta: float) -> void:
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
