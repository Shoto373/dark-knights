class_name TrollKingBoss
extends CharacterBody2D

## Босс биома 2: Король троллей
## Механики: удар по земле с радиальной ударной волной, бросок валуна, регенерация, сбиваемая огнём.

signal phase_changed(new_phase: int)
signal boss_defeated
signal regeneration_interrupted

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")
const ITEM_PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var attack_shape: CollisionShape2D = %AttackShape
@onready var visuals: Node2D = %Visuals
@onready var crown_rect: ColorRect = %CrownRect
@onready var flame_fx: ColorRect = %FlameFx
@onready var regen_fx: ColorRect = %RegenFx

@export var boss_data: BossData

var player_target: Node2D = null
var current_phase: int = 1

# Таймеры способностей
var attack_timer: float = 0.0
var slam_timer: float = 3.5
var boulder_timer: float = 2.0

var is_acting: bool = false

# Регенерация и статус горения
var time_since_damage: float = 2.0
var regen_tick_timer: float = 0.0
var is_burning: bool = false
var burn_timer: float = 0.0
var regen_heal_amount: int = 10

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")
	
	collision_layer = 4 # enemies
	collision_mask = 1 | 4
	
	attack_hitbox.is_player_hitbox = false
	attack_hitbox.source_owner = self
	attack_shape.disabled = true
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.is_player_hurtbox = false
	hurtbox_component.hit_received.connect(_on_hit_received)
	
	if boss_data == null:
		boss_data = load("res://data/enemies/boss_troll_king.tres") as BossData
	
	if boss_data != null:
		health_component.max_health = boss_data.max_hp
		health_component.reset(boss_data.max_hp)
		movement_component.max_speed = boss_data.speed
		hurtbox_component.armor = boss_data.armor
		attack_hitbox.base_damage = boss_data.damage
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	flame_fx.visible = false
	regen_fx.visible = false
	
	EventBus.boss_spawned.emit(boss_data.name if boss_data else "Король троллей", health_component.max_health)

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return
	
	# Поиск цели (игрока)
	if not is_instance_valid(player_target):
		for p in get_tree().get_nodes_in_group("player"):
			player_target = p as Node2D
			break
	
	# Обработка горения (сбивающего регенерацию)
	if is_burning:
		burn_timer -= delta
		flame_fx.visible = true
		flame_fx.color = Color(1.0, randf_range(0.3, 0.7), 0.1, 0.8)
		if burn_timer <= 0.0:
			is_burning = false
			flame_fx.visible = false
	
	# Пассивная регенерация (сбивается огнём или свежим уроном)
	time_since_damage += delta
	if not is_burning and time_since_damage >= 2.0:
		if health_component.current_health < health_component.max_health:
			regen_tick_timer += delta
			if regen_tick_timer >= 1.5:
				regen_tick_timer = 0.0
				health_component.heal(regen_heal_amount)
				EventBus.boss_health_changed.emit(health_component.current_health, health_component.max_health)
				_flash_regen_pulse()
	
	if is_acting:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if attack_timer > 0.0:
		attack_timer -= delta
	if slam_timer > 0.0:
		slam_timer -= delta
	if boulder_timer > 0.0:
		boulder_timer -= delta
	
	if is_instance_valid(player_target):
		var to_player: Vector2 = player_target.global_position - global_position
		var dist: float = to_player.length()
		var dir: Vector2 = to_player.normalized()
		
		if slam_timer <= 0.0 and dist <= 180.0:
			_perform_ground_slam()
		elif boulder_timer <= 0.0:
			_perform_boulder_toss(dir)
		elif dist <= 75.0 and attack_timer <= 0.0:
			_melee_club_smash(dir)
		else:
			movement_component.move(self, dir, delta)

func _on_hit_received(_dmg: int, _crit: bool, hitbox: HitboxComponent) -> void:
	time_since_damage = 0.0
	# Огненный урон сбивает регенерацию Короля троллей
	if hitbox != null and (hitbox.damage_type == "fire" or hitbox.tags.has("fire")):
		is_burning = true
		burn_timer = 5.0
		flame_fx.visible = true
		regeneration_interrupted.emit()
		EventBus.screen_shake_requested.emit(5.0, 0.15)

func _on_damaged(_amount: int, current_hp: int, max_hp: int) -> void:
	time_since_damage = 0.0
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	_flash_red()
	
	if current_phase == 1 and current_hp <= (max_hp / 2):
		_enter_phase_2()

func _enter_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	
	movement_component.max_speed *= 1.3
	attack_hitbox.base_damage = int(round(attack_hitbox.base_damage * 1.25))
	regen_heal_amount = 15
	
	EventBus.screen_shake_requested.emit(14.0, 0.5)
	crown_rect.color = Color(1.0, 0.2, 0.1, 1.0)
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.2, 0.8, 0.3, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.5)

func _flash_red() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.2, 0.3, 0.3, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)

func _flash_regen_pulse() -> void:
	regen_fx.visible = true
	var tween: Tween = create_tween()
	regen_fx.modulate = Color(0.2, 2.5, 0.6, 0.8)
	tween.tween_property(regen_fx, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func(): regen_fx.visible = false)

func _melee_club_smash(dir: Vector2) -> void:
	attack_timer = 1.2 if current_phase == 1 else 0.9
	is_acting = true
	
	# Замах булавой
	var tween: Tween = create_tween()
	visuals.scale = Vector2(1.15, 0.9)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.2)
	tween.tween_callback(func():
		attack_hitbox.rotation = dir.angle()
		attack_hitbox.reset_hits()
		attack_shape.disabled = false
		EventBus.screen_shake_requested.emit(6.0, 0.2)
	)
	tween.tween_property(self, "position", position + dir * 30.0, 0.12)
	tween.tween_callback(func():
		attack_shape.disabled = true
		is_acting = false
	)
	tween.tween_property(self, "position", position, 0.15)

func _perform_ground_slam() -> void:
	slam_timer = 4.5 if current_phase == 1 else 3.2
	is_acting = true
	
	# Подготовка к удару по земле (прыжок вверх)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "position:y", -30.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		# Удар по земле
		EventBus.screen_shake_requested.emit(12.0, 0.4)
		_spawn_radial_shockwave()
		is_acting = false
	)

func _spawn_radial_shockwave() -> void:
	var wave_count: int = 8 if current_phase == 1 else 12
	var angle_step: float = TAU / float(wave_count)
	
	for i in range(wave_count):
		var angle: float = i * angle_step
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position
		proj.setup(
			dir,
			260.0,
			16,
			false,
			450.0,
			220.0,
			Color(0.9, 0.7, 0.3, 1.0)
		)

func _perform_boulder_toss(dir: Vector2) -> void:
	boulder_timer = 3.2 if current_phase == 1 else 2.4
	is_acting = true
	
	# Замах с валуном
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.8, 1.4, 0.8, 1.0)
	tween.tween_interval(0.35)
	tween.tween_callback(func():
		visuals.modulate = Color.WHITE
		_throw_giant_boulder(dir)
		is_acting = false
	)

func _throw_giant_boulder(dir: Vector2) -> void:
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 35.0
	proj.scale = Vector2(2.2, 2.2)
	proj.setup(
		dir,
		360.0,
		boss_data.damage if boss_data else 25,
		false,
		550.0,
		260.0,
		Color(0.55, 0.48, 0.38, 1.0)
	)

func _on_died() -> void:
	remove_from_group("bosses")
	remove_from_group("enemies")
	attack_shape.disabled = true
	flame_fx.visible = false
	regen_fx.visible = false
	
	EventBus.boss_defeated.emit(boss_data.name if boss_data else "Король троллей")
	boss_defeated.emit()
	
	if boss_data != null:
		GameState.add_gold(boss_data.gold_reward)
		MetaProgress.add_souls(boss_data.souls_reward)
	
	# Спавн выбора 1 из 3 благословений
	_spawn_blessing_choice()
	
	# Спавн портала перехода
	_spawn_exit_portal()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.8)
	tween.chain().tween_callback(queue_free)

func _spawn_blessing_choice() -> void:
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	if loot_table == null:
		return
	
	var choices: Array[ItemData] = loot_table.roll_multiple_unique(3, GameState.rng)
	var x_offsets: Array[float] = [-140.0, 0.0, 140.0]
	
	for i in range(choices.size()):
		var ped: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		get_parent().add_child(ped)
		ped.global_position = global_position + Vector2(x_offsets[i], 30.0)
		ped.setup(choices[i], 0, true)

func _spawn_exit_portal() -> void:
	var portal_scene = load("res://levels/Portal.tscn")
	var portal = portal_scene.instantiate()
	get_parent().add_child(portal)
	portal.global_position = global_position + Vector2(0, -90.0)
	portal.prompt_label.text = "[F] Перейти в Замок скелетов"

