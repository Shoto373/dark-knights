class_name CastCircleVisual
extends Node2D

## Процедурный магический рунический круг под ногами персонажа при касте способностей

@export var circle_color: Color = Color(1.0, 0.85, 0.35)
@export var radius: float = 32.0

func _ready() -> void:
	scale = Vector2(0.25, 0.25)
	modulate.a = 0.95
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(45.0), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var col_outer: Color = circle_color.lightened(0.2)
	col_outer.a = 0.85
	var col_inner: Color = circle_color
	col_inner.a = 0.5
	var col_fill: Color = circle_color
	col_fill.a = 0.12
	
	# Полупрозрачное заполнение ядра
	draw_circle(Vector2.ZERO, radius, col_fill)
	
	# Внешнее руническое кольцо
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, col_outer, 2.0)
	
	# Внутреннее концентрическое кольцо
	draw_arc(Vector2.ZERO, radius * 0.55, 0.0, TAU, 24, col_inner, 1.4)
	
	# 8 рунических лучей / радиальных перекрестий
	for i in range(8):
		var ang: float = (float(i) / 8.0) * TAU
		var p1: Vector2 = Vector2(cos(ang), sin(ang)) * (radius * 0.4)
		var p2: Vector2 = Vector2(cos(ang), sin(ang)) * radius
		draw_line(p1, p2, col_outer, 1.2)
		
		# Маленькие рунические узлы на внешнем кольце
		var p_node: Vector2 = Vector2(cos(ang), sin(ang)) * radius
		draw_circle(p_node, 2.0, col_outer)
