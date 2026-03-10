extends AudioStreamPlayer

const SETTINGS_MUSIC_ENABLED_KEY := "game/settings/music_enabled"
const FALLBACK_TRACK := preload("res://assets/Audio/On The Flip - The Grey Room _ Density & Time.mp3")

@export var default_track: AudioStream
@export var fade_time: float = 1.0

var _tween: Tween

func _ready() -> void:
	if default_track != null:
		stream = default_track
	elif stream == null:
		stream = FALLBACK_TRACK
	var music_enabled: bool = bool(ProjectSettings.get_setting(SETTINGS_MUSIC_ENABLED_KEY, true))
	if music_enabled:
		if not playing and stream != null:
			volume_db = 0.0
			play()
	else:
		stop()

func play_track(new_track: AudioStream) -> void:
	if new_track == null or stream == new_track:
		return
	_fade_out_and_switch(new_track)

func stop_music() -> void:
	stop()

func set_volume_db_safe(value: float) -> void:
	volume_db = clampf(value, -80.0, 0.0)

func _fade_out_and_switch(new_track: AudioStream) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "volume_db", -60.0, fade_time)
	await _tween.finished

	stream = new_track
	play()
	volume_db = -60.0

	_tween = create_tween()
	_tween.tween_property(self, "volume_db", 0.0, fade_time)
