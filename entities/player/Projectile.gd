class_name Projectile
extends Area2D

## Снаряд для дальних атак и способностей

@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var collision_shape: CollisionShape2D = %CollisionShape2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var max_distance: float = 600.0
var distance_traveled: float = 0.0

func _ready() -> void:
	# Снаряд врезается в стены (слой 1: world)
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func setup(
	dir: Vector2,
	proj_speed: float,
	damage: int,
	is_player: bool = true,
	max_range: float = 600.0,
	knockback: float = 200.0,
	color: Color = Color.WHITE,
	p_damage_type: String = "physical",
	p_tags: Array[String] = []
) -> void:
	direction = dir.normalized()
	speed = proj_speed
	max_distance = max_range
	rotation = direction.angle()
	
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = is_player
	hitbox.knockback_force = knockback
	hitbox.source_owner = self
	hitbox.damage_type = p_damage_type
	hitbox.tags = p_tags.duplicate()
	
	modulate = color

func _physics_process(delta: float) -> void:
	var step: Vector2 = direction * speed * delta
	global_position += step
	distance_traveled += step.length()
	
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	# Попадание в стену окружения
	queue_free()

