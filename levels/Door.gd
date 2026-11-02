class_name DungeonDoor
extends Area2D

## Темные готические ворота между комнатами подземелья (Кованая железная решетка и руническая печать)

signal door_entered(direction: Vector2i)

@export var direction: Vector2i = Vector2i.UP
@export var is_open: bool = true:
	set(val):
		is_open = val
		_update_door_state()

@onready var barrier_collider: StaticBody2D = %BarrierCollider
@onready var door_visual: ColorRect = %DoorVisual
@onready var status_light: ColorRect = %StatusLight

var _pulse_time: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Слушает игрока (слой 2)
	body_entered.connect(_on_body_entered)
	if door_visual != null:
		door_visual.visible = false
	if status_light != null:
		status_light.visible = false
	_setup_door_dimensions()
	_update_door_state()

func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

func _setup_door_dimensions() -> void:
	var trig_shape: CollisionShape2D = get_node_or_null("TriggerCollision") as CollisionShape2D
	var bar_shape: CollisionShape2D = get_node_or_null("BarrierCollider/BarrierShape") as CollisionShape2D
	
	var is_horizontal: bool = (direction.y != 0)
	var door_size: Vector2 = Vector2(96, 40) if is_horizontal else Vector2(40, 96)
	
	if trig_shape != null:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = door_size
		trig_shape.shape = rect
		
	if bar_shape != null:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = door_size
		bar_shape.shape = rect
	
	if door_visual != null:
		door_visual.size = door_size
		door_visual.position = -door_size / 2.0

func _update_door_state() -> void:
	if not is_node_ready():
		return
	
	if is_open:
		barrier_collider.set_collision_layer_value(1, false)
		barrier_collider.set_collision_mask_value(2, false)
	else:
		barrier_collider.set_collision_layer_value(1, true)
		barrier_collider.set_collision_mask_value(2, true)
	queue_redraw()

func _draw() -> void:
	var is_horizontal: bool = (direction.y != 0)
	var sz: Vector2 = Vector2(96, 40) if is_horizontal else Vector2(40, 96)
	var r: Rect2 = Rect2(-sz / 2.0, sz)
	
	if is_open:
		# Мягкий изумрудно-рунический открытый проход
		var pulse_alpha: float = 0.55 + sin(_pulse_time * 3.0) * 0.15
		draw_rect(r, Color(0.08, 0.28, 0.18, pulse_alpha))
		draw_rect(r, Color(0.3, 0.85, 0.45, 0.8), false, 2.0)
		
		# Светящаяся полоса порога
		if is_horizontal:
			draw_line(Vector2(-sz.x/2.0 + 6, 0), Vector2(sz.x/2.0 - 6, 0), Color(0.6, 1.0, 0.7, 0.9), 2.5)
		else:
			draw_line(Vector2(0, -sz.y/2.0 + 6), Vector2(0, sz.y/2.0 - 6), Color(0.6, 1.0, 0.7, 0.9), 2.5)
	else:
		# Кованая железная решетка ворот (Portcullis)
		draw_rect(r, Color(0.06, 0.07, 0.1, 0.95))
		
		# Багровый рунический барьер блокировки
		var bar_pulse: float = 0.75 + sin(_pulse_time * 4.0) * 0.2
		draw_rect(r, Color(0.9, 0.18, 0.18, bar_pulse), false, 2.0)
		
		# Железные прутья решетки
		if is_horizontal:
			var bar_spacing: float = 14.0
			var start_x: float = -sz.x / 2.0 + bar_spacing
			while start_x < sz.x / 2.0 - 6.0:
				draw_line(Vector2(start_x, -sz.y/2.0), Vector2(start_x, sz.y/2.0), Color(0.35, 0.38, 0.45, 0.9), 3.0)
				start_x += bar_spacing
			draw_line(Vector2(-sz.x/2.0, 0), Vector2(sz.x/2.0, 0), Color(0.45, 0.5, 0.58, 0.95), 4.0)
		else:
			var bar_spacing: float = 14.0
			var start_y: float = -sz.y / 2.0 + bar_spacing
			while start_y < sz.y / 2.0 - 6.0:
				draw_line(Vector2(-sz.x/2.0, start_y), Vector2(sz.x/2.0, start_y), Color(0.35, 0.38, 0.45, 0.9), 3.0)
				start_y += bar_spacing
			draw_line(Vector2(0, -sz.y/2.0), Vector2(0, sz.y/2.0), Color(0.45, 0.5, 0.58, 0.95), 4.0)
		
		# Центральная багровая печать блокировки
		draw_circle(Vector2.ZERO, 9.0, Color(0.9, 0.12, 0.15, 0.95))
		draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.7, 0.7, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if is_open and body is Player:
		door_entered.emit(direction)
