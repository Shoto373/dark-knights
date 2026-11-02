class_name MovementComponent
extends Node

## Компонент движения с плавным ускорением, трением и отталкиванием (Knockback)

@export var max_speed: float = 200.0
@export var acceleration: float = 1400.0
@export var friction: float = 1600.0
@export var knockback_friction: float = 1400.0
@export var is_on_ice: bool = false # Скользкий лёд снижает трение в 4 раза

var move_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

func move(body: CharacterBody2D, direction: Vector2, delta: float) -> Vector2:
	if not is_instance_valid(body):
		return Vector2.ZERO
	
	var target_velocity: Vector2 = direction.normalized() * max_speed
	var current_friction: float = friction * 0.25 if is_on_ice else friction
	var current_accel: float = acceleration * 0.45 if is_on_ice else acceleration
	
	if direction != Vector2.ZERO:
		move_velocity = move_velocity.move_toward(target_velocity, current_accel * delta)
	else:
		move_velocity = move_velocity.move_toward(Vector2.ZERO, current_friction * delta)
	
	# Применяем затухание отталкивания
	if knockback_velocity.length_squared() > 1.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	else:
		knockback_velocity = Vector2.ZERO
	
	body.velocity = move_velocity + knockback_velocity
	body.move_and_slide()
	return body.velocity

func apply_knockback(force: Vector2) -> void:
	# Ограничиваем силу отталкивания, исключая нереалистичные улеты за пределы экрана
	knockback_velocity = (knockback_velocity + force).limit_length(350.0)

func stop(body: CharacterBody2D = null) -> void:
	move_velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	if is_instance_valid(body):
		body.velocity = Vector2.ZERO
