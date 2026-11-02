extends Node

## Высококачественный Аудио Менеджер (Студийный 16-bit Hi-Fi PCM, Процедурная музыка, SFX)
## Полная замена резких 8-битных шумов на мягкие, сочные и гармоничные звуки

@onready var music_player_a: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var music_player_b: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var current_music_player: AudioStreamPlayer = music_player_a

var is_player_a_active: bool = true
var current_track_name: String = ""

var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}

func _ready() -> void:
	music_player_a.bus = &"Master"
	music_player_b.bus = &"Master"
	add_child(music_player_a)
	add_child(music_player_b)
	
	_generate_sfx_cache()
	_generate_music_cache()
	_connect_event_bus()

func _connect_event_bus() -> void:
	if not is_instance_valid(EventBus):
		return
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_healed.connect(func(_amount: int): play_sfx_named("heal", 0.04))
	EventBus.room_cleared.connect(func(): play_sfx_named("room_clear", 0.03))
	EventBus.currency_changed.connect(func(_g: int, _s: int): play_sfx_named("coin", 0.08))
	
	# Автоматические переходы фоновой музыки
	EventBus.boss_spawned.connect(func(_name: String, _hp: int):
		play_music_named("boss", 0.6)
	)
	EventBus.boss_defeated.connect(func(_name: String):
		play_sfx_named("victory", 0.0)
		play_music_named("dungeon", 1.8)
	)
	EventBus.player_died.connect(func():
		play_sfx_named("hurt", 0.0)
		stop_music(1.2)
	)
	EventBus.run_started.connect(func(_seed: int):
		play_music_named("dungeon", 1.0)
	)

func _on_damage_dealt(_target: Node2D, _amount: int, is_crit: bool) -> void:
	if is_crit:
		play_sfx_named("crit", 0.05)
	else:
		play_sfx_named("hit", 0.08)

# --- Управление фоновой музыкой ---

func play_music_named(track_name: String, fade_duration: float = 0.8) -> void:
	if current_track_name == track_name:
		var active: AudioStreamPlayer = music_player_a if is_player_a_active else music_player_b
		if active.playing:
			return
	
	var stream: AudioStream = _music_cache.get(track_name, null)
	if stream != null:
		current_track_name = track_name
		play_music(stream, fade_duration)

func play_music(stream: AudioStream, fade_duration: float = 0.5) -> void:
	if stream == null:
		return
	
	var next_player: AudioStreamPlayer = music_player_b if is_player_a_active else music_player_a
	var current_player: AudioStreamPlayer = music_player_a if is_player_a_active else music_player_b
	
	if current_player.playing and current_player.stream == stream:
		return
	
	next_player.stream = stream
	next_player.volume_db = -45.0
	next_player.play()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(next_player, "volume_db", -3.0, fade_duration).set_trans(Tween.TRANS_SINE)
	if current_player.playing:
		tween.tween_property(current_player, "volume_db", -45.0, fade_duration).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_callback(current_player.stop)
	
	is_player_a_active = not is_player_a_active

func stop_music(fade_duration: float = 0.5) -> void:
	current_track_name = ""
	var active_player: AudioStreamPlayer = music_player_a if is_player_a_active else music_player_b
	if active_player.playing:
		var tween: Tween = create_tween()
		tween.tween_property(active_player, "volume_db", -45.0, fade_duration).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(active_player.stop)

# --- Управление звуковыми эффектами (SFX) ---

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

# --- Генераторы 16-битных WAV аудио-потоков ---

func _create_wav_16(samples: PackedFloat32Array, rate: int = 44100, loop: bool = false) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	var count: int = samples.size()
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(count * 2)
	for i in range(count):
		var s: float = clampf(samples[i], -1.0, 1.0)
		var val: int = clampi(int(s * 32767.0), -32768, 32767)
		byte_data.encode_s16(i * 2, val)
	wav.data = byte_data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = count
	return wav

func _create_wav(samples: PackedByteArray, rate: int = 22050) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = samples
	return wav

func _apply_loop_crossfade(samples: PackedFloat32Array, crossfade_samples: int = 1100) -> void:
	var n: int = samples.size()
	if n <= crossfade_samples * 2:
		return
	for i in range(crossfade_samples):
		var factor: float = float(i) / float(crossfade_samples)
		var head_val: float = samples[i]
		var tail_idx: int = n - crossfade_samples + i
		var tail_val: float = samples[tail_idx]
		var blended: float = lerpf(tail_val, head_val, factor)
		samples[i] = blended
		samples[tail_idx] = blended

# --- Процедурный синтез приятных звуковых эффектов (16-bit 44.1 kHz) ---

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
	_sfx_cache["shield_block"] = _synth_shield_block()

func _synth_swing() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.16
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var filter_noise: float = 0.0
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = sin(progress * PI)
		env = env * env
		var freq: float = lerpf(380.0, 110.0, progress * progress)
		phase += TAU * freq * (1.0 / float(rate))
		var tone: float = sin(phase) * 0.45 + sin(phase * 0.5) * 0.2
		var raw_noise: float = randf_range(-1.0, 1.0)
		filter_noise = lerpf(filter_noise, raw_noise, 0.22)
		var s: float = (tone * 0.5 + filter_noise * 0.5) * env * 0.75
		samples[i] = s
	return _create_wav_16(samples, rate)

func _synth_shoot() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.14
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var body_phase: float = 0.0
	var zip_phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var snap: float = sin(TAU * 880.0 * t) * exp(-progress * 50.0) * 0.5
		body_phase += TAU * 280.0 * (1.0 / float(rate))
		var body: float = (sin(body_phase) * 0.6 + sin(body_phase * 2.0) * 0.3) * exp(-progress * 16.0)
		var zip_freq: float = lerpf(350.0, 950.0, progress)
		zip_phase += TAU * zip_freq * (1.0 / float(rate))
		var zip_env: float = sin(progress * PI) * 0.35
		var zip_sound: float = sin(zip_phase) * zip_env
		samples[i] = (snap + body * 0.55 + zip_sound) * 0.75
	return _create_wav_16(samples, rate)

func _synth_cast() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.32
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = sin(progress * PI)
		var vibrato: float = sin(t * 14.0) * 8.0
		var f1: float = 164.81 + vibrato
		var f2: float = 246.94 + vibrato * 1.5
		var f3: float = 329.63 + vibrato * 2.0
		var f4: float = 415.30 + vibrato * 2.5
		var chord: float = (
			sin(TAU * f1 * t) * 0.35 +
			sin(TAU * f2 * t) * 0.30 +
			sin(TAU * f3 * t) * 0.25 +
			sin(TAU * f4 * t) * 0.20
		)
		var shimmer: float = sin(TAU * 1320.0 * t) * 0.08 * env
		samples[i] = (chord * env + shimmer) * 0.7
	return _create_wav_16(samples, rate)

func _synth_hit() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.12
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var phase: float = 0.0
	var click_phase: float = 0.0
	var f_noise: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var freq: float = lerpf(135.0, 40.0, progress * progress)
		phase += TAU * freq * (1.0 / float(rate))
		var bass_env: float = exp(-progress * 18.0)
		var bass: float = sin(phase) * bass_env * 0.7
		click_phase += TAU * 1400.0 * (1.0 / float(rate))
		var click_env: float = exp(-progress * 65.0)
		var click: float = sin(click_phase) * click_env * 0.45
		f_noise = lerpf(f_noise, randf_range(-1.0, 1.0), 0.18)
		var noise_part: float = f_noise * exp(-progress * 25.0) * 0.35
		samples[i] = (bass + click + noise_part) * 0.85
	return _create_wav_16(samples, rate)

func _synth_crit() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.22
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var bass_phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var b_freq: float = lerpf(120.0, 35.0, progress)
		bass_phase += TAU * b_freq * (1.0 / float(rate))
		var bass: float = sin(bass_phase) * exp(-progress * 16.0) * 0.65
		var chime_env: float = exp(-progress * 7.5)
		var chime: float = (
			sin(TAU * 1046.5 * t) * 0.45 +
			sin(TAU * 1567.98 * t) * 0.35 +
			sin(TAU * 2093.0 * t) * 0.25
		) * chime_env
		samples[i] = (bass + chime) * 0.8
	return _create_wav_16(samples, rate)

func _synth_dash() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.18
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var filter_noise: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = sin(progress * PI)
		env = env * env
		var sub_bass: float = sin(TAU * 75.0 * t) * env * 0.4
		var raw_n: float = randf_range(-1.0, 1.0)
		filter_noise = lerpf(filter_noise, raw_n, 0.2)
		var wind: float = filter_noise * env * 0.55
		samples[i] = (sub_bass + wind) * 0.75
	return _create_wav_16(samples, rate)

func _synth_coin() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.24
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env1: float = exp(-progress * 9.0)
		var tone1: float = (
			sin(TAU * 1174.66 * t) * 0.6 +
			sin(TAU * 2349.32 * t) * 0.25 +
			sin(TAU * 3523.98 * t) * 0.15
		) * env1
		var tone2: float = 0.0
		if t > 0.035:
			var dt: float = t - 0.035
			var env2: float = exp(-(dt / (dur - 0.035)) * 10.0)
			tone2 = (
				sin(TAU * 1567.98 * dt) * 0.65 +
				sin(TAU * 3135.96 * dt) * 0.25
			) * env2
		samples[i] = (tone1 * 0.5 + tone2 * 0.6) * 0.75
	return _create_wav_16(samples, rate)

func _synth_hurt() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.18
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var phase: float = 0.0
	var f_noise: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 14.0)
		var freq: float = lerpf(110.0, 35.0, progress * progress)
		phase += TAU * freq * (1.0 / float(rate))
		var bass: float = sin(phase) * env * 0.7
		var grunt: float = sin(TAU * 210.0 * t) * exp(-progress * 10.0) * 0.35
		f_noise = lerpf(f_noise, randf_range(-1.0, 1.0), 0.12)
		var impact_noise: float = f_noise * env * 0.25
		samples[i] = (bass + grunt + impact_noise) * 0.8
	return _create_wav_16(samples, rate)

func _synth_heal() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.35
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var notes: Array[float] = [349.23, 440.0, 523.25, 698.46]
	var note_times: Array[float] = [0.0, 0.07, 0.14, 0.21]
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		var total_s: float = 0.0
		for n in range(notes.size()):
			var nt: float = note_times[n]
			if t >= nt:
				var dt: float = t - nt
				var n_env: float = exp(-dt * 9.0)
				var freq: float = notes[n]
				var s: float = (
					sin(TAU * freq * dt) * 0.55 +
					sin(TAU * freq * 2.0 * dt) * 0.25 +
					sin(TAU * freq * 3.0 * dt) * 0.1
				) * n_env
				total_s += s
		samples[i] = total_s * 0.65
	return _create_wav_16(samples, rate)

func _synth_room_clear() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.42
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	var freqs: Array[float] = [293.66, 369.99, 440.0, 587.33]
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 5.5) * (1.0 - exp(-t * 80.0))
		var chord: float = 0.0
		for f in freqs:
			chord += sin(TAU * f * t) * 0.25
		var shimmer: float = sin(TAU * 1174.66 * t) * 0.1 * env
		samples[i] = (chord * env + shimmer) * 0.75
	return _create_wav_16(samples, rate)

func _synth_victory() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.65
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 4.0) * (1.0 - exp(-t * 50.0))
		var bass: float = sin(TAU * 73.42 * t) * 0.45 * env
		var brass: float = (
			sin(TAU * 146.83 * t) * 0.35 +
			sin(TAU * 220.0 * t) * 0.30 +
			sin(TAU * 293.66 * t) * 0.30 +
			sin(TAU * 369.99 * t) * 0.25
		) * env
		samples[i] = (bass + brass) * 0.75
	return _create_wav_16(samples, rate)

func _synth_shield_block() -> AudioStreamWAV:
	var rate: int = 44100
	var dur: float = 0.20
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		var progress: float = t / dur
		var env: float = exp(-progress * 16.0)
		var clang: float = (
			sin(TAU * 480.0 * t) * 0.45 +
			sin(TAU * 890.0 * t) * 0.35 +
			sin(TAU * 1420.0 * t) * 0.25 +
			sin(TAU * 2150.0 * t) * 0.18
		) * env
		var thud: float = sin(TAU * 120.0 * t) * exp(-progress * 24.0) * 0.4
		samples[i] = (clang + thud) * 0.8
	return _create_wav_16(samples, rate)

# --- Процедурный синтез атмосферной фоновой музыки (16-bit 22.05 kHz) ---

func _generate_music_cache() -> void:
	_music_cache["menu"] = _synth_music_menu_hub()
	_music_cache["hub"] = _music_cache["menu"]
	_music_cache["dungeon"] = _synth_music_dungeon()
	_music_cache["boss"] = _synth_music_boss()

func _synth_music_menu_hub() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 12.0
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	# 4 аккордовые гармонические зоны по 3 секунды: Dm9 -> Bbmaj7 -> C6 -> Am7
	var chords: Array = [
		[73.42, 110.0, 174.61, 261.63, 329.63], # Dm9
		[58.27, 87.31, 146.83, 220.00, 293.66], # Bbmaj7
		[65.41, 98.00, 164.81, 196.00, 329.63], # C6
		[55.00, 82.41, 130.81, 164.81, 220.00]  # Am7
	]
	
	# Колокольные / кристальные мелодические ноты в стиле темного фэнтези
	var bell_notes: Array[float] = [440.0, 587.33, 349.23, 523.25, 659.25, 392.0, 440.0]
	var bell_times: Array[float] = [0.6, 2.2, 3.8, 5.4, 7.0, 8.6, 10.4]
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		
		# Определение текущего аккорда с мягким перетеканием
		var section: float = fmod(t, 12.0) / 3.0
		var c_idx_a: int = int(section) % 4
		var c_idx_b: int = (c_idx_a + 1) % 4
		var blend: float = fmod(section, 1.0)
		var blend_s: float = smoothstep(0.0, 1.0, blend)
		
		var pad_sample: float = 0.0
		var c_a: Array = chords[c_idx_a]
		var c_b: Array = chords[c_idx_b]
		
		for k in range(5):
			var f_a: float = c_a[k]
			var f_b: float = c_b[k]
			var sig_a: float = sin(TAU * f_a * t) * 0.08
			var sig_b: float = sin(TAU * f_b * t) * 0.08
			pad_sample += lerpf(sig_a, sig_b, blend_s)
		
		# Дышащий медленный LFO пэда
		var pad_lfo: float = 0.75 + 0.25 * sin(t * 1.5708)
		pad_sample *= pad_lfo
		
		# Теплый бархатный виолончельный суб-бас
		var drone: float = (sin(TAU * 73.42 * t) * 0.16 + sin(TAU * 110.0 * t) * 0.09)
		
		# Хрустальные готические колокола
		var bell_total: float = 0.0
		for b in range(bell_notes.size()):
			var bt: float = bell_times[b]
			if t >= bt and t < bt + 2.2:
				var dt: float = t - bt
				var b_env: float = exp(-dt * 4.5)
				var bf: float = bell_notes[b]
				# Обертоны колокола (основной + терция + октава)
				var b_sig: float = (
					sin(TAU * bf * dt) * 0.6 +
					sin(TAU * bf * 2.76 * dt) * 0.25 +
					sin(TAU * bf * 5.40 * dt) * 0.15
				) * b_env
				bell_total += b_sig
		
		samples[i] = (pad_sample + drone + bell_total * 0.28) * 0.85
	
	_apply_loop_crossfade(samples, 1200)
	return _create_wav_16(samples, rate, true)

func _synth_music_dungeon() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 12.0
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	# Темп 90 BPM (1 четверть = 0.6667 сек)
	var beat_len: float = 0.66667
	var bass_notes: Array[float] = [
		73.42, 73.42, 87.31, 73.42, 98.00, 87.31, 65.41, 73.42,
		55.00, 73.42, 73.42, 87.31, 77.78, 73.42, 65.41, 73.42, 49.00, 55.00
	]
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		
		# Кавернозный пульс саб-баса (тяжелый глухой ритм шагов по склепу)
		var beat_progress: float = fmod(t, beat_len) / beat_len
		var kick_env: float = exp(-beat_progress * 14.0)
		var kick_freq: float = lerpf(80.0, 42.0, beat_progress * beat_progress)
		var kick: float = sin(TAU * kick_freq * (t * 0.5)) * kick_env * 0.24
		
		# Пульсирующий бас синтезатора подземелья
		var step_idx: int = int(t / (beat_len * 0.5)) % bass_notes.size()
		var step_t: float = fmod(t, beat_len * 0.5) / (beat_len * 0.5)
		var b_freq: float = bass_notes[step_idx]
		var b_env: float = exp(-step_t * 6.5)
		var bass: float = (sin(TAU * b_freq * t) * 0.55 + sin(TAU * b_freq * 2.0 * t) * 0.25) * b_env * 0.26
		
		# Мрачный гудящий пэд катакомб (D2 + A2 + Eb3 для зловещей атмосферы)
		var sweep: float = sin(t * 0.75) * 6.0
		var pad: float = (
			sin(TAU * (73.42 + sweep) * t) * 0.12 +
			sin(TAU * (110.0 + sweep) * t) * 0.09 +
			sin(TAU * 155.56 * t) * 0.05
		) * (0.8 + 0.2 * sin(t * 1.8))
		
		# Эхо капель воды в пещере (высокие резонансные звоны)
		var drip: float = 0.0
		var drip_times: Array[float] = [1.8, 4.6, 7.5, 10.3]
		var drip_freqs: Array[float] = [1320.0, 987.0, 1480.0, 1174.0]
		for d in range(drip_times.size()):
			var dt_d: float = drip_times[d]
			if t >= dt_d and t < dt_d + 0.4:
				var el: float = t - dt_d
				drip += sin(TAU * drip_freqs[d] * el) * exp(-el * 12.0) * 0.12
		
		samples[i] = (kick + bass + pad + drip) * 0.9
	
	_apply_loop_crossfade(samples, 1200)
	return _create_wav_16(samples, rate, true)

func _synth_music_boss() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 8.0
	var count: int = int(dur * rate)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	
	# Боевой темп 135 BPM (1 четверть = 0.4444 сек)
	var beat_len: float = 0.44444
	var sixteenth: float = beat_len * 0.25
	
	for i in range(count):
		var t: float = float(i) / float(rate)
		
		# Тяжелые боевые барабаны (War Drum Kick на четвертях)
		var b_prog: float = fmod(t, beat_len) / beat_len
		var kick: float = sin(TAU * lerpf(120.0, 45.0, b_prog)) * exp(-b_prog * 12.0) * 0.35
		
		# Малый барабан / хлыст на слабую долю (Backbeat Snare)
		var snare: float = 0.0
		var half_prog: float = fmod(t, beat_len * 2.0)
		if half_prog >= beat_len:
			var s_p: float = (half_prog - beat_len) / beat_len
			var noise_val: float = randf_range(-1.0, 1.0)
			snare = (noise_val * 0.6 + sin(TAU * 220.0 * t) * 0.4) * exp(-s_p * 15.0) * 0.28
		
		# Быстрый драйвовый 16-й ритм шейкера
		var s_prog: float = fmod(t, sixteenth) / sixteenth
		var hihat: float = randf_range(-1.0, 1.0) * exp(-s_prog * 22.0) * 0.08
		
		# Агрессивная пульсирующая 16-я басовая линия
		var step_16: int = int(t / sixteenth) % 16
		var b_freq: float = 73.42 # D2
		if step_16 == 6 or step_16 == 14:
			b_freq = 87.31 # F2
		elif step_16 == 7 or step_16 == 15:
			b_freq = 98.00 # G2
		elif step_16 == 3 or step_16 == 11:
			b_freq = 65.41 # C2
		var bass: float = (sin(TAU * b_freq * t) * 0.6 + sin(TAU * b_freq * 0.5 * t) * 0.4) * exp(-s_prog * 8.0) * 0.32
		
		# Драматичные медные оркестровые аккорды (Stabs) на тактах
		var stab: float = 0.0
		var measure: float = fmod(t, 2.0)
		if measure < 0.6:
			var stab_env: float = exp(-measure * 4.0)
			# Медный тембр: D minor -> F minor -> G minor -> A dim
			var m_idx: int = int(t / 2.0) % 4
			var root_f: float = 146.83
			if m_idx == 1: root_f = 174.61
			elif m_idx == 2: root_f = 196.00
			elif m_idx == 3: root_f = 220.00
			stab = (
				sin(TAU * root_f * t) * 0.45 +
				sin(TAU * root_f * 1.5 * t) * 0.35 +
				sin(TAU * root_f * 2.0 * t) * 0.25
			) * stab_env * 0.32
		
		samples[i] = (kick + snare + hihat + bass + stab) * 0.88
	
	_apply_loop_crossfade(samples, 1000)
	return _create_wav_16(samples, rate, true)
