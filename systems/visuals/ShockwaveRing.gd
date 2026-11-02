class_name ShockwaveRing
extends Node2D

## Процедурная круговая ударная волна (Expanding Circular Shockwave)
## Никаких ColorRect и прямоугольных артефактов — только плавные светящиеся круговые дуги с Vulkan HDR Bloom

@export var max_radius: float = 120.0
@export var ring_color: Color = Color(1.8, 1.6, 1.2, 0.85)
@export var thickness: float = 3.5

var current_radius: float = 5.0
var current_alpha: float = 1.0

func setup(radius: float, duration: float = 0.26, color: Color = Color(1.8, 1.6, 1.2, 0.85)) -> void:
	max_radius = radius
	ring_color = color
	current_radius = 6.0
	current_alpha = 0.95
	z_index = 1
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_method(func(r: float):
		current_radius = r
		queue_redraw()
	, 6.0, max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_method(func(a: float):
		current_alpha = a
		queue_redraw()
	, 0.95, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	if current_radius <= 1.0 or current_alpha <= 0.01:
		return
	
	# Ядро волны с ярким свечением (HDR > 1.0 для Vulkan Bloom)
	var col_outer: Color = Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * current_alpha)
	var col_glow: Color = Color(ring_color.r * 1.3, ring_color.g * 1.3, ring_color.b * 1.3, ring_color.a * 0.35 * current_alpha)
	
	var w: float = maxf(1.0, thickness * (1.0 - (current_radius / max_radius) * 0.4))
	
	# Мягкий внешний сияющий ореол
	draw_arc(Vector2.ZERO, current_radius + 2.5, 0.0, TAU, 40, col_glow, w + 3.0)
	# Основное четкое кольцо ударной волны
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 40, col_outer, w)
	# Внутренний спад волны
	if current_radius > 6.0:
		draw_arc(Vector2.ZERO, maxf(1.0, current_radius - 2.5), 0.0, TAU, 36, col_glow, w * 0.6)
