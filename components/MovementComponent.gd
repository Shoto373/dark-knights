class_name MovementComponent
extends Node

## Компонент движения с плавным ускорением, трением и отталкиванием (Knockback)

@export var max_speed: float = 200.0
@export var acceleration: float = 1400.0
@export var friction: float = 1600.0
@export var knockback_friction: float = 800.0

var knockback_velocity: Vector2 = Vector2.ZERO

func move(body: CharacterBody2D, direction: Vector2, delta: float) -> Vector2:
	if not is_instance_valid(body):
		return Vector2.ZERO
	
	var target_velocity: Vector2 = direction.normalized() * max_speed
	
	if direction != Vector2.ZERO:
		body.velocity = body.velocity.move_toward(target_velocity, acceleration * delta)
	else:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Применяем затухание отталкивания
	if knockback_velocity.length_squared() > 1.0:
		body.velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	else:
		knockback_velocity = Vector2.ZERO
	
	body.move_and_slide()
	return body.velocity

func apply_knockback(force: Vector2) -> void:
	knockback_velocity += force

func stop(body: CharacterBody2D = null) -> void:
	knockback_velocity = Vector2.ZERO
	if is_instance_valid(body):
		body.velocity = Vector2.ZERO

