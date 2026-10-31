class_name BridgeArea
extends Area2D

## Мост над обрывом, позволяющий безопасно пересекать пропасть

@onready var visual_rect: ColorRect = $VisualPlanks

@export var bridge_size: Vector2 = Vector2(160, 120):
	set(val):
		bridge_size = val
		_update_dimensions()

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Игрок
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_dimensions()

func _update_dimensions() -> void:
	var shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		(shape.shape as RectangleShape2D).size = bridge_size
	
	if visual_rect != null:
		visual_rect.size = bridge_size
		visual_rect.position = -bridge_size / 2.0

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.add_to_group("on_bridge")

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("on_bridge"):
		body.remove_from_group("on_bridge")
