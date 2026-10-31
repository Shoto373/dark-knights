class_name DungeonDoor
extends Area2D

## Дверь между комнатами

signal door_entered(direction: Vector2i)

@export var direction: Vector2i = Vector2i.UP
@export var is_open: bool = true:
	set(val):
		is_open = val
		_update_door_state()

@onready var barrier_collider: StaticBody2D = %BarrierCollider
@onready var door_visual: ColorRect = %DoorVisual
@onready var status_light: ColorRect = %StatusLight

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Слушает игрока (слой 2)
	body_entered.connect(_on_body_entered)
	_setup_door_dimensions()
	_update_door_state()

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
		door_visual.color = Color(0.2, 0.6, 0.3, 0.8)
		status_light.color = Color(0.3, 1.0, 0.4, 1.0)
	else:
		barrier_collider.set_collision_layer_value(1, true)
		barrier_collider.set_collision_mask_value(2, true)
		door_visual.color = Color(0.7, 0.15, 0.15, 0.9)
		status_light.color = Color(1.0, 0.2, 0.2, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if is_open and body is Player:
		door_entered.emit(direction)

