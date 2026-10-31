extends Node

## Аудио менеджер (Музыка, Звуки, Шины громкости)

@onready var music_player_a: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var music_player_b: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var current_music_player: AudioStreamPlayer = music_player_a

var is_player_a_active: bool = true

func _ready() -> void:
	music_player_a.bus = &"Master"
	music_player_b.bus = &"Master"
	add_child(music_player_a)
	add_child(music_player_b)

func play_music(stream: AudioStream, fade_duration: float = 0.5) -> void:
	if stream == null:
		return
	
	var next_player: AudioStreamPlayer = music_player_b if is_player_a_active else music_player_a
	var current_player: AudioStreamPlayer = music_player_a if is_player_a_active else music_player_b
	
	if current_player.playing and current_player.stream == stream:
		return
	
	next_player.stream = stream
	next_player.volume_db = -40.0
	next_player.play()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(next_player, "volume_db", 0.0, fade_duration)
	if current_player.playing:
		tween.tween_property(current_player, "volume_db", -40.0, fade_duration)
		tween.chain().tween_callback(current_player.stop)
	
	is_player_a_active = not is_player_a_active

func stop_music(fade_duration: float = 0.5) -> void:
	var active_player: AudioStreamPlayer = music_player_a if is_player_a_active else music_player_b
	if active_player.playing:
		var tween: Tween = create_tween()
		tween.tween_property(active_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(active_player.stop)

func play_sfx(stream: AudioStream, pitch_variance: float = 0.0) -> void:
	if stream == null:
		return
	var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.bus = &"Master"
	if pitch_variance > 0.0:
		sfx_player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		var db_volume: float = linear_to_db(clampf(linear_volume, 0.0001, 1.0))
		AudioServer.set_bus_volume_db(bus_index, db_volume)
		AudioServer.set_bus_mute(bus_index, linear_volume <= 0.0001)

