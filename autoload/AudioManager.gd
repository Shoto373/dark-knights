extends Node

## Аудио менеджер (Музыка, Звуки, Шины громкости, Процедурный синтез SFX)

@onready var music_player_a: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var music_player_b: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var current_music_player: AudioStreamPlayer = music_player_a

var is_player_a_active: bool = true
var _sfx_cache: Dictionary = {}

func _ready() -> void:
	music_player_a.bus = &"Master"
	music_player_b.bus = &"Master"
	add_child(music_player_a)
	add_child(music_player_b)
	
	_generate_sfx_cache()
	_connect_event_bus()

func _connect_event_bus() -> void:
	if not is_instance_valid(EventBus):
		return
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_died.connect(func(): play_sfx_named("hurt", 0.0))
	EventBus.player_healed.connect(func(_amount: int): play_sfx_named("heal", 0.05))
	EventBus.boss_defeated.connect(func(_name: String): play_sfx_named("victory", 0.0))
	EventBus.room_cleared.connect(func(): play_sfx_named("room_clear", 0.05))
	EventBus.currency_changed.connect(func(_g: int, _s: int): play_sfx_named("coin", 0.12))

func _on_damage_dealt(_target: Node2D, _amount: int, is_crit: bool) -> void:
	if is_crit:
		play_sfx_named("crit", 0.08)
	else:
		play_sfx_named("hit", 0.12)

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

func play_sfx_named(sfx_name: String, pitch_variance: float = 0.08) -> void:
	var stream: AudioStream = _sfx_cache.get(sfx_name, null)
	if stream != null:
		play_sfx(stream, pitch_variance)

func set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		var db_volume: float = linear_to_db(clampf(linear_volume, 0.0001, 1.0))
		AudioServer.set_bus_volume_db(bus_index, db_volume)
		AudioServer.set_bus_mute(bus_index, linear_volume <= 0.0001)

# --- Процедурный синтез звуковых эффектов (8-bit PCM) ---

func _generate_sfx_cache() -> void:
	_sfx_cache["swing"] = _synth_swing()
	_sfx_cache["shoot"] = _synth_shoot()
	_sfx_cache["cast"] = _synth_cast()
	_sfx_cache["hit"] = _synth_hit()
	_sfx_cache["crit"] = _synth_crit()
	_sfx_cache["dash"] = _synth_dash()
	_sfx_cache["coin"] = _synth_coin()
	_sfx_cache["hurt"] = _synth_hurt()
	_sfx_cache["heal"] = _synth_heal()
	_sfx_cache["room_clear"] = _synth_room_clear()
	_sfx_cache["victory"] = _synth_victory()

func _create_wav(samples: PackedByteArray, rate: int = 22050) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = samples
	return wav

func _synth_swing() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.12
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = (1.0 - progress) * (1.0 - progress)
		var freq: float = lerpf(300.0, 90.0, progress)
		var sine_val: float = sin(TAU * freq * t)
		var noise_val: float = randf_range(-1.0, 1.0)
		var mixed: float = (sine_val * 0.4 + noise_val * 0.6) * env * 0.7
		data[i] = clampi(int((mixed + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_shoot() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.11
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = 1.0 - progress
		var freq: float = lerpf(880.0, 220.0, progress)
		var val: float = sin(TAU * freq * t) * env * 0.65
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_cast() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.20
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = sin(progress * PI)
		var freq: float = 440.0 + sin(t * 30.0) * 160.0
		var val: float = (sin(TAU * freq * t) * 0.7 + randf_range(-0.3, 0.3)) * env * 0.6
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_hit() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.08
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 14.0)
		var freq: float = lerpf(220.0, 60.0, progress)
		var val: float = (sin(TAU * freq * t) * 0.5 + randf_range(-0.5, 0.5)) * env * 0.8
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_crit() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.15
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 10.0)
		var val: float = (sin(TAU * 880.0 * t) * 0.5 + sin(TAU * 1320.0 * t) * 0.4 + randf_range(-0.2, 0.2)) * env * 0.8
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_dash() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.16
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = sin(progress * PI)
		var noise: float = randf_range(-1.0, 1.0)
		var val: float = noise * env * 0.55
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_coin() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.18
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var freq: float = 987.77 if progress < 0.45 else 1318.51
		var env: float = 1.0 - progress
		var val: float = sin(TAU * freq * t) * env * 0.65
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_hurt() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.16
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 8.0)
		var freq: float = lerpf(160.0, 50.0, progress)
		var square: float = 1.0 if sin(TAU * freq * t) > 0.0 else -1.0
		var val: float = square * env * 0.55
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_heal() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.24
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var freq: float = 523.25
		if progress > 0.66:
			freq = 783.99
		elif progress > 0.33:
			freq = 659.25
		var env: float = sin(progress * PI)
		var val: float = sin(TAU * freq * t) * env * 0.6
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_room_clear() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.28
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var freq: float = 440.0
		if progress > 0.66:
			freq = 659.25
		elif progress > 0.33:
			freq = 554.37
		var env: float = 1.0 - progress * 0.7
		var val: float = sin(TAU * freq * t) * env * 0.55
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)

func _synth_victory() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.45
	var count: int = int(dur * rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 5.0)
		var freq: float = lerpf(180.0, 40.0, progress)
		var val: float = (sin(TAU * freq * t) * 0.6 + randf_range(-0.4, 0.4)) * env * 0.75
		data[i] = clampi(int((val + 1.0) * 127.5), 0, 255)
	return _create_wav(data, rate)
