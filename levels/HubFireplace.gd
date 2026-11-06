class_name HubFireplace
extends StaticBody2D

## Декоративный камин в Хабе с мерцающим светом и потрескиванием огня

@onready var light_glow: Sprite2D = get_node_or_null("LightGlow") as Sprite2D
var _flicker_phase: float = randf_range(0.0, 10.0)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

func _process(delta: float) -> void:
	_flicker_phase += delta * 7.5
	if light_glow != null:
		var pulse: float = 0.85 + sin(_flicker_phase) * 0.12 + randf() * 0.05
		light_glow.scale = Vector2(2.2, 1.8) * pulse
