"""
Developer: Donovan Thach
Documentation on gdScripts: https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
							https://docs.godotengine.org/en/4.4/classes/class_characterbody3d.html#description
							https://docs.godotengine.org/en/4.4/classes/class_canvaslayer.html
							https://docs.godotengine.org/en/4.4/classes/class_collisionshape3d.html
							https://docs.godotengine.org/en/4.4/tutorials/physics/collision_shapes_3d.html#primitive-collision-shapes
							https://docs.godotengine.org/en/4.4/tutorials/animation/animation_track_types.html#position-3d-rotation-3d-scale-3d-track
"""

extends CharacterBody3D

# References the Head node created in the scene.
@onready var head: Node3D = $Head

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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Exit mouse capture when UI Cancel (usually Escape) is pressed.
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Direction is now calculated relative to the character's current Y rotation.
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
