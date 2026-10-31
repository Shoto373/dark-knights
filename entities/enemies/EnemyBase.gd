class_name EnemyBase
extends CharacterBody2D

## Базовый класс врагов с конечным автоматом состояний (AI) и механиками Спринтов 4, 6, 7

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var attack_shape: CollisionShape2D = %AttackShape
@onready var state_machine: StateMachine = %StateMachine
@onready var status_effect_manager: StatusEffectManager = %StatusEffectManager
@onready var visuals: Node2D = %Visuals
@onready var body_rect: ColorRect = %BodyRect
@onready var hp_bar: ProgressBar = %HpBar

@export var enemy_data: EnemyData

var player_target: Node2D = null
var attack_timer: float = 0.0
var heal_cooldown_timer: float = 0.0
var summon_timer: float = 4.0

# Механики регенерации и горения (тролли и др.)
var time_since_damage: float = 3.0
var regen_tick_timer: float = 0.0
var is_burning: bool = false
var burn_timer: float = 0.0

# Механики скелетов и стражей (Спринт 7)
var is_collapsed: bool = false
var has_reassembled: bool = false
var reassemble_timer: float = 0.0

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
	hurtbox_component.hit_received.connect(_on_hit_received)
	
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
	
	# Установка стилизованного пиксель-арт спрайта монстра
	var enemy_tex: Texture2D = SpriteGenerator.get_enemy_texture(enemy_data.enemy_type)
	if enemy_tex != null and visuals != null:
		var enemy_sprite: Sprite2D = visuals.get_node_or_null("EnemySprite") as Sprite2D
		if enemy_sprite == null:
			enemy_sprite = Sprite2D.new()
			enemy_sprite.name = "EnemySprite"
			enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			visuals.add_child(enemy_sprite)
		enemy_sprite.texture = enemy_tex
		if body_rect != null:
			body_rect.visible = false
		if visuals.has_node("EyeLeft"):
			visuals.get_node("EyeLeft").visible = false
		if visuals.has_node("EyeRight"):
			visuals.get_node("EyeRight").visible = false
	hp_bar.max_value = enemy_data.max_hp
	hp_bar.value = enemy_data.max_hp
	
	time_since_damage = enemy_data.regen_delay_seconds
	if status_effect_manager != null and enemy_data != null:
		status_effect_manager.immunities = enemy_data.immunities

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return
	
	# Заморозка или оглушение блокируют любые действия
	if status_effect_manager != null and (status_effect_manager.is_frozen() or status_effect_manager.is_stunned()):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Если скелет рассыпался в груду костей — лежит и ждёт пересборки
	if is_collapsed:
		velocity = Vector2.ZERO
		move_and_slide()
		reassemble_timer -= delta
		if reassemble_timer <= 0.0:
			_reassemble_skeleton()
		return
	
	if attack_timer > 0.0:
		attack_timer -= delta
	if heal_cooldown_timer > 0.0:
		heal_cooldown_timer -= delta
	if summon_timer > 0.0:
		summon_timer -= delta
	
	# Статус горения (сбивает регенерацию)
	if is_burning:
		burn_timer -= delta
		if burn_timer <= 0.0:
			is_burning = false
	
	# Пассивная регенерация (тролли)
	time_since_damage += delta
	if enemy_data != null and enemy_data.can_regenerate and not is_burning:
		if time_since_damage >= enemy_data.regen_delay_seconds:
			if health_component.current_health < health_component.max_health:
				regen_tick_timer += delta
				if regen_tick_timer >= 1.0:
					regen_tick_timer = 0.0
					health_component.heal(enemy_data.regen_amount)
					hp_bar.value = health_component.current_health
					_flash_heal_effect(self)
	
	# Находим цель (игрока) если еще не найдена
	if not is_instance_valid(player_target):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_target = players[0] as Node2D
		else:
			for child in get_tree().root.find_children("*", "Player", true, false):
				player_target = child as Node2D
				break
	
	if velocity.x < -5.0:
		visuals.scale.x = -1.0
	elif velocity.x > 5.0:
		visuals.scale.x = 1.0

func _on_hit_received(_dmg: int, _crit: bool, hitbox: HitboxComponent) -> void:
	# Проверка щита рыцаря-стража: блок спереди, уязвим со спины
	if enemy_data != null and enemy_data.has_front_shield and is_instance_valid(hitbox):
		var hit_dir: Vector2 = (hitbox.global_position - global_position).normalized()
		var facing_dir: Vector2 = Vector2.RIGHT
		if is_instance_valid(player_target):
			facing_dir = (player_target.global_position - global_position).normalized()
		
		# Если удар нанесён спереди (угол меньше 80 градусов к направлению взгляда)
		if hit_dir.dot(facing_dir) > 0.15:
			health_component.heal(_dmg) # Поглощаем урон щитом
			hp_bar.value = health_component.current_health
			_flash_shield_block()
			return
	
	time_since_damage = 0.0
	if hitbox != null and (hitbox.damage_type == "fire" or hitbox.tags.has("fire")):
		is_burning = true
		burn_timer = 4.0
		visuals.modulate = Color(2.5, 0.8, 0.2, 1.0)

func _flash_shield_block() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.5, 2.0, 3.0, 1.0) # Голубая металлическая искра
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)
	EventBus.screen_shake_requested.emit(3.0, 0.1)

func _on_damaged(_amount: int, current_hp: int, _max_hp: int) -> void:
	time_since_damage = 0.0
	hp_bar.value = current_hp
	_flash_red()

func _flash_red() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.4, 0.4, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)

func _on_died() -> void:
	# Скелет-мечник: рассыпается в кости и восстанавливается, если не разбить кучу костей
	if enemy_data != null and enemy_data.can_reassemble and not has_reassembled and not is_collapsed:
		_collapse_into_bones()
		return
	
	_permanent_death()

func _collapse_into_bones() -> void:
	is_collapsed = true
	has_reassembled = true
	attack_shape.disabled = true
	
	# Формируем кучу костей на полу
	body_rect.scale = Vector2(1.4, 0.35)
	body_rect.color = Color(0.8, 0.8, 0.75, 1.0)
	
	health_component.reset(enemy_data.bone_pile_hp)
	hp_bar.max_value = enemy_data.bone_pile_hp
	hp_bar.value = enemy_data.bone_pile_hp
	
	reassemble_timer = enemy_data.reassemble_time
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.5, 1.5, 1.5, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.2)

func _reassemble_skeleton() -> void:
	is_collapsed = false
	body_rect.scale = Vector2.ONE
	body_rect.color = enemy_data.color
	
	# Установка стилизованного пиксель-арт спрайта монстра
	var enemy_tex: Texture2D = SpriteGenerator.get_enemy_texture(enemy_data.enemy_type)
	if enemy_tex != null and visuals != null:
		var enemy_sprite: Sprite2D = visuals.get_node_or_null("EnemySprite") as Sprite2D
		if enemy_sprite == null:
			enemy_sprite = Sprite2D.new()
			enemy_sprite.name = "EnemySprite"
			enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			visuals.add_child(enemy_sprite)
		enemy_sprite.texture = enemy_tex
		if body_rect != null:
			body_rect.visible = false
		if visuals.has_node("EyeLeft"):
			visuals.get_node("EyeLeft").visible = false
		if visuals.has_node("EyeRight"):
			visuals.get_node("EyeRight").visible = false
	
	var revive_hp: int = int(round(enemy_data.max_hp * 0.55))
	health_component.reset(revive_hp)
	hp_bar.max_value = enemy_data.max_hp
	hp_bar.value = revive_hp
	
	# Зелёная некромантическая вспышка оживления
	var tween: Tween = create_tween()
	visuals.modulate = Color(0.2, 2.5, 0.5, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.35)
	EventBus.screen_shake_requested.emit(4.0, 0.2)

func _permanent_death() -> void:
	remove_from_group("enemies")
	attack_shape.disabled = true
	hurtbox_component.set_deferred("monitoring", false)
	
	if enemy_data != null:
		GameState.add_gold(enemy_data.gold_reward)
		if enemy_data.souls_reward > 0:
			MetaProgress.add_souls(enemy_data.souls_reward)
		GameState.run_stats["kills"] = GameState.run_stats.get("kills", 0) + 1
	
	if enemy_data != null and enemy_data.enemy_type == "lava_slime":
		_spawn_death_lava_puddle()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.35)
	tween.chain().tween_callback(queue_free)

func perform_attack() -> void:
	if not is_instance_valid(player_target) or attack_timer > 0.0 or is_collapsed:
		return
	if status_effect_manager != null and (status_effect_manager.is_frozen() or status_effect_manager.is_stunned()):
		return
	
	attack_timer = enemy_data.attack_cooldown if enemy_data else 1.2
	
	match enemy_data.enemy_type if enemy_data else "melee":
		"ranged":
			_shoot_arrow()
		"crossbowman":
			_shoot_crossbow()
		"boulder_thrower":
			_throw_boulder()
		"necromancer":
			_cast_necromancy()
		"frost_wraith":
			_shoot_frost_bolt()
		"frost_golem":
			_frost_golem_smash()
		"lich_apprentice":
			_lich_apprentice_cast()
		"ice_spider":
			_ice_spider_leap()
		"lava_slime":
			_lava_slime_bounce_attack()
		"fire_elemental":
			_shoot_fireball_barrage()
		"flame_cultist":
			_cast_flame_pillar()
		"magma_worm":
			_magma_worm_spit()
		"shadow_chimera":
			_shadow_chimera_strike()
		"fallen_archon":
			_fallen_archon_cross_barrage()
		"void_specter":
			_void_specter_phase_pulse()
		"purgatory_executioner":
			_executioner_cleave()
		"support":
			_try_heal_or_attack()
		"heavy":
			_heavy_attack()
		_:
			_melee_attack()

func _melee_attack() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.reset_hits()
	attack_shape.disabled = false
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + dir * 18.0, 0.1)
	tween.tween_callback(func(): attack_shape.disabled = true)
	tween.tween_property(self, "position", position, 0.1)

func _heavy_attack() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.knockback_force = 420.0
	attack_hitbox.reset_hits()
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.0, 1.2, 0.4, 1.0)
	tween.tween_property(self, "position", position - dir * 10.0, 0.2)
	tween.tween_callback(func():
		attack_shape.disabled = false
		visuals.modulate = Color.WHITE
		EventBus.screen_shake_requested.emit(4.0, 0.15)
	)
	tween.tween_property(self, "position", position + dir * 28.0, 0.12)
	tween.tween_callback(func(): attack_shape.disabled = true)
	tween.tween_property(self, "position", position, 0.15)

func _throw_boulder() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 24.0
	proj.scale = Vector2(1.7, 1.7)
	proj.setup(
		dir,
		290.0,
		enemy_data.damage if enemy_data else 16,
		false,
		460.0,
		280.0,
		Color(0.6, 0.52, 0.42, 1.0)
	)

func _shoot_crossbow() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	# Краткий прицел перед выстрелом арбалета
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.2, 0.5, 0.5, 1.0)
	tween.tween_interval(0.2)
	tween.tween_callback(func():
		visuals.modulate = Color.WHITE
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 22.0
		proj.scale = Vector2(1.4, 0.8) # Узкий быстрый арбалетный болт
		proj.setup(
			dir,
			520.0,
			enemy_data.damage if enemy_data else 18,
			false,
			550.0,
			220.0,
			Color(0.9, 0.8, 0.4, 1.0)
		)
	)

func _cast_necromancy() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	if summon_timer <= 0.0:
		summon_timer = 5.0
		_summon_skeleton_minion()
		return
	
	# Тёмный магический снаряд
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 20.0
	proj.setup(
		dir,
		320.0,
		enemy_data.damage if enemy_data else 15,
		false,
		420.0,
		200.0,
		Color(0.6, 0.2, 0.85, 1.0)
	)

func _summon_skeleton_minion() -> void:
	var count: int = get_tree().get_nodes_in_group("enemies").size()
	if count >= 6:
		return
		
	var skel_data: EnemyData = load("res://data/enemies/skeleton_swordsman.tres") as EnemyData
	var minion_scene: PackedScene = load("res://entities/enemies/EnemyBase.tscn")
	var minion: EnemyBase = minion_scene.instantiate() as EnemyBase
	get_parent().add_child(minion)
	minion.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	if skel_data != null:
		minion.setup_from_data(skel_data)
	_flash_heal_effect(minion)

func _shoot_arrow() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 20.0
	proj.setup(
		dir,
		380.0,
		enemy_data.damage if enemy_data else 10,
		false,
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
		if enemy is EnemyBase and enemy != self and not enemy.is_collapsed:
			var hc: HealthComponent = enemy.health_component
			if hc.current_health < hc.max_health:
				return enemy
	return null

func _flash_heal_effect(target: EnemyBase) -> void:
	var tween: Tween = target.create_tween()
	target.visuals.modulate = Color(0.3, 2.5, 0.8, 1.0)
	tween.tween_property(target.visuals, "modulate", Color.WHITE, 0.25)

func _shoot_frost_bolt() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 20.0
	proj.setup(
		dir,
		320.0,
		enemy_data.damage if enemy_data else 14,
		false,
		450.0,
		180.0,
		Color(0.4, 0.9, 1.0, 1.0),
		"freeze",
		["frost", "ice", "freeze"]
	)

func _frost_golem_smash() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.5, 2.2, 3.0, 1.0)
	tween.tween_property(self, "position", position - dir * 12.0, 0.25)
	tween.tween_callback(func():
		visuals.modulate = Color.WHITE
		EventBus.screen_shake_requested.emit(6.0, 0.2)
		for i in range(6):
			var angle: float = (TAU / 6.0) * i
			var pdir: Vector2 = Vector2(cos(angle), sin(angle))
			var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
			get_parent().add_child(proj)
			proj.global_position = global_position + pdir * 25.0
			proj.setup(
				pdir,
				260.0,
				enemy_data.damage if enemy_data else 16,
				false,
				350.0,
				220.0,
				Color(0.5, 0.9, 1.0, 1.0),
				"freeze",
				["frost", "freeze"]
			)
	)
	tween.tween_property(self, "position", position, 0.15)

func _lich_apprentice_cast() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	if global_position.distance_to(player_target.global_position) < 100.0:
		var teleport_offset: Vector2 = -dir * 110.0 + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		global_position += teleport_offset
		var flash: Tween = create_tween()
		visuals.modulate = Color(2.0, 2.5, 3.0, 1.0)
		flash.tween_property(visuals, "modulate", Color.WHITE, 0.2)
		dir = (player_target.global_position - global_position).normalized()
	
	var base_angle: float = dir.angle()
	var angles: Array[float] = [base_angle - 0.25, base_angle, base_angle + 0.25]
	for a in angles:
		var pdir: Vector2 = Vector2(cos(a), sin(a))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 22.0
		proj.setup(
			pdir,
			360.0,
			enemy_data.damage if enemy_data else 12,
			false,
			450.0,
			180.0,
			Color(0.3, 0.8, 1.0, 1.0),
			"freeze",
			["frost", "ice"]
		)

func _ice_spider_leap() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.damage_type = "freeze"
	attack_hitbox.tags = ["frost", "freeze"]
	attack_hitbox.reset_hits()
	
	var leap_target: Vector2 = position + dir * 85.0
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.8, 2.5, 3.0, 1.0)
	tween.tween_callback(func(): attack_shape.disabled = false)
	tween.tween_property(self, "position", leap_target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		attack_shape.disabled = true
		visuals.modulate = Color.WHITE
	)

func _spawn_death_lava_puddle() -> void:
	var lava_scene: PackedScene = load("res://levels/hazards/LavaHazard.tscn")
	if lava_scene != null and get_parent() != null:
		var puddle: LavaHazard = lava_scene.instantiate() as LavaHazard
		puddle.lifetime = 4.0
		puddle.scale = Vector2(0.5, 0.5)
		puddle.tick_damage = 4
		get_parent().add_child(puddle)
		puddle.global_position = global_position

func _lava_slime_bounce_attack() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.damage_type = "fire"
	attack_hitbox.tags = ["fire"]
	attack_hitbox.reset_hits()
	
	var tween: Tween = create_tween()
	visuals.scale = Vector2(1.3, 0.7)
	tween.tween_property(visuals, "scale", Vector2(0.8, 1.3), 0.12)
	tween.tween_callback(func(): attack_shape.disabled = false)
	tween.tween_property(self, "position", position + dir * 65.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		attack_shape.disabled = true
		visuals.scale = Vector2.ONE
	)

func _shoot_fireball_barrage() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 1.2, 0.3, 1.0)
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		visuals.modulate = Color.WHITE
		for i in range(2):
			var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
			get_parent().add_child(proj)
			var spread_dir: Vector2 = dir.rotated(randf_range(-0.12, 0.12))
			proj.global_position = global_position + spread_dir * (20.0 + i * 8.0)
			proj.setup(
				spread_dir,
				340.0,
				enemy_data.damage if enemy_data else 14,
				false,
				480.0,
				200.0,
				Color(1.0, 0.45, 0.1, 1.0),
				"fire",
				["fire"]
			)
	)

func _shadow_chimera_strike() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.damage_type = "poison"
	attack_hitbox.tags = ["poison"]
	var poison_res: StatusEffect = load("res://data/status_effects/poison.tres") as StatusEffect
	attack_hitbox.applied_effect = poison_res
	attack_hitbox.reset_hits()
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(0.4, 2.5, 0.6, 1.0)
	tween.tween_callback(func(): attack_shape.disabled = false)
	tween.tween_property(self, "position", position + dir * 75.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		attack_shape.disabled = true
		visuals.modulate = Color.WHITE
	)

func _fallen_archon_cross_barrage() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var base_ang: float = dir.angle()
	var cardinal_angles: Array[float] = [base_ang, base_ang + PI * 0.5, base_ang + PI, base_ang + PI * 1.5]
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 2.2, 0.8, 1.0)
	tween.tween_interval(0.2)
	tween.tween_callback(func():
		visuals.modulate = Color.WHITE
		EventBus.screen_shake_requested.emit(5.0, 0.2)
		for ang in cardinal_angles:
			var pdir: Vector2 = Vector2(cos(ang), sin(ang))
			var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
			get_parent().add_child(proj)
			proj.global_position = global_position + pdir * 25.0
			proj.setup(
				pdir,
				420.0,
				enemy_data.damage if enemy_data else 18,
				false,
				550.0,
				200.0,
				Color(0.85, 0.75, 1.0, 1.0),
				"astral",
				["astral", "energy"]
			)
	)

func _void_specter_phase_pulse() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func():
		global_position = player_target.global_position + dir * 60.0
		visuals.modulate = Color(2.0, 1.0, 3.5, 1.0)
		EventBus.screen_shake_requested.emit(4.0, 0.15)
		var stun_res: StatusEffect = load("res://data/status_effects/stun.tres") as StatusEffect
		attack_hitbox.rotation = (-dir).angle()
		attack_hitbox.applied_effect = stun_res
		attack_hitbox.reset_hits()
		attack_shape.disabled = false
	)
	tween.tween_interval(0.12)
	tween.tween_callback(func():
		attack_shape.disabled = true
		visuals.modulate = Color.WHITE
	)

func _executioner_cleave() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.knockback_force = 480.0
	attack_hitbox.applied_effect = null
	attack_hitbox.reset_hits()
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.3, 0.8, 1.0)
	tween.tween_property(self, "position", position - dir * 14.0, 0.28)
	tween.tween_callback(func():
		attack_shape.disabled = false
		visuals.modulate = Color.WHITE
		EventBus.screen_shake_requested.emit(7.0, 0.2)
	)
	tween.tween_property(self, "position", position + dir * 32.0, 0.14)
	tween.tween_callback(func(): attack_shape.disabled = true)
	tween.tween_property(self, "position", position, 0.15)

func _cast_flame_pillar() -> void:
	var target_pos: Vector2 = player_target.global_position
	var telegraph: ColorRect = ColorRect.new()
	telegraph.size = Vector2(56, 56)
	telegraph.position = target_pos - Vector2(28, 28)
	telegraph.color = Color(1.0, 0.3, 0.1, 0.4)
	get_parent().add_child(telegraph)
	
	var tween: Tween = create_tween()
	tween.tween_property(telegraph, "color:a", 0.9, 0.5)
	tween.tween_callback(func():
		telegraph.queue_free()
		EventBus.screen_shake_requested.emit(5.0, 0.2)
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = target_pos
		proj.scale = Vector2(2.0, 2.0)
		proj.setup(
			Vector2.RIGHT,
			0.001,
			enemy_data.damage if enemy_data else 16,
			false,
			10.0,
			220.0,
			Color(1.0, 0.5, 0.1, 1.0),
			"fire",
			["fire"]
		)
		var p_tween: Tween = proj.create_tween()
		p_tween.tween_interval(0.2)
		p_tween.tween_callback(proj.queue_free)
	)

func _magma_worm_spit() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var base_ang: float = dir.angle()
	var angles: Array[float] = [base_ang - 0.28, base_ang, base_ang + 0.28]
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.8, 0.2, 1.0)
	tween.tween_interval(0.2)
	tween.tween_callback(func():
		visuals.modulate = Color.WHITE
		EventBus.screen_shake_requested.emit(4.0, 0.15)
		for a in angles:
			var pdir: Vector2 = Vector2(cos(a), sin(a))
			var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
			get_parent().add_child(proj)
			proj.global_position = global_position + pdir * 25.0
			proj.setup(
				pdir,
				300.0,
				enemy_data.damage if enemy_data else 18,
				false,
				420.0,
				240.0,
				Color(1.0, 0.35, 0.05, 1.0),
				"fire",
				["fire"]
			)
	)

