class_name DungeonEnvironment
extends WorldEnvironment

## Окружение с поддержкой Vulkan Forward+ HDR Glow, ACES Tonemapping и пост-обработки

@export var hdr_glow_enabled: bool = true:
	set(val):
		hdr_glow_enabled = val
		_apply_environment_settings()

func _ready() -> void:
	_setup_environment()
	if SettingsManager.has_signal("graphics_settings_changed"):
		SettingsManager.graphics_settings_changed.connect(_on_settings_changed)

func _setup_environment() -> void:
	if environment == null:
		environment = Environment.new()
	
	environment.background_mode = Environment.BG_CANVAS
	_apply_environment_settings()

func _apply_environment_settings() -> void:
	if environment == null:
		return
	
	var is_glow_active: bool = hdr_glow_enabled
	if "glow_enabled" in SettingsManager and not SettingsManager.glow_enabled:
		is_glow_active = false
	
	environment.glow_enabled = is_glow_active
	if is_glow_active:
		environment.glow_normalized = true
		environment.glow_intensity = 0.7
		environment.glow_strength = 1.05
		environment.glow_bloom = 0.22
		environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		environment.glow_hdr_threshold = 1.0
		environment.glow_hdr_scale = 1.6
		environment.glow_hdr_luminance_cap = 12.0
		
		# Включаем уровни свечения для богатого мягкого рассеивания
		environment.set_glow_level(1, 1.0)
		environment.set_glow_level(2, 0.8)
		environment.set_glow_level(3, 0.6)
		environment.set_glow_level(4, 0.4)
		environment.set_glow_level(5, 0.2)
	
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 1.0

func _on_settings_changed() -> void:
	_apply_environment_settings()

