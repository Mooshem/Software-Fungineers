extends StaticBody3D

## Break progress 0.0–1.0. When > 0, the mesh wobbles; intensity increases with progress.
var break_progress: float = 0.0

const MESH_OFFSET := Vector3(0.5, 0.5, 0.5)
const WOBBLE_SPEED := 22.0
const WOBBLE_MAX_ANGLE := 0.18

var _wobble_time: float = 0.0
var _mesh_instance: MeshInstance3D

func _ready() -> void:
	_mesh_instance = $MeshInstance3D

func set_break_progress(p: float) -> void:
	break_progress = clampf(p, 0.0, 1.0)

func _process(delta: float) -> void:
	if _mesh_instance == null:
		return
	if break_progress <= 0.0:
		_mesh_instance.transform = Transform3D(Basis(), MESH_OFFSET)
		_wobble_time = 0.0
		return
	_wobble_time += delta
	var intensity := break_progress * WOBBLE_MAX_ANGLE
	var rot_x := sin(_wobble_time * WOBBLE_SPEED) * intensity
	var rot_z := cos(_wobble_time * (WOBBLE_SPEED * 1.1)) * intensity
	var basis := Basis.from_euler(Vector3(rot_x, 0.0, rot_z))
	_mesh_instance.transform = Transform3D(basis, MESH_OFFSET)
