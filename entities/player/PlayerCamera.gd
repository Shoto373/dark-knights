class_name PlayerCamera
extends Camera2D

## Камера AAA-класса: динамический предиктивный прицел (Aim Lead),
## отдача от атак (Kickback), кинематографический зум напряжения и screen shake

@export var target: Node2D
@export var follow_speed: float = 8.0
@export var is_room_locked: bool = false
@export var room_center: Vector2 = Vector2(640, 360)
@export var max_aim_lead: float = 38.0
@export var default_zoom: float = 1.04

var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var total_shake_duration: float = 0.0
var pan_tween: Tween
var zoom_tween: Tween

var _kick_offset: Vector2 = Vector2.ZERO
var _current_aim_lead: Vector2 = Vector2.ZERO
var _target_zoom: float = 1.04

func _ready() -> void:
	zoom = Vector2(default_zoom, default_zoom)
	_target_zoom = default_zoom
	EventBus.screen_shake_requested.connect(add_shake)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	if target == null and not is_room_locked:
		target = get_parent() as Node2D

func _process(delta: float) -> void:
	# Находим игрока для предиктивного сдвига камеры (Aim Lead)
	if not is_instance_valid(target):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target = players[0] as Node2D
	
	var desired_lead: Vector2 = Vector2.ZERO
	if is_instance_valid(target):
		var aim_dir: Vector2 = Vector2.ZERO
		if "aim_direction" in target:
			aim_dir = target.get("aim_direction")
		elif target is CharacterBody2D:
			aim_dir = (get_global_mouse_position() - target.global_position).normalized()
		
		# Предиктивное смещение камеры по направлению прицеливания и движения
		var move_bias: Vector2 = Vector2.ZERO
		if target is CharacterBody2D and target.velocity.length_squared() > 100.0:
			move_bias = target.velocity.normalized() * 0.35
		
		desired_lead = (aim_dir * 0.65 + move_bias).limit_length(1.0) * max_aim_lead
	
	_current_aim_lead = _current_aim_lead.lerp(desired_lead, delta * 5.0)
	
	if is_room_locked:
		if pan_tween == null or not pan_tween.is_running():
			global_position = room_center + _current_aim_lead
	elif is_instance_valid(target):
		var target_pos: Vector2 = target.global_position + _current_aim_lead
		global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Затухание отдачи (Kickback decay)
	if _kick_offset.length_squared() > 0.01:
		_kick_offset = _kick_offset.lerp(Vector2.ZERO, delta * 14.0)
	else:
		_kick_offset = Vector2.ZERO
	
	# Расчет суммарного сотрясения и отдачи
	var shake_offset: Vector2 = Vector2.ZERO
	if shake_timer > 0.0:
		shake_timer -= delta
		if shake_timer > 0.0:
			var current_power: float = shake_intensity * clampf(shake_timer / maxf(0.001, total_shake_duration), 0.0, 1.0)
			shake_offset = Vector2(
				randf_range(-current_power, current_power),
				randf_range(-current_power, current_power)
			)
		else:
			shake_timer = 0.0
			shake_intensity = 0.0
			total_shake_duration = 0.0
	
	offset = shake_offset + _kick_offset

func add_kick(direction: Vector2, force: float = 6.0) -> void:
	_kick_offset += direction.normalized() * force

func set_tension_zoom(target_z: float, duration: float = 0.4) -> void:
	_target_zoom = target_z
	if zoom_tween != null and zoom_tween.is_valid():
		zoom_tween.kill()
	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "zoom", Vector2(_target_zoom, _target_zoom), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	var hp_ratio: float = float(current_hp) / float(max_hp)
	if hp_ratio <= 0.30:
		set_tension_zoom(1.08, 0.5)
	else:
		set_tension_zoom(default_zoom, 0.5)

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
