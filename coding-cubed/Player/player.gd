"""
Developers: Donovan Thach, Cash Limberg, Zheng Chen, Daniel Martin
Documentation : https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
"""

extends CharacterBody3D

# Environment variables that will be initialized.
@onready var head: Node3D = $Head
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hotbar: HBoxContainer = $CanvasLayer/Hotbar
@onready var hotbar_selection_label: Label = $CanvasLayer/HotbarSelectionLabel
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var pause_resume_button: Button = $CanvasLayer/PauseMenu/Center/Panel/VBox/ResumeButton
@onready var pause_settings_overlay: Control = $CanvasLayer/PauseMenu/SettingsOverlay
# Backward-compatible alias used by tests expecting a placeholder notice node.
@onready var pause_settings_notice: Control = $CanvasLayer/PauseMenu/SettingsOverlay
@onready var pause_settings_master_volume_slider: HSlider = $CanvasLayer/PauseMenu/SettingsOverlay/Center/Panel/VBox/MasterVolumeHBox/MasterVolumeSlider
@onready var pause_settings_music_check_box: CheckBox = $CanvasLayer/PauseMenu/SettingsOverlay/Center/Panel/VBox/MusicHBox/MusicCheckBox
@onready var pause_settings_hotbar_size_option: OptionButton = $CanvasLayer/PauseMenu/SettingsOverlay/Center/Panel/VBox/HotbarSizeHBox/HotbarSizeOption
@onready var pause_notice_timer: Timer = $CanvasLayer/PauseNoticeTimer
@onready var pause_fade_overlay: ColorRect = $CanvasLayer/PauseFadeOverlay

# Block Menus
@onready var variable_block_menu: Control = $CanvasLayer/VariableBlockMenu
@onready var if_block_menu: Control = $CanvasLayer/IfBlockMenu
@onready var increment_block_menu: Control = $CanvasLayer/IncrementBlockMenu
@onready var block_place_sfx: AudioStreamPlayer = $BlockPlaceSfx
@onready var block_break_sfx: AudioStreamPlayer = $BlockBreakSfx

# Captures the block scene to add to the scene when necessary.
var VarBlockScene = preload("res://Blocks/var_block.tscn")
var WireScene = preload("res://Blocks/wire.tscn")
var IfScene = preload("res://Blocks/if_block.tscn")
var StartBlockScene = preload("res://Blocks/start_block.tscn")
var IncrementScene = preload("res://Blocks/increment_block.tscn")

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

# Hotbar & settings keys.
const HOTBAR_SLOT_COUNT: int = 5
const SETTINGS_MASTER_VOLUME_KEY := "game/settings/master_volume"
const SETTINGS_MUSIC_ENABLED_KEY := "game/settings/music_enabled"
const SETTINGS_HOTBAR_SCALE_KEY := "game/settings/hotbar_scale"
const GRID_STEP: float = 1.0
const GRID_EPSILON: float = 0.05
const HOTBAR_SLOT_SHORT_NAMES := ["VAR", "IF", "WIRE", "START", "INC"]
const HOTBAR_SLOT_DISPLAY_NAMES := ["Variable Block", "If Block", "Wire", "Start Block", "Increment Block"]
const HOTBAR_SELECTION_POPUP_TIME := 0.6
const HOTBAR_SELECTION_FADE_TIME := 0.25

# Timer used to sense how long left click is held.
var BREAK_TIMER: float = 0.0
# How long is required to break a block.
var BREAK_TIME: float = 1
var selected_slot: int = 0
var is_pause_transitioning: bool = false
var _breaking_block: Node = null
var _hotbar_selection_tween: Tween = null

func _ready() -> void:
	"""Initializes environment variables and methods."""
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pause_menu.visible = false
	if pause_settings_overlay != null:
		pause_settings_overlay.visible = false
	pause_fade_overlay.modulate.a = 0.0
	
	# Blocks
	variable_block_menu.visible = false
	if_block_menu.visible = false
	increment_block_menu.visible = false
	_init_pause_settings_hotbar_size_options()
	_load_pause_settings()
	update_hotbar_visuals()
	# Deferred so the hotbar has a valid size before we compute its pivot.
	_apply_hotbar_scale_from_settings.call_deferred()
	if hotbar_selection_label != null:
		hotbar_selection_label.visible = false
		hotbar_selection_label.modulate.a = 0.0

func _apply_hotbar_scale_from_settings() -> void:
	var hotbar_scale: float = float(ProjectSettings.get_setting(SETTINGS_HOTBAR_SCALE_KEY, 2.0))
	if typeof(hotbar_scale) != TYPE_FLOAT:
		hotbar_scale = 2.0
	if hotbar != null:
		# Scale from the center-bottom so the hotbar stays centered on screen.
		hotbar.pivot_offset = Vector2(hotbar.size.x * 0.5, hotbar.size.y)
		hotbar.scale = Vector2.ONE * hotbar_scale
	if hotbar_selection_label != null:
		# Keep the label above the scaled hotbar.
		# Hotbar bottom anchor offset = -12, unscaled height = 44.
		# After scaling from bottom pivot, hotbar visual top = -(12 + 44 * scale).
		const HOTBAR_BOTTOM_OFFSET: float = -12.0
		const HOTBAR_UNSCALED_HEIGHT: float = 44.0
		const LABEL_GAP: float = 8.0
		const LABEL_HEIGHT: float = 24.0
		var label_bottom: float = HOTBAR_BOTTOM_OFFSET - HOTBAR_UNSCALED_HEIGHT * hotbar_scale - LABEL_GAP
		hotbar_selection_label.offset_bottom = label_bottom
		hotbar_selection_label.offset_top = label_bottom - LABEL_HEIGHT

func _init_pause_settings_hotbar_size_options() -> void:
	if pause_settings_hotbar_size_option == null:
		return
	pause_settings_hotbar_size_option.clear()
	pause_settings_hotbar_size_option.add_item("Small", 0)
	pause_settings_hotbar_size_option.add_item("Medium", 1)
	pause_settings_hotbar_size_option.add_item("Large", 2)

func _load_pause_settings() -> void:
	if pause_settings_master_volume_slider != null:
		var master_volume: float = float(ProjectSettings.get_setting(SETTINGS_MASTER_VOLUME_KEY, 1.0))
		if typeof(master_volume) != TYPE_FLOAT:
			master_volume = 1.0
		pause_settings_master_volume_slider.value = clamp(master_volume, 0.0, 1.0)
		_apply_master_volume(pause_settings_master_volume_slider.value)

	if pause_settings_music_check_box != null:
		var music_enabled: bool = bool(ProjectSettings.get_setting(SETTINGS_MUSIC_ENABLED_KEY, true))
		if typeof(music_enabled) != TYPE_BOOL:
			music_enabled = true
		pause_settings_music_check_box.button_pressed = music_enabled
		_apply_music_enabled(pause_settings_music_check_box.button_pressed)

	if pause_settings_hotbar_size_option != null:
		var hotbar_scale: float = float(ProjectSettings.get_setting(SETTINGS_HOTBAR_SCALE_KEY, 2.0))
		if typeof(hotbar_scale) != TYPE_FLOAT:
			hotbar_scale = 2.0
		var index := 1
		if hotbar_scale <= 1.85:
			index = 0
		elif hotbar_scale >= 2.2:
			index = 2
		pause_settings_hotbar_size_option.select(index)
		_apply_hotbar_scale_from_settings.call_deferred()

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
	var music_root := get_node_or_null("/root/Music")
	if music_root != null:
		var candidates: Array = []
		if music_root is AudioStreamPlayer:
			candidates.append(music_root)
		for child in music_root.get_children():
			if child is AudioStreamPlayer:
				candidates.append(child)

		var music_player: AudioStreamPlayer = null
		for candidate in candidates:
			if candidate is AudioStreamPlayer:
				if music_player == null:
					music_player = candidate
				if candidate.has_method("stop_music"):
					music_player = candidate
					break

		if music_player != null:
			if enabled:
				if not music_player.playing and music_player.stream != null:
					music_player.play()
			else:
				if music_player.has_method("stop_music"):
					music_player.call("stop_music")
				else:
					music_player.stop()
		return

	# Fallback: if a dedicated Music bus exists, toggle it.
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_mute(music_bus, not enabled)

func _unhandled_input(event: InputEvent) -> void:
	"""Handles one time events."""
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause_menu()
		return
	if _is_pause_menu_open():
		return
	if _is_var_menu_open():
		return
	if _is_if_menu_open():
		return
	if _is_increment_menu_open():
		return
	handle_one_time_events(event)

func _is_var_menu_open() -> bool:
	return variable_block_menu.visible
	
func _is_if_menu_open() -> bool:
	return if_block_menu.visible

func _is_increment_menu_open() -> bool:
	return increment_block_menu.visible
	
func _physics_process(delta: float) -> void:
	"""Handles continuous physics and game updates each frame."""
	if _is_pause_menu_open():
		return
	if _is_var_menu_open():
		return
	if _is_if_menu_open():
		return
	if _is_increment_menu_open():
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
				# If slot 4 (index 3), place start block (signal block) — allow snap to wires/blocks and replace wire in cell
				elif selected_slot == 3:
					var start_placement = _resolve_wire_placement(hit_position, hit_normal, target_block)
					place_position = start_placement["position"]
					block = StartBlockScene.instantiate()
				# If slot 5 (index 4), place increment block
				elif selected_slot == 4:
					block = IncrementScene.instantiate()
					apply_block_variant(block, selected_slot)
				else:
					block = VarBlockScene.instantiate()
					apply_block_variant(block, selected_slot)

				if player_position == place_position or player_head_position == place_position:
					return

				# For start block (sandbox): allow replacing a wire in the target cell so it's placeable on wires
				if selected_slot == 3:
					var existing := _get_block_at_cell(place_position)
					if existing != null:
						if _is_wire_scene(existing):
							existing.queue_free()
						else:
							return
				elif _is_block_cell_occupied(place_position):
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
	if Input.is_action_just_pressed("slot_4"):
		set_hotbar_slot(3)
	if Input.is_action_just_pressed("slot_5"):
		set_hotbar_slot(4)
		
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
					if not target_block.get("is_locked"):
						target_block.queue_free()
						BREAK_TIMER = 0.0
						_breaking_block = null
						if block_break_sfx and block_break_sfx.playing:
							block_break_sfx.stop()
			elif target_block and str(target_block.scene_file_path).begins_with("res://Blocks/"):
				# Other Blocks (e.g. wire): break after hold, no wobble.
				if BREAK_TIMER >= BREAK_TIME:
					if not target_block.get("is_locked"):
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
	update_hotbar_visuals(true)

func set_hotbar_slot(slot_index: int) -> void:
	"""Sets the hotbar based on the current hotbar count."""
	selected_slot = clamp(slot_index, 0, HOTBAR_SLOT_COUNT - 1)
	update_hotbar_visuals(true)

func update_hotbar_visuals(show_selection_feedback: bool = false) -> void:
	"""Visually updates the hotbar to show which item is currently selected."""
	if hotbar == null:
		return

	for i in range(hotbar.get_child_count()):
		var slot_panel := hotbar.get_child(i) as Panel
		if slot_panel == null:
			continue
		var slot_label := slot_panel.get_node_or_null("Label") as Label
		if slot_label != null and i < HOTBAR_SLOT_SHORT_NAMES.size():
			slot_label.text = "%d\n%s" % [i + 1, HOTBAR_SLOT_SHORT_NAMES[i]]
		if i == selected_slot:
			slot_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			slot_panel.modulate = Color(0.65, 0.65, 0.65, 1.0)

	if hotbar_selection_label != null and selected_slot < HOTBAR_SLOT_DISPLAY_NAMES.size():
		hotbar_selection_label.text = "Selected: %s" % HOTBAR_SLOT_DISPLAY_NAMES[selected_slot]
		if show_selection_feedback:
			_show_hotbar_selection_feedback()

func _show_hotbar_selection_feedback() -> void:
	if hotbar_selection_label == null:
		return
	if _hotbar_selection_tween != null:
		_hotbar_selection_tween.kill()
	_hotbar_selection_tween = create_tween()
	hotbar_selection_label.visible = true
	hotbar_selection_label.modulate.a = 0.0
	_hotbar_selection_tween.tween_property(hotbar_selection_label, "modulate:a", 1.0, HOTBAR_SELECTION_FADE_TIME)
	_hotbar_selection_tween.tween_interval(HOTBAR_SELECTION_POPUP_TIME)
	_hotbar_selection_tween.tween_property(hotbar_selection_label, "modulate:a", 0.0, HOTBAR_SELECTION_FADE_TIME)
	_hotbar_selection_tween.finished.connect(_hide_hotbar_selection_label)

func _hide_hotbar_selection_label() -> void:
	if hotbar_selection_label != null:
		hotbar_selection_label.visible = false
	_hotbar_selection_tween = null

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
	return _get_block_at_cell(cell_position) != null

func _get_block_at_cell(cell_position: Vector3) -> Node3D:
	var parent := get_parent()
	if parent == null:
		return null
	var cell := cell_position.round()
	for child in parent.get_children():
		if not child is Node3D:
			continue
		var node_3d := child as Node3D
		var path := str(node_3d.scene_file_path)
		if not path.begins_with("res://Blocks/"):
			continue
		if node_3d.global_position.distance_to(cell) <= GRID_EPSILON:
			return node_3d
	return null

func _is_wire_scene(node: Node) -> bool:
	"""True if the node is from the wire scene (so start block can replace it in sandbox)."""
	return "wire" in str(node.scene_file_path)

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
	if pause_settings_overlay != null:
		pause_settings_overlay.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed() -> void:
	_resume_game()

func _on_settings_button_pressed() -> void:
	if pause_settings_overlay != null:
		_load_pause_settings()
		pause_settings_overlay.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
	if pause_settings_notice != null:
		pause_settings_notice.visible = false

func _on_pause_settings_master_volume_value_changed(value: float) -> void:
	_apply_master_volume(value)
	_save_setting(SETTINGS_MASTER_VOLUME_KEY, value)

func _on_pause_settings_music_check_box_toggled(button_pressed: bool) -> void:
	_apply_music_enabled(button_pressed)
	_save_setting(SETTINGS_MUSIC_ENABLED_KEY, button_pressed)

func _on_pause_settings_hotbar_size_option_item_selected(index: int) -> void:
	var scale := 2.0
	if index == 0:
		scale = 1.7
	elif index == 2:
		scale = 2.4
	_save_setting(SETTINGS_HOTBAR_SCALE_KEY, scale)
	_apply_hotbar_scale_from_settings()

func _on_pause_settings_close_button_pressed() -> void:
	if pause_settings_overlay != null:
		pause_settings_overlay.visible = false
	pause_resume_button.grab_focus()

"""
# Variable block overlay
func _var_menu_interact() -> void:
	if variable_block_menu.visible:
		variable_block_menu.visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		variable_block_menu.visible = true
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
"""
