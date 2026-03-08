"""
Developer: Daniel Martin
End Block — receives a signal, evaluates a hardcoded condition,
and on success transitions the player to the level select screen.
"""

extends FlowBlock

# ── Developer-set constants ────────────────────────────────────────────────
const LEVEL_SELECT_SCENE := "res://Levels/level_select.tscn"
const FADE_DURATION       := 0.25

# Hardcoded condition (edit these values, never exposed to the player)
const COND_VAR1    : String = "10"   # name of the first variable block
const COND_VAR2    : String = "10"      # name OR literal to compare against
const COND_COMPARE : String = ">="      # >, <, >=, <=, ==, !=
# ──────────────────────────────────────────────────────────────────────────

var raycast: RayCast3D
var player = null

var powered     := false
var is_locked   := true   # block is never editable

var _input_sources: Array[NodePath] = []
var _fade_overlay: ColorRect = null
var _is_transitioning := false

func _ready() -> void:
	super._ready()
	player = get_tree().get_first_node_in_group("player")
	if player:
		raycast = player.get_node("Head/Camera3D/RayCast3D")

	# Visual cue: tint the block so players know it's special / locked
	var mesh = $MeshInstance3D
	if mesh:
		var existing = mesh.get_active_material(0)
		if existing is StandardMaterial3D:
			var mat = existing.duplicate() as StandardMaterial3D
			mat.albedo_color = Color(0.2, 0.8, 0.3, 1.0)   # green "exit" tint
			mesh.material_override = mat

	# Create a full-screen fade overlay (same technique as the level select screen)
	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas := CanvasLayer.new()
	canvas.layer = 100          # render on top of everything
	canvas.add_child(_fade_overlay)
	add_child(canvas)

# ── No interaction menu — interact does nothing on this block ──────────────
func _unhandled_input(_event: InputEvent) -> void:
	pass   # intentionally empty; EndBlock is not interactive

# ── Condition evaluation ───────────────────────────────────────────────────
func evaluate() -> bool:
	var val_a := COND_VAR1
	var val_b := COND_VAR2   # may be a literal number string

	# If VAR2 looks like a variable block name, resolve it; otherwise treat as literal
	var resolved_b := _get_var_value(COND_VAR2)
	if resolved_b != "":
		val_b = resolved_b

	if val_a == "" :
		push_warning("EndBlock: could not resolve VAR1 '%s'." % COND_VAR1)
		return false

	if val_a.is_valid_float() and val_b.is_valid_float():
		var a := float(val_a)
		var b := float(val_b)
		match COND_COMPARE:
			">":  return a > b
			"<":  return a < b
			">=": return a >= b
			"<=": return a <= b
			"==": return a == b
			"!=": return a != b
	else:
		match COND_COMPARE:
			"==": return val_a == val_b
			"!=": return val_a != val_b

	return false

func _get_var_value(var_name: String) -> String:
	if var_name == "":
		return ""
	for node in get_tree().get_nodes_in_group("var_blocks"):
		if node.var_name == var_name:
			return node.var_val
	return ""   # caller treats empty string as "not found / use as literal"

# ── Signal handling ────────────────────────────────────────────────────────
func receive_signal(run_id: int = -1, from_node: Node = null, step_id: int = 0) -> void:
	if not should_process_signal(run_id, step_id):
		return
	flash_signal()
	powered = true

	if evaluate():
		_exit_to_level_select()

func _exit_to_level_select() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	get_tree().paused = false   # unpause in case it was paused by a menu

	var tween := create_tween()
	_fade_overlay.modulate.a = 0.0
	tween.tween_property(_fade_overlay, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

# ── Reset ──────────────────────────────────────────────────────────────────
func reset_signal_state() -> void:
	super.reset_signal_state()
	_input_sources.clear()
	_is_transitioning = false
