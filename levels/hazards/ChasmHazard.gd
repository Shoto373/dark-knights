class_name ChasmHazard
extends Area2D

## Обрыв / пропасть. При падении без моста и без рывка игрок получает урон и возвращается на край.

signal player_fell(player: Node2D)

@onready var visual_pit: ColorRect = $VisualPit
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var pit_size: Vector2 = Vector2(160, 240):
	set(val):
		pit_size = val
		_update_dimensions()

@export var fall_damage: int = 15

var safe_respawn_position: Vector2 = Vector2(640, 360)
var falling_players: Dictionary = {} # Player -> bool

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Игрок
	_update_dimensions()

func _update_dimensions() -> void:
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = pit_size
	if visual_pit != null:
		visual_pit.size = pit_size
		visual_pit.position = -pit_size / 2.0

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is CharacterBody2D and body.is_in_group("player"):
			_check_player_fall(body)

func _check_player_fall(player: CharacterBody2D) -> void:
	if falling_players.has(player):
		return
	
	# Если игрок на мосту — он в безопасности
	if player.is_in_group("on_bridge"):
		return
	
	# Если игрок выполняет рывок (dash) — он перелетает пропасть
	if "is_dashing" in player and player.is_dashing:
		return
	
	_trigger_fall(player)

func _trigger_fall(player: CharacterBody2D) -> void:
	falling_players[player] = true
	player_fell.emit(player)
	
	# Нанесение урона от падения
	var hc: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if hc != null:
		hc.take_damage(fall_damage)
	
	EventBus.screen_shake_requested.emit(8.0, 0.3)
	
	# Мгновенное перемещение на безопасную точку во избежание повторного застревания
	player.global_position = safe_respawn_position
	player.velocity = Vector2.ZERO
	
	# Анимация возрождения
	var initial_scale: Vector2 = player.scale
	player.scale = Vector2.ZERO
	var tween: Tween = player.create_tween()
	tween.tween_property(player, "scale", initial_scale, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(player):
			var hc_ref: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
			if hc_ref != null:
				hc_ref.set_invulnerable(true)
				var timer: SceneTreeTimer = player.get_tree().create_timer(1.2)
				timer.timeout.connect(func():
					if is_instance_valid(hc_ref):
						hc_ref.set_invulnerable(false)
				)
		falling_players.erase(player)
	)
