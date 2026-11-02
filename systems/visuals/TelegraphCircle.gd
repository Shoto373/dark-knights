class_name TelegraphCircle
extends Node2D

## Процедурный круговой телеграф опасной зоны (Runic Warning Telegraph)
## Полная замена прямоугольных ColorRect: плавный круговой индикатор с рунической рамкой,
## заполнением тайминга удара и Vulkan HDR Bloom.

@export var radius: float = 40.0
@export var duration: float = 0.5
@export var telegraph_color: Color = Color(1.0, 0.25, 0.1, 0.45)

var _progress: float = 0.0
var _pulse_time: float = 0.0

func setup(p_radius: float, p_duration: float, p_color: Color = Color(1.0, 0.25, 0.1, 0.45)) -> void:
	radius = p_radius
	duration = p_duration
	telegraph_color = p_color
	_progress = 0.0
	z_index = 0
	
	var tween: Tween = create_tween()
	tween.tween_method(func(val: float):
		_progress = val
		queue_redraw()
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

func _draw() -> void:
	if radius <= 1.0:
		return
	
	var fill_color: Color = Color(telegraph_color.r, telegraph_color.g, telegraph_color.b, telegraph_color.a * (0.2 + _progress * 0.45))
	var ring_color: Color = Color(telegraph_color.r * 1.2, telegraph_color.g * 1.2, telegraph_color.b * 1.2, 0.85 + sin(_pulse_time * 12.0) * 0.15)
	
	# Полупрозрачное фоновое предупреждающее пятно
	draw_circle(Vector2.ZERO, radius, fill_color)
	
	# Заполняющееся внутреннее ядро удара (показывает игроку точный момент детонации)
	var fill_radius: float = radius * _progress
	if fill_radius > 1.0:
		var inner_glow: Color = Color(telegraph_color.r * 1.4, telegraph_color.g * 1.4, telegraph_color.b * 1.4, 0.45 * _progress)
		draw_circle(Vector2.ZERO, fill_radius, inner_glow)
		draw_arc(Vector2.ZERO, fill_radius, 0.0, TAU, 32, ring_color, 1.8)
	
	# Внешнее руническое кольцо границы опасности
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, ring_color, 2.5)
	
	# Рунические насечки по периметру (8 отметок)
	for i in range(8):
		var ang: float = (float(i) / 8.0) * TAU + _pulse_time * 0.5
		var p1: Vector2 = Vector2(cos(ang), sin(ang)) * (radius - 5.0)
		var p2: Vector2 = Vector2(cos(ang), sin(ang)) * (radius + 2.0)
		draw_line(p1, p2, ring_color, 1.5)

