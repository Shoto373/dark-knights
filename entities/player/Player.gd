class_name Player
extends CharacterBody2D

## Персонаж игрока, конфигурируемый через HeroData (Data-Driven)

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")
const AOE_SCENE = preload("res://entities/player/AreaOfEffect.tscn")

@onready var movement_component: MovementComponent = %MovementComponent
@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var weapon_pivot: Node2D = %WeaponPivot
@onready var weapon_hitbox: HitboxComponent = %WeaponHitbox
@onready var attack_collision: CollisionShape2D = %AttackCollision
@onready var visuals: Node2D = %Visuals
@onready var status_effect_manager: StatusEffectManager = %StatusEffectManager
@onready var body_rect: ColorRect = $Visuals/BodyRect
@onready var dash_timer: Timer = %DashTimer
@onready var dash_cooldown_timer: Timer = %DashCooldownTimer
@onready var attack_timer: Timer = %AttackTimer
@onready var iframes_timer: Timer = %IframesTimer

@export var hero_data: HeroData
@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.8
@export var iframes_duration: float = 0.6

var is_dashing: bool = false
var can_attack: bool = true
var dash_direction: Vector2 = Vector2.RIGHT
var aim_direction: Vector2 = Vector2.RIGHT

var ability_1_timer: Timer
var ability_2_timer: Timer

func _ready() -> void:
	add_to_group("player")
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
	
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	
	iframes_timer.wait_time = iframes_duration
	iframes_timer.one_shot = true
	iframes_timer.timeout.connect(_on_iframes_finished)
	
	health_component.damaged.connect(_on_health_damaged)
	health_component.healed.connect(_on_health_healed)
	health_component.died.connect(_on_health_died)
	
	# Создаем таймеры способностей
	ability_1_timer = Timer.new()
	ability_1_timer.one_shot = true
	add_child(ability_1_timer)
	
	ability_2_timer = Timer.new()
	ability_2_timer.one_shot = true
	add_child(ability_2_timer)
	
	# Загружаем героя из данных
	if hero_data == null:
		var hero_path: String = "res://data/heroes/%s.tres" % GameState.selected_hero_id
		if ResourceLoader.exists(hero_path):
			hero_data = load(hero_path) as HeroData
		else:
			hero_data = load("res://data/heroes/warrior.tres") as HeroData
	
	apply_hero_data(hero_data)
	EventBus.player_spawned.emit(self)

func apply_hero_data(data: HeroData) -> void:
	if data == null:
		return
	hero_data = data
	
	health_component.max_health = hero_data.max_hp
	health_component.reset(hero_data.max_hp)
	movement_component.max_speed = hero_data.speed
	hurtbox_component.armor = hero_data.armor
	
	weapon_hitbox.base_damage = hero_data.attack_damage
	attack_timer.wait_time = hero_data.attack_cooldown
	
	if body_rect != null:
		body_rect.color = hero_data.color
	
	# Установка детализированного пиксель-арт спрайта героя
	var hero_id: String = hero_data.id if hero_data else "warrior"
	var hero_tex: Texture2D = SpriteGenerator.get_hero_texture(hero_id)
	if hero_tex != null and visuals != null:
		var char_sprite: Sprite2D = visuals.get_node_or_null("CharacterSprite") as Sprite2D
		if char_sprite == null:
			char_sprite = Sprite2D.new()
			char_sprite.name = "CharacterSprite"
			char_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			visuals.add_child(char_sprite)
		char_sprite.texture = hero_tex
		if body_rect != null:
			body_rect.visible = false
		if visuals.has_node("EyeRect"):
			visuals.get_node("EyeRect").visible = false
	
	if hero_data.ability_1 != null:
		ability_1_timer.wait_time = hero_data.ability_1.cooldown
	if hero_data.ability_2 != null:
		ability_2_timer.wait_time = hero_data.ability_2.cooldown
	
	recalculate_stats()

func recalculate_stats() -> void:
	if hero_data == null:
		return
	
	# Извлекаем все предметы
	var items: Array[ItemData] = []
	for inv in GameState.inventory_items:
		if inv.has("item_ref") and inv["item_ref"] is ItemData:
			items.append(inv["item_ref"])
		elif inv.has("id"):
			var it_path: String = "res://data/items/%s.tres" % inv["id"]
			if ResourceLoader.exists(it_path):
				items.append(load(it_path) as ItemData)
	
	var new_max_hp: int = int(round(StatCalculator.calculate_stat(hero_data.max_hp, items, "max_hp")))
	var new_speed: float = StatCalculator.calculate_stat(hero_data.speed, items, "speed")
	var new_armor: int = int(round(StatCalculator.calculate_stat(hero_data.armor, items, "armor")))
	var new_damage: int = int(round(StatCalculator.calculate_stat(hero_data.attack_damage, items, "damage")))
	var new_crit_chance: float = StatCalculator.calculate_stat(0.08, items, "crit_chance")
	var new_crit_mult: float = StatCalculator.calculate_stat(2.0, items, "crit_multiplier")
	
	var hp_diff: int = new_max_hp - health_component.max_health
	health_component.max_health = new_max_hp
	if hp_diff > 0:
		health_component.current_health += hp_diff
	
	movement_component.max_speed = new_speed
	hurtbox_component.armor = new_armor
	weapon_hitbox.base_damage = new_damage
	weapon_hitbox.crit_chance = new_crit_chance
	weapon_hitbox.crit_multiplier = new_crit_mult
	
	# Проверка синергий и тегов предметов (например огонь и холод)
	var tag_counts: Dictionary = StatCalculator.get_tag_counts(items)
	if tag_counts.get("fire", 0) > 0:
		weapon_hitbox.damage_type = "fire"
		if not weapon_hitbox.tags.has("fire"):
			weapon_hitbox.tags.append("fire")
	elif tag_counts.get("frost", 0) > 0:
		weapon_hitbox.damage_type = "freeze"
		if not weapon_hitbox.tags.has("frost"):
			weapon_hitbox.tags.append("frost")
		if not weapon_hitbox.tags.has("freeze"):
			weapon_hitbox.tags.append("freeze")
	
	# Проверка особых свойств артефактов (например Замерзшее сердце и Магматические сапоги)
	for it in items:
		if it is ItemData:
			if it.id == "frozen_heart":
				if status_effect_manager != null and not status_effect_manager.immunities.has("freeze"):
					status_effect_manager.immunities.append("freeze")
				movement_component.is_on_ice = false
			elif it.id == "magma_boots":
				if status_effect_manager != null:
					if not status_effect_manager.immunities.has("burn"):
						status_effect_manager.immunities.append("burn")
					if not status_effect_manager.immunities.has("fire"):
						status_effect_manager.immunities.append("fire")
	
	GameState.current_hp = health_component.current_health
	GameState.max_hp = health_component.max_health
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
	
	# Заморозка или оглушение
	if status_effect_manager != null and (status_effect_manager.is_frozen() or status_effect_manager.is_stunned()):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
	else:
		var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var spd_mult: float = status_effect_manager.get_speed_multiplier() if status_effect_manager != null else 1.0
		movement_component.move(self, input_vector * spd_mult, delta)

func _update_aim() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = (mouse_pos - global_position)
	if to_mouse.length_squared() > 100.0:
		aim_direction = to_mouse.normalized()
	
	weapon_pivot.rotation = aim_direction.angle()
	
	if aim_direction.x < 0:
		visuals.scale.x = -1.0
	elif aim_direction.x > 0:
		visuals.scale.x = 1.0

func _handle_input() -> void:
	if status_effect_manager != null and (status_effect_manager.is_frozen() or status_effect_manager.is_stunned()):
		return
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer.is_stopped() and not is_dashing:
		_start_dash()
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_dashing:
		_perform_attack()
	
	if Input.is_action_just_pressed("ability_1") and hero_data != null and hero_data.ability_1 != null:
		_trigger_ability(hero_data.ability_1, ability_1_timer)
		
	if Input.is_action_just_pressed("ability_2") and hero_data != null and hero_data.ability_2 != null:
		_trigger_ability(hero_data.ability_2, ability_2_timer)

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
	
	if hero_data != null and hero_data.attack_type == "ranged":
		_shoot_basic_projectile()
	else:
		_swing_melee_weapon()

func _swing_melee_weapon() -> void:
	weapon_hitbox.reset_hits()
	attack_collision.disabled = false
	
	var base_angle: float = aim_direction.angle()
	weapon_pivot.rotation = base_angle - deg_to_rad(65.0)
	
	var tween: Tween = create_tween()
	tween.tween_property(weapon_pivot, "rotation", base_angle + deg_to_rad(65.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): attack_collision.disabled = true)
	tween.tween_property(weapon_pivot, "rotation", base_angle, 0.08)

func _shoot_basic_projectile() -> void:
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + aim_direction * 20.0
	proj.setup(
		aim_direction,
		hero_data.projectile_speed if hero_data else 500.0,
		hero_data.attack_damage if hero_data else 20,
		true,
		hero_data.attack_range if hero_data else 500.0,
		180.0,
		hero_data.color if hero_data else Color.WHITE
	)
	if weapon_hitbox.damage_type == "fire" or weapon_hitbox.tags.has("fire"):
		proj.hitbox.damage_type = "fire"
		proj.hitbox.tags = ["fire"]

func _trigger_ability(ability: AbilityData, timer: Timer) -> void:
	if not timer.is_stopped() or is_dashing:
		return
	
	timer.start()
	match ability.effect_type:
		"buff":
			_apply_buff_ability(ability)
		"dash":
			_apply_dash_ability(ability)
		"aoe":
			_apply_aoe_ability(ability)
		"teleport":
			_apply_teleport_ability(ability)
		"projectile":
			_apply_projectile_ability(ability)

func _apply_buff_ability(ability: AbilityData) -> void:
	health_component.set_invulnerable(true)
	visuals.modulate = Color(1.5, 1.5, 0.5, 1.0)
	var tween: Tween = create_tween()
	tween.tween_interval(ability.duration)
	tween.tween_callback(func():
		if iframes_timer.is_stopped():
			health_component.set_invulnerable(false)
		visuals.modulate = Color.WHITE
	)

func _apply_dash_ability(ability: AbilityData) -> void:
	is_dashing = true
	dash_direction = aim_direction
	health_component.set_invulnerable(true)
	visuals.modulate = Color(1.5, 0.5, 0.5, 0.8)
	
	weapon_hitbox.base_damage = ability.base_damage
	weapon_hitbox.reset_hits()
	attack_collision.disabled = false
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "velocity", dash_direction * ability.speed, ability.duration)
	tween.tween_callback(func():
		is_dashing = false
		attack_collision.disabled = true
		weapon_hitbox.base_damage = hero_data.attack_damage if hero_data else 25
		health_component.set_invulnerable(false)
		visuals.modulate = Color.WHITE
	)

func _apply_aoe_ability(ability: AbilityData) -> void:
	var target_pos: Vector2 = get_global_mouse_position()
	# Ограничение дальности применения AoE
	var dist: float = (target_pos - global_position).length()
	if dist > 350.0:
		target_pos = global_position + (target_pos - global_position).normalized() * 350.0
	
	var aoe: AreaOfEffect = AOE_SCENE.instantiate() as AreaOfEffect
	get_parent().add_child(aoe)
	aoe.setup(target_pos, ability.range_or_radius, ability.base_damage, true, 400.0)
	if ability.id == "fireball" or ability.name.to_lower().contains("огн") or ability.name.to_lower().contains("fire"):
		aoe.hitbox.damage_type = "fire"
		aoe.hitbox.tags = ["fire"]

func _apply_teleport_ability(ability: AbilityData) -> void:
	var target_pos: Vector2 = global_position + aim_direction * ability.range_or_radius
	health_component.set_invulnerable(true)
	visuals.modulate.a = 0.2
	
	global_position = target_pos
	
	var tween: Tween = create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		health_component.set_invulnerable(false)
		visuals.modulate.a = 1.0
	)

func _apply_projectile_ability(ability: AbilityData) -> void:
	var count: int = ability.projectile_count
	var half_spread: float = deg_to_rad(ability.spread_angle_deg) / 2.0
	var base_angle: float = aim_direction.angle()
	
	for i in range(count):
		var angle_offset: float = 0.0
		if count > 1:
			angle_offset = -half_spread + (float(i) / float(count - 1)) * (half_spread * 2.0)
		
		var dir: Vector2 = Vector2.from_angle(base_angle + angle_offset)
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 20.0
		proj.setup(
			dir,
			ability.speed,
			ability.base_damage,
			true,
			ability.range_or_radius,
			220.0,
			hero_data.color if hero_data else Color.WHITE
		)

func _on_attack_cooldown_finished() -> void:
	can_attack = true

func _on_health_damaged(amount: int, current_hp: int, max_hp: int) -> void:
	GameState.current_hp = current_hp
	GameState.max_hp = max_hp
	EventBus.player_health_changed.emit(current_hp, max_hp)
	if status_effect_manager == null or not status_effect_manager.is_processing_dot:
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

func get_ability_cooldown_ratio(slot: int) -> float:
	var t: Timer = ability_1_timer if slot == 1 else ability_2_timer
	if t == null or t.is_stopped() or t.wait_time <= 0.0:
		return 1.0
	return 1.0 - (t.time_left / t.wait_time)
