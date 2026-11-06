class_name HubFireplace
extends StaticBody2D

## Декоративный камин в Хабе с мерцающим светом и потрескиванием огня

@onready var light_glow: Sprite2D = get_node_or_null("LightGlow") as Sprite2D
var fireplace_light: PointLight2D = null
var _flicker_phase: float = randf_range(0.0, 10.0)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	
	if fireplace_light == null and SettingsManager.dynamic_lighting_enabled:
		fireplace_light = LightTextureGenerator.create_point_light(Color(1.0, 0.65, 0.25), 0.95, 3.2)
		fireplace_light.name = "FireplaceLight"
		fireplace_light.position = Vector2(0, 6.0)
		add_child(fireplace_light)

func _process(delta: float) -> void:
	_flicker_phase += delta * 7.5
	if light_glow != null:
		var pulse: float = 0.85 + sin(_flicker_phase) * 0.12 + randf() * 0.05
		light_glow.scale = Vector2(2.2, 1.8) * pulse
	if fireplace_light != null and fireplace_light.visible:
		var flicker: float = 0.88 + sin(_flicker_phase * 1.3) * 0.15 + (randf() - 0.5) * 0.08
		fireplace_light.energy = flicker * 0.95


