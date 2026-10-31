class_name PlayerCamera
extends Camera2D

## Камера игрока с плавным следованием и screen shake, поддержкой фиксации на комнате (стиль The Binding of Isaac)

@export var target: Node2D
@export var follow_speed: float = 10.0
@export var is_room_locked: bool = false
@export var room_center: Vector2 = Vector2(640, 360)

var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var total_shake_duration: float = 0.0
var pan_tween: Tween

func _ready() -> void:
	EventBus.screen_shake_requested.connect(add_shake)
	if target == null and not is_room_locked:
		target = get_parent() as Node2D

func _process(delta: float) -> void:
	if is_room_locked:
		if pan_tween == null or not pan_tween.is_running():
			global_position = room_center
	elif is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
	
	if shake_timer > 0.0:
		shake_timer -= delta
		if shake_timer > 0.0:
			var current_power: float = shake_intensity * clampf(shake_timer / maxf(0.001, total_shake_duration), 0.0, 1.0)
			offset = Vector2(
				randf_range(-current_power, current_power),
				randf_range(-current_power, current_power)
			)
		else:
			shake_timer = 0.0
			shake_intensity = 0.0
			total_shake_duration = 0.0
			offset = Vector2.ZERO
	else:
		offset = Vector2.ZERO

func lock_to_room(new_center: Vector2, smooth: bool = false, duration: float = 0.25) -> void:
	is_room_locked = true
	room_center = new_center
	if smooth:
		if pan_tween != null and pan_tween.is_valid():
			pan_tween.kill()
		pan_tween = create_tween()
		pan_tween.tween_property(self, "global_position", new_center, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		global_position = new_center

func add_shake(intensity: float, duration: float) -> void:
	shake_intensity = maxf(shake_intensity, intensity)
	shake_timer = maxf(shake_timer, duration)
	total_shake_duration = maxf(total_shake_duration, duration)
