class_name PlayerCamera
extends Camera2D

## Камера игрока с плавным следованием и screen shake

@export var target: Node2D
@export var follow_speed: float = 10.0

var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready() -> void:
	EventBus.screen_shake_requested.connect(add_shake)
	if target == null:
		target = get_parent() as Node2D

func _process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
	
	if shake_timer > 0.0:
		shake_timer -= delta
		var current_power: float = shake_intensity * (shake_timer / maxf(0.001, shake_timer + delta))
		offset = Vector2(
			randf_range(-current_power, current_power),
			randf_range(-current_power, current_power)
		)
	else:
		offset = Vector2.ZERO

func add_shake(intensity: float, duration: float) -> void:
	shake_intensity = maxf(shake_intensity, intensity)
	shake_timer = maxf(shake_timer, duration)
