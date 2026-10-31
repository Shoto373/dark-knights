class_name EnemyBase
extends CharacterBody2D

## Базовый класс врагов с конечным автоматом состояний (AI)

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var attack_shape: CollisionShape2D = %AttackShape
@onready var state_machine: StateMachine = %StateMachine
@onready var visuals: Node2D = %Visuals
@onready var body_rect: ColorRect = %BodyRect
@onready var hp_bar: ProgressBar = %HpBar

@export var enemy_data: EnemyData

var player_target: Node2D = null
var attack_timer: float = 0.0
var heal_cooldown_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4 # Слой 3: enemies
	collision_mask = 1 | 4 # Стены и другие враги
	
	attack_hitbox.is_player_hitbox = false
	attack_hitbox.source_owner = self
	attack_shape.disabled = true
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.is_player_hurtbox = false
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	if enemy_data != null:
		setup_from_data(enemy_data)

func setup_from_data(data: EnemyData) -> void:
	enemy_data = data
	health_component.max_health = enemy_data.max_hp
	health_component.reset(enemy_data.max_hp)
	movement_component.max_speed = enemy_data.speed
	hurtbox_component.armor = enemy_data.armor
	attack_hitbox.base_damage = enemy_data.damage
	
	body_rect.color = enemy_data.color
	hp_bar.max_value = enemy_data.max_hp
	hp_bar.value = enemy_data.max_hp

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return
	
	if attack_timer > 0.0:
		attack_timer -= delta
	if heal_cooldown_timer > 0.0:
		heal_cooldown_timer -= delta
	
	# Находим цель (игрока) если еще не найдена
	if not is_instance_valid(player_target):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_target = players[0] as Node2D
		else:
			# Ищем по типу
			for child in get_tree().root.find_children("*", "Player", true, false):
				player_target = child as Node2D
				break

func _on_damaged(_amount: int, current_hp: int, _max_hp: int) -> void:
	hp_bar.value = current_hp
	_flash_red()

func _flash_red() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.4, 0.4, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)

func _on_died() -> void:
	remove_from_group("enemies")
	attack_shape.disabled = true
	hurtbox_component.set_deferred("monitoring", false)
	
	# Начисление наград за победу над врагом
	if enemy_data != null:
		GameState.add_gold(enemy_data.gold_reward)
		if enemy_data.souls_reward > 0:
			MetaProgress.add_souls(enemy_data.souls_reward)
		GameState.run_stats["kills"] = GameState.run_stats.get("kills", 0) + 1
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.35)
	tween.chain().tween_callback(queue_free)

func perform_attack() -> void:
	if not is_instance_valid(player_target) or attack_timer > 0.0:
		return
	
	attack_timer = enemy_data.attack_cooldown if enemy_data else 1.2
	
	if enemy_data != null and enemy_data.enemy_type == "ranged":
		_shoot_arrow()
	elif enemy_data != null and enemy_data.enemy_type == "support":
		_try_heal_or_attack()
	else:
		_melee_attack()

func _melee_attack() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.reset_hits()
	attack_shape.disabled = false
	
	# Небольшой выпад вперед
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + dir * 18.0, 0.1)
	tween.tween_callback(func(): attack_shape.disabled = true)
	tween.tween_property(self, "position", position, 0.1)

func _shoot_arrow() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 20.0
	proj.setup(
		dir,
		380.0,
		enemy_data.damage if enemy_data else 10,
		false, # Вражеский снаряд!
		400.0,
		180.0,
		Color(0.85, 0.4, 0.2, 1.0)
	)

func _try_heal_or_attack() -> void:
	if heal_cooldown_timer <= 0.0:
		var wounded_ally: EnemyBase = _find_wounded_ally()
		if wounded_ally != null:
			heal_cooldown_timer = 4.0
			wounded_ally.health_component.heal(20)
			_flash_heal_effect(wounded_ally)
			return
	
	_shoot_arrow()

func _find_wounded_ally() -> EnemyBase:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyBase and enemy != self:
			var hc: HealthComponent = enemy.health_component
			if hc.current_health < hc.max_health:
				return enemy
	return null

func _flash_heal_effect(target: EnemyBase) -> void:
	var tween: Tween = target.create_tween()
	target.visuals.modulate = Color(0.3, 2.5, 0.8, 1.0)
	tween.tween_property(target.visuals, "modulate", Color.WHITE, 0.25)

