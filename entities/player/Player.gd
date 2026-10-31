class_name Player
extends CharacterBody2D

## Персонаж игрока

@onready var movement_component: MovementComponent = %MovementComponent
@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var weapon_pivot: Node2D = %WeaponPivot
@onready var weapon_hitbox: HitboxComponent = %WeaponHitbox
@onready var attack_collision: CollisionShape2D = %AttackCollision
@onready var visuals: Node2D = %Visuals
@onready var dash_timer: Timer = %DashTimer
@onready var dash_cooldown_timer: Timer = %DashCooldownTimer
@onready var attack_timer: Timer = %AttackTimer
@onready var iframes_timer: Timer = %IframesTimer

@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.8
@export var attack_cooldown: float = 0.32
@export var iframes_duration: float = 0.6

var is_dashing: bool = false
var can_attack: bool = true
var dash_direction: Vector2 = Vector2.RIGHT
var aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	collision_layer = 2 # Слой 2: player
	collision_mask = 1  # Слой 1: world
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.is_player_hurtbox = true
	
	weapon_hitbox.is_player_hitbox = true
	weapon_hitbox.source_owner = self
	attack_collision.disabled = true
	
	dash_timer.wait_time = dash_duration
	dash_timer.one_shot = true
	dash_timer.timeout.connect(_on_dash_finished)
	
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.one_shot = true
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	
	iframes_timer.wait_time = iframes_duration
	iframes_timer.one_shot = true
	iframes_timer.timeout.connect(_on_iframes_finished)
	
	health_component.damaged.connect(_on_health_damaged)
	health_component.healed.connect(_on_health_healed)
	health_component.died.connect(_on_health_died)
	
	# Обновляем глобальное состояние HP
	GameState.current_hp = health_component.current_health
	GameState.max_hp = health_component.max_health
	EventBus.player_spawned.emit(self)
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)

func _process(delta: float) -> void:
	if health_component.is_dead:
		return
	_update_aim()
	_handle_input()
	_update_iframes_blink(delta)

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
	else:
		var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		movement_component.move(self, input_vector, delta)

func _update_aim() -> void:
	# Определение направления прицеливания: мышь или геймпад
	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = (mouse_pos - global_position)
	if to_mouse.length_squared() > 100.0:
		aim_direction = to_mouse.normalized()
	
	weapon_pivot.rotation = aim_direction.angle()
	
	# Разворот спрайта влево/вправо
	if aim_direction.x < 0:
		visuals.scale.x = -1.0
	elif aim_direction.x > 0:
		visuals.scale.x = 1.0

func _handle_input() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer.is_stopped() and not is_dashing:
		_start_dash()
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_dashing:
		_perform_attack()

func _start_dash() -> void:
	is_dashing = true
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		dash_direction = input_vector.normalized()
	else:
		dash_direction = aim_direction
	
	health_component.set_invulnerable(true)
	visuals.modulate.a = 0.5
	dash_timer.start()
	dash_cooldown_timer.start()

func _on_dash_finished() -> void:
	is_dashing = false
	if iframes_timer.is_stopped():
		health_component.set_invulnerable(false)
		visuals.modulate.a = 1.0

func _perform_attack() -> void:
	can_attack = false
	attack_timer.start()
	weapon_hitbox.reset_hits()
	attack_collision.disabled = false
	
	# Анимация дуги взмаха оружием через твин
	var base_angle: float = aim_direction.angle()
	weapon_pivot.rotation = base_angle - deg_to_rad(65.0)
	
	var tween: Tween = create_tween()
	tween.tween_property(weapon_pivot, "rotation", base_angle + deg_to_rad(65.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): attack_collision.disabled = true)
	tween.tween_property(weapon_pivot, "rotation", base_angle, 0.08)

func _on_attack_cooldown_finished() -> void:
	can_attack = true

func _on_health_damaged(amount: int, current_hp: int, max_hp: int) -> void:
	GameState.current_hp = current_hp
	GameState.max_hp = max_hp
	EventBus.player_health_changed.emit(current_hp, max_hp)
	
	# Запуск i-frames после получения урона
	health_component.set_invulnerable(true)
	iframes_timer.start()

func _on_health_healed(amount: int, current_hp: int, max_hp: int) -> void:
	GameState.current_hp = current_hp
	GameState.max_hp = max_hp
	EventBus.player_health_changed.emit(current_hp, max_hp)

func _on_health_died() -> void:
	GameState.current_hp = 0
	EventBus.player_health_changed.emit(0, health_component.max_health)
	EventBus.player_died.emit()
	visuals.modulate = Color(0.8, 0.2, 0.2, 0.6)

var _blink_timer: float = 0.0
func _update_iframes_blink(delta: float) -> void:
	if not iframes_timer.is_stopped() and not is_dashing:
		_blink_timer += delta * 25.0
		visuals.modulate.a = 0.3 if int(_blink_timer) % 2 == 0 else 0.9
	elif not is_dashing and not health_component.is_dead:
		visuals.modulate.a = 1.0

func _on_iframes_finished() -> void:
	if not is_dashing:
		health_component.set_invulnerable(false)
		visuals.modulate.a = 1.0

func get_dash_cooldown_ratio() -> float:
	if dash_cooldown_timer.is_stopped():
		return 1.0
	return 1.0 - (dash_cooldown_timer.time_left / dash_cooldown_timer.wait_time)

