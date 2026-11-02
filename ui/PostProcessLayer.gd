class_name PostProcessLayer
extends CanvasLayer

## Полноэкранный слой пост-обработки на Vulkan Forward+
## Управляет виньеткой, атмосферой биома, хроматической аберрацией при ударах и пульсом низкого HP

@onready var color_rect: ColorRect = %ColorRect

var _material: ShaderMaterial
var _ca_tween: Tween
var _hp_tween: Tween

func _ready() -> void:
	layer = 95 # Под HUD (100) и модальными окнами, но над всеми объектами мира
	_material = color_rect.material as ShaderMaterial
	
	EventBus.screen_shake_requested.connect(_on_screen_shake)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_health_changed.connect(update_hp_pulse)
	
	if SettingsManager.has_signal("graphics_settings_changed"):
		SettingsManager.graphics_settings_changed.connect(_on_settings_changed)
	
	_on_settings_changed()

func setup_biome(biome_id: String) -> void:
	if _material == null:
		return
	
	match biome_id:
		"fire_world", "fire_mines":
			_material.set_shader_parameter("biome_tint", Color(1.15, 0.88, 0.72, 1.0))
			_material.set_shader_parameter("biome_tint_strength", 0.18)
			_material.set_shader_parameter("vignette_intensity", 0.44)
			_material.set_shader_parameter("vignette_radius", 0.88)
		"frost_world", "frost_caves":
			_material.set_shader_parameter("biome_tint", Color(0.82, 0.95, 1.2, 1.0))
			_material.set_shader_parameter("biome_tint_strength", 0.22)
			_material.set_shader_parameter("vignette_intensity", 0.40)
			_material.set_shader_parameter("vignette_radius", 0.85)
		"skeleton_castle":
			_material.set_shader_parameter("biome_tint", Color(0.88, 1.08, 0.92, 1.0))
			_material.set_shader_parameter("biome_tint_strength", 0.15)
			_material.set_shader_parameter("vignette_intensity", 0.48)
			_material.set_shader_parameter("vignette_radius", 0.82)
		"purgatory":
			_material.set_shader_parameter("biome_tint", Color(1.18, 0.82, 1.25, 1.0))
			_material.set_shader_parameter("biome_tint_strength", 0.24)
			_material.set_shader_parameter("vignette_intensity", 0.54)
			_material.set_shader_parameter("vignette_radius", 0.78)
		"troll_gorge":
			_material.set_shader_parameter("biome_tint", Color(0.92, 0.98, 0.88, 1.0))
			_material.set_shader_parameter("biome_tint_strength", 0.12)
			_material.set_shader_parameter("vignette_intensity", 0.38)
			_material.set_shader_parameter("vignette_radius", 0.86)
		_:
			# Goblin dungeon & Hub
			_material.set_shader_parameter("biome_tint", Color(1.05, 0.98, 0.9, 1.0))
			_material.set_shader_parameter("biome_tint_strength", 0.08)
			_material.set_shader_parameter("vignette_intensity", 0.36)
			_material.set_shader_parameter("vignette_radius", 0.88)

func pulse_chromatic_aberration(strength: float = 0.009, duration: float = 0.16) -> void:
	if _material == null or not visible:
		return
	if _ca_tween != null and _ca_tween.is_valid():
		_ca_tween.kill()
	
	_material.set_shader_parameter("ca_offset", strength)
	_ca_tween = create_tween()
	_ca_tween.tween_method(func(val: float):
		if is_instance_valid(self) and _material != null:
			_material.set_shader_parameter("ca_offset", val)
	, strength, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func update_hp_pulse(current_hp: int, max_hp: int) -> void:
	if _material == null:
		return
	var ratio: float = float(current_hp) / float(maxi(1, max_hp))
	if ratio <= 0.28:
		if _hp_tween == null or not _hp_tween.is_running():
			if _hp_tween != null and _hp_tween.is_valid():
				_hp_tween.kill()
			_hp_tween = create_tween().set_loops()
			_hp_tween.tween_method(func(val: float):
				if is_instance_valid(self) and _material != null:
					_material.set_shader_parameter("low_hp_pulse", val)
			, 0.2, 0.85, 0.55).set_trans(Tween.TRANS_SINE)
			_hp_tween.tween_method(func(val: float):
				if is_instance_valid(self) and _material != null:
					_material.set_shader_parameter("low_hp_pulse", val)
			, 0.85, 0.2, 0.55).set_trans(Tween.TRANS_SINE)
	else:
		if _hp_tween != null and _hp_tween.is_valid():
			_hp_tween.kill()
		_material.set_shader_parameter("low_hp_pulse", 0.0)

func _on_screen_shake(intensity: float, _duration: float) -> void:
	pulse_chromatic_aberration(clampf(intensity * 0.0012, 0.004, 0.015), 0.14)

func _on_damage_dealt(target: Node2D, amount: int, _is_crit: bool) -> void:
	if target is Player:
		pulse_chromatic_aberration(0.012, 0.22)
		var p: Player = target as Player
		if p.health_component != null:
			update_hp_pulse(p.health_component.current_health, p.health_component.max_health)
	elif _is_crit:
		pulse_chromatic_aberration(0.007, 0.12)

func _on_settings_changed() -> void:
	visible = SettingsManager.postprocessing_enabled
