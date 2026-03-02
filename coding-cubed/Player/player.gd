"""
Developers: Donovan Thach, Cash Limberg, Zheng Chen, Daniel Martin
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends CharacterBody3D

# Environment variables that will be initialized.
@onready var head: Node3D = $Head
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hotbar: HBoxContainer = $CanvasLayer/Hotbar
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var pause_resume_button: Button = $CanvasLayer/PauseMenu/Center/Panel/VBox/ResumeButton
@onready var pause_settings_notice: Label = $CanvasLayer/PauseMenu/Center/Panel/VBox/SettingsNotice
@onready var pause_notice_timer: Timer = $CanvasLayer/PauseNoticeTimer
@onready var pause_fade_overlay: ColorRect = $CanvasLayer/PauseFadeOverlay

# Block Menus
@onready var variable_block_menu: Control = $CanvasLayer/VariableBlockMenu
@onready var block_place_sfx: AudioStreamPlayer = $BlockPlaceSfx
@onready var block_break_sfx: AudioStreamPlayer = $BlockBreakSfx

# Captures the block scene to add to the scene when necessary.
var BlockScene = preload("res://Blocks/block.tscn")
var WireScene = preload("res://Blocks/wire.tscn")
var IfScene = preload("res://Blocks/if_block.tscn")

# Block placement sound effects.
const BLOCK_PLACE_SOUNDS: Array[AudioStream] = [
	preload("res://assets/Audio/blockplace1.mp3"),
	preload("res://assets/Audio/blockplace2.mp3"),
	preload("res://assets/Audio/blockplace3.mp3")
]
const BLOCK_BREAK_SOUND: AudioStream = preload("res://assets/Audio/blockbreak1.mp3")
const MAIN_MENU_SCENE = "res://Levels/main_menu.tscn"
const PAUSE_FADE_DURATION = 0.25

# Game modifiers for movement, jumping, and direction.
const SPEED = 5.0
const JUMP_VELOCITY = 5.5
const MOUSE_SENSITIVITY = 0.003

# Hotbar settings.
const HOTBAR_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.75, 0.95, 1.0, 1.0),
	Color(1.0, 0.82, 0.65, 1.0)
]
const HOTBAR_SLOT_COUNT: int = 3
const GRID_STEP: float = 1.0
const GRID_EPSILON: float = 0.05

# Timer used to sense how long left click is held.
var BREAK_TIMER: float = 0.0
# How long is required to break a block.
var BREAK_TIME: float = 1
var selected_slot: int = 0
var is_pause_transitioning: bool = false
var _breaking_block: Node = null

func _ready() -> void:
	"""Initializes environment variables and methods."""
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pause_menu.visible = false
	pause_settings_notice.visible = false
	pause_fade_overlay.modulate.a = 0.0
	variable_block_menu.visible = false
	update_hotbar_visuals()

func _unhandled_input(event: InputEvent) -> void:
	"""Handles one time events."""
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause_menu()
		return
	if _is_pause_menu_open():
		return
	handle_one_time_events(event)

func _physics_process(delta: float) -> void:
	"""Handles continuous physics and game updates each frame."""
	if _is_pause_menu_open():
		return
	handle_constant_events(delta)
				
func handle_one_time_events(event: InputEvent) -> void:
	"""Handles the user's keyboard or mouse inputs (not holding down inputs)."""
	# Handle mouse motion for camera rotation.
	if event is InputEventMouseMotion:
		# Rotate the CharacterBody3D around the Y-axis (left/right).
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Rotate the Head node around the X-axis (up/down).
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		# Clamp the vertical rotation to prevent the camera from flipping over.
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if Input.is_action_just_pressed("place_block"):
		if ray.is_colliding():
			# Variables that contain information on where the player was looking at the time.
			var hit_position = ray.get_collision_point()
			var hit_normal = ray.get_collision_normal()
			var target_block = ray.get_collider()

			# Takes the values of where the raycast saw the click occur to determine block placement.
			var place_position := Vector3(
				floor(hit_position.x + hit_normal.x * 0.5),
				floor(hit_position.y + hit_normal.y * 0.5),
				floor(hit_position.z + hit_normal.z * 0.5)
			)
			
			# Variables that contain information on player's position at the feet and head.
			var player_position = self.global_position.floor()
			var player_head_position = (self.global_position + Vector3(0, 1, 0)).floor()
			
			# If block is in player, don't place.
			if player_position != place_position and player_head_position != place_position:
				var block
				var wire_preferred_dir := Vector3.ZERO
				
				# If slot 3 (index 2), place wire
				if selected_slot == 2:
					var wire_placement = _resolve_wire_placement(hit_position, hit_normal, target_block)
					place_position = wire_placement["position"]
					wire_preferred_dir = wire_placement["preferred_dir"]
					block = WireScene.instantiate()
				# If slot 2 (index 1), place if block
				elif selected_slot == 1:
					block = IfScene.instantiate()
					apply_block_variant(block, selected_slot)
				else:
					block = BlockScene.instantiate()
					apply_block_variant(block, selected_slot)

				if player_position == place_position or player_head_position == place_position:
					return

				if _is_block_cell_occupied(place_position):
					return

				block.set_meta("hotbar_slot", selected_slot)
				get_parent().add_child(block)
				block.global_position = place_position.round()
				if selected_slot == 2 and block.has_method("set_preferred_dir"):
					block.call("set_preferred_dir", wire_preferred_dir)
				_play_block_place_sound()

	if Input.is_action_just_pressed("scroll_down"):
		change_hotbar_slot(-1)
	if Input.is_action_just_pressed("scroll_up"):
		change_hotbar_slot(1)
	if Input.is_action_just_pressed("slot_1"):
		set_hotbar_slot(0)
	if Input.is_action_just_pressed("slot_2"):
		set_hotbar_slot(1)
	if Input.is_action_just_pressed("slot_3"):
		set_hotbar_slot(2)
	# if Input.is_action_just_pressed("open_block_interaction"):
	# 	_var_menu_interact()
		
func handle_constant_events(delta: float) -> void:
	"""Handles all the user's constant events (holding down or physics calcuations done every frame)."""
	if Input.is_action_pressed("break_block"):
		# Incrememt the timer using frames.
		BREAK_TIMER += delta
		if ray.is_colliding():
			var target_block = ray.get_collider()
			if target_block and target_block.has_method("set_break_progress"):
				# BreakableBlock (block, var_block, if_block): wobble + break sound + timer.
				if _breaking_block != null and _breaking_block != target_block and _breaking_block.has_method("set_break_progress"):
					_breaking_block.set_break_progress(0.0)
				_breaking_block = target_block
				_breaking_block.set_break_progress(BREAK_TIMER / BREAK_TIME)
				if BREAK_TIMER <= delta and block_break_sfx and BLOCK_BREAK_SOUND:
					block_break_sfx.stream = BLOCK_BREAK_SOUND
					block_break_sfx.play()
				if BREAK_TIMER >= BREAK_TIME:
					target_block.queue_free()
					BREAK_TIMER = 0.0
					_breaking_block = null
					if block_break_sfx and block_break_sfx.playing:
						block_break_sfx.stop()
			elif target_block and str(target_block.scene_file_path).begins_with("res://Blocks/"):
				# Other Blocks (e.g. wire): break after hold, no wobble.
				if BREAK_TIMER >= BREAK_TIME:
					target_block.queue_free()
					BREAK_TIMER = 0.0
					if block_break_sfx and BLOCK_BREAK_SOUND:
						block_break_sfx.stream = BLOCK_BREAK_SOUND
						block_break_sfx.play()
			else:
				# Looking at non-block (floor, wall, etc.): reset so previous block stops wobbling.
				BREAK_TIMER = 0.0
				_reset_breaking_block()
		else:
			BREAK_TIMER = 0.0
			_reset_breaking_block()
	else:
		# Resets break timer and stop break sound when player releases.
		BREAK_TIMER = 0.0
		_reset_breaking_block()
			
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Maintain jumping while player is holding spacebar.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get directional inputs and vector directions from WASD movement.
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

func change_hotbar_slot(direction: int) -> void:
	"""Changes the current hotbar slot."""
	selected_slot = posmod(selected_slot + direction, HOTBAR_SLOT_COUNT)
	update_hotbar_visuals()

func set_hotbar_slot(slot_index: int) -> void:
	"""Sets the hotbar based on the current hotbar count."""
	selected_slot = clamp(slot_index, 0, HOTBAR_SLOT_COUNT - 1)
	update_hotbar_visuals()

func update_hotbar_visuals() -> void:
	"""Visually updates the hotbar to show which item is currently selected."""
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

func _reset_breaking_block() -> void:
	"""Stops break sound and resets wobble on the block we were breaking."""
	if block_break_sfx and block_break_sfx.playing:
		block_break_sfx.stop()
	if _breaking_block != null and is_instance_valid(_breaking_block) and _breaking_block.has_method("set_break_progress"):
		_breaking_block.set_break_progress(0.0)
	_breaking_block = null

func _play_block_place_sound() -> void:
	"""Plays a random block placement sound effect."""
	if block_place_sfx == null or BLOCK_PLACE_SOUNDS.is_empty():
		return
	block_place_sfx.stream = BLOCK_PLACE_SOUNDS.pick_random()
	block_place_sfx.play()

func apply_block_variant(block: Node, slot_index: int) -> void:
	"""Changes the type of block placed depending on which hotbar slot is selected."""
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

func _resolve_wire_placement(hit_position: Vector3, hit_normal: Vector3, target: Object) -> Dictionary:
	var default_position := Vector3(
		floor(hit_position.x + hit_normal.x * 0.5),
		floor(hit_position.y + hit_normal.y * 0.5),
		floor(hit_position.z + hit_normal.z * 0.5)
	)
	var preferred_dir := _to_cardinal_dir(hit_normal)

	if target is Node3D and _is_snap_candidate(target):
		var target_node := target as Node3D
		var side_dir := _pick_block_side(target_node, hit_position, hit_normal)
		if side_dir != Vector3.ZERO:
			var snapped_position := target_node.global_position.round() + side_dir
			if not _is_block_cell_occupied(snapped_position):
				return {
					"position": snapped_position,
					"preferred_dir": side_dir
				}

	return {
		"position": default_position,
		"preferred_dir": preferred_dir
	}

func _is_snap_candidate(target: Object) -> bool:
	if not target is Node:
		return false
	var target_node := target as Node
	var path := str(target_node.scene_file_path)
	return path.begins_with("res://Blocks/")

func _pick_block_side(target: Node3D, hit_position: Vector3, hit_normal: Vector3) -> Vector3:
	var block_center := target.global_position + Vector3(0.5, 0.5, 0.5)
	var local_hit := hit_position - block_center
	local_hit.y = 0

	if abs(local_hit.x) > abs(local_hit.z) and abs(local_hit.x) > 0.05:
		return Vector3(sign(local_hit.x), 0, 0)
	if abs(local_hit.z) > 0.05:
		return Vector3(0, 0, sign(local_hit.z))
	return _to_cardinal_dir(hit_normal)

func _to_cardinal_dir(direction: Vector3) -> Vector3:
	var flat := direction
	flat.y = 0
	if flat.length_squared() < 0.0001:
		return Vector3.ZERO
	if abs(flat.x) > abs(flat.z):
		return Vector3(sign(flat.x), 0, 0)
	return Vector3(0, 0, sign(flat.z))

func _is_block_cell_occupied(cell_position: Vector3) -> bool:
	var parent := get_parent()
	if parent == null:
		return false

	for child in parent.get_children():
		if not child is Node3D:
			continue
		var node_3d := child as Node3D
		var path := str(node_3d.scene_file_path)
		if not path.begins_with("res://Blocks/"):
			continue
		if node_3d.global_position.distance_to(cell_position.round()) <= GRID_EPSILON:
			return true
	return false

func _is_pause_menu_open() -> bool:
	return pause_menu.visible

func _toggle_pause_menu() -> void:
	if is_pause_transitioning:
		return
	if _is_pause_menu_open():
		_resume_game()
	else:
		_pause_game()

func _pause_game() -> void:
	pause_menu.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pause_resume_button.grab_focus()

func _resume_game() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	pause_settings_notice.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed() -> void:
	_resume_game()

func _on_settings_button_pressed() -> void:
	pause_settings_notice.visible = true
	pause_notice_timer.start()

func _on_main_menu_button_pressed() -> void:
	if is_pause_transitioning:
		return
	is_pause_transitioning = true
	var tween := create_tween()
	tween.tween_property(pause_fade_overlay, "modulate:a", 1.0, PAUSE_FADE_DURATION)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_quit_button_pressed() -> void:
	if is_pause_transitioning:
		return
	is_pause_transitioning = true
	var tween := create_tween()
	tween.tween_property(pause_fade_overlay, "modulate:a", 1.0, PAUSE_FADE_DURATION)
	await tween.finished
	get_tree().paused = false
	get_tree().quit()

func _on_pause_notice_timer_timeout() -> void:
	pause_settings_notice.visible = false

"""
# Variable block overlay
func _var_menu_interact() -> void:
	if variable_block_menu.visible:
		variable_block_menu.visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		variable_block_menu.visible = true
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
"""
