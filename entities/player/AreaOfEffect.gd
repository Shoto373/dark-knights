class_name AreaOfEffect
extends Node2D

## Область поражения (AoE: взрыв, огненный шар, ударная волна)

@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var circle_shape: CircleShape2D = collision_shape.shape as CircleShape2D
@onready var visual_circle: ColorRect = %VisualCircle

var radius: float = 80.0

func setup(
	pos: Vector2,
	aoe_radius: float,
	damage: int,
	is_player: bool = true,
	knockback: float = 350.0,
	color: Color = Color(1.0, 0.4, 0.1, 0.7)
) -> void:
	global_position = pos
	radius = aoe_radius
	
	circle_shape.radius = radius
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = is_player
	hitbox.knockback_force = knockback
	hitbox.source_owner = self
	
	visual_circle.offset_left = -radius
	visual_circle.offset_top = -radius
	visual_circle.offset_right = radius
	visual_circle.offset_bottom = radius
	visual_circle.color = color

func _ready() -> void:
	# Анимация расширения и затухания взрыва
	scale = Vector2.ZERO
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
