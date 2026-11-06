class_name EnemyBase
extends CharacterBody2D

## Базовый класс врагов с конечным автоматом состояний (AI) и механиками Спринтов 4, 6, 7

signal permanently_died(enemy: EnemyBase)

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
var _walk_anim_phase: float = randf_range(0.0, 10.0)
var _shadow_sprite: Sprite2D = null
var _eye_light: PointLight2D = null
var _base_eye_energy: float = 0.55
var _step_dust_timer: float = 0.0
var _left_foot: Sprite2D = null
var _right_foot: Sprite2D = null
var _weapon_pivot: Node2D = null
var _weapon_sprite: Sprite2D = null
var _is_attack_animating: bool = false

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
	
	# Установка детализированного готического спрайта монстра
	var type_key: String = enemy_data.id if not enemy_data.id.is_empty() else enemy_data.enemy_type
	var is_heavy: bool = type_key.contains("troll") or type_key.contains("golem") or type_key.contains("brute") or type_key.contains("executioner")
	var enemy_tex: Texture2D = SpriteGenerator.get_enemy_texture(type_key)
	if enemy_tex != null and visuals != null:
		var enemy_sprite: Sprite2D = visuals.get_node_or_null("EnemySprite") as Sprite2D
		if enemy_sprite == null:
			enemy_sprite = Sprite2D.new()
			enemy_sprite.name = "EnemySprite"
			visuals.add_child(enemy_sprite)
		enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		enemy_sprite.texture = enemy_tex
		var base_scale: float = 0.88 if is_heavy else 0.76
		enemy_sprite.scale = Vector2(base_scale, base_scale)
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
	_setup_enemy_visuals()

func _setup_enemy_visuals() -> void:
	var type_key: String = enemy_data.id if (enemy_data and not enemy_data.id.is_empty()) else (enemy_data.enemy_type if enemy_data else "")
	
	if _shadow_sprite == null:
		_shadow_sprite = Sprite2D.new()
		_shadow_sprite.name = "FloorShadow"
		_shadow_sprite.texture = EffectsHelper.get_spark_texture()
		_shadow_sprite.modulate = Color(0, 0, 0, 0.5)
		_shadow_sprite.z_index = -1
		add_child(_shadow_sprite)
	
	var is_heavy: bool = type_key.contains("troll") or type_key.contains("golem") or type_key.contains("brute") or type_key.contains("executioner")
	var is_small: bool = type_key.contains("spider") or type_key.contains("slime")
	if is_heavy:
		_shadow_sprite.scale = Vector2(3.6, 1.2)
		_shadow_sprite.position = Vector2(0, 18.0)
	elif is_small:
		_shadow_sprite.scale = Vector2(1.8, 0.65)
		_shadow_sprite.position = Vector2(0, 10.0)
	else:
		_shadow_sprite.scale = Vector2(2.4, 0.85)
		_shadow_sprite.position = Vector2(0, 14.0)
	
	# Анимированные стопы/сапоги двуногих врагов
	var foot_tex: Texture2D = SpriteGenerator.get_enemy_foot_texture(type_key)
	if foot_tex != null and visuals != null:
		if _left_foot == null:
			_left_foot = Sprite2D.new()
			_left_foot.name = "LeftFoot"
			_left_foot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_left_foot.z_index = -1
			visuals.add_child(_left_foot)
		_left_foot.texture = foot_tex
		_left_foot.visible = true
		_left_foot.position = Vector2(-6.0 if is_heavy else -4.5, 16.0 if is_heavy else 13.0)
		
		if _right_foot == null:
			_right_foot = Sprite2D.new()
			_right_foot.name = "RightFoot"
			_right_foot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_right_foot.z_index = -1
			visuals.add_child(_right_foot)
		_right_foot.texture = foot_tex
		_right_foot.visible = true
		_right_foot.position = Vector2(6.0 if is_heavy else 4.5, 16.0 if is_heavy else 13.0)
	else:
		if _left_foot != null:
			_left_foot.visible = false
		if _right_foot != null:
			_right_foot.visible = false
	
	# Анимированное оружие врага на шарнире EnemyWeaponPivot
	var w_tex: Texture2D = SpriteGenerator.get_enemy_weapon_texture(type_key)
	if w_tex != null:
		if _weapon_pivot == null:
			_weapon_pivot = Node2D.new()
			_weapon_pivot.name = "EnemyWeaponPivot"
			_weapon_pivot.z_index = 1
			add_child(_weapon_pivot)
		if _weapon_sprite == null:
			_weapon_sprite = Sprite2D.new()
			_weapon_sprite.name = "EnemyWeaponSprite"
			_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_weapon_pivot.add_child(_weapon_sprite)
		_weapon_sprite.texture = w_tex
		_weapon_sprite.position = Vector2(15.0 if is_heavy else 12.0, 2.0)
		_weapon_pivot.visible = true
	elif _weapon_pivot != null:
		_weapon_pivot.visible = false
	
	var eye_col: Color = Color(1.0, 0.25, 0.2)
	_base_eye_energy = 0.55
	if type_key.contains("skeleton") or type_key.contains("wraith"):
		eye_col = Color(0.2, 0.85, 1.0)
		_base_eye_energy = 0.7
	elif type_key.contains("troll"):
		eye_col = Color(0.75, 0.95, 0.25)
	elif type_key.contains("fire") or type_key.contains("magma") or type_key.contains("flame"):
		eye_col = Color(1.1, 0.55, 0.15)
		_base_eye_energy = 0.75
	elif type_key.contains("frost") or type_key.contains("ice"):
		eye_col = Color(0.3, 0.9, 1.1)
		_base_eye_energy = 0.7
	elif type_key.contains("void") or type_key.contains("chimera") or type_key.contains("archon") or type_key.contains("purgatory"):
		eye_col = Color(0.85, 0.35, 1.1)
		_base_eye_energy = 0.8
	
	if _eye_light == null and visuals != null:
		_eye_light = LightTextureGenerator.create_point_light(eye_col, _base_eye_energy, 0.8)
		_eye_light.name = "EnemyEyeLight"
		_eye_light.position = Vector2(0, -6.0)
		visuals.add_child(_eye_light)
	elif _eye_light != null:
		_eye_light.color = eye_col
		_eye_light.energy = _base_eye_energy

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return
	
	# Заморозка или оглушение блокируют любые действия
	if status_effect_manager != null and (status_effect_manager.is_frozen() or status_effect_manager.is_stunned()):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Если скелет рассыпался в груду костей — дрожит перед сборкой
	if is_collapsed:
		velocity = Vector2.ZERO
		move_and_slide()
		reassemble_timer -= delta
		if visuals != null:
			var shake_intensity: float = clampf((1.5 - reassemble_timer) * 2.2, 0.4, 2.5)
			visuals.position.x = sin(reassemble_timer * 42.0) * shake_intensity
		if reassemble_timer <= 0.0:
			if visuals != null:
				visuals.position.x = 0.0
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
	
	# Если враг не в состоянии погони, но получил отталкивание — обрабатываем движение и затухание
	if state_machine != null and state_machine.current_state_name != "chase" and movement_component != null:
		if movement_component.knockback_velocity.length_squared() > 1.0:
			movement_component.move(self, Vector2.ZERO, delta)
	
	_step_dust_timer = maxf(0.0, _step_dust_timer - delta)
	var facing_sign: float = -1.0 if visuals.scale.x < 0.0 else 1.0
	if velocity.x < -5.0:
		facing_sign = -1.0
		visuals.scale.x = -abs(visuals.scale.x)
	elif velocity.x > 5.0:
		facing_sign = 1.0
		visuals.scale.x = abs(visuals.scale.x)
	elif is_instance_valid(player_target):
		var dx: float = player_target.global_position.x - global_position.x
		if absf(dx) > 8.0:
			facing_sign = -1.0 if dx < 0.0 else 1.0
			visuals.scale.x = absf(visuals.scale.x) * facing_sign

	var is_moving: bool = velocity.length_squared() > 100.0
	var type_key: String = enemy_data.id if (enemy_data and not enemy_data.id.is_empty()) else (enemy_data.enemy_type if enemy_data else "")
	
	var is_floating: bool = type_key.contains("wraith") or type_key.contains("specter") or type_key.contains("archon") or type_key.contains("necromancer") or type_key.contains("lich") or type_key.contains("elemental")
	var is_heavy: bool = type_key.contains("troll") or type_key.contains("golem") or type_key.contains("brute") or type_key.contains("executioner")
	var is_skitter: bool = type_key.contains("spider") or type_key.contains("worm") or type_key.contains("chimera")
	var is_slime: bool = type_key.contains("slime")
	
	if is_floating:
		_walk_anim_phase += delta * 3.4
		var hover_y: float = sin(_walk_anim_phase) * 5.5 - 5.0
		visuals.position.y = hover_y
		visuals.rotation = sin(_walk_anim_phase * 0.7) * 0.09 + clampf(velocity.x / 220.0, -0.14, 0.14)
		visuals.scale.y = 1.0 + cos(_walk_anim_phase * 1.4) * 0.04
		visuals.scale.x = (1.0 - cos(_walk_anim_phase * 1.4) * 0.025) * facing_sign
		if _shadow_sprite != null:
			var s_shrink: float = clampf(1.0 - (hover_y / -12.0) * 0.25, 0.7, 1.2)
			_shadow_sprite.scale = Vector2(2.4 * s_shrink, 0.85 * s_shrink)
	elif is_heavy:
		if is_moving:
			_walk_anim_phase += delta * 8.5
			var step_sin: float = sin(_walk_anim_phase)
			visuals.position.y = -absf(step_sin) * 4.8
			visuals.rotation = step_sin * 0.09
			visuals.scale.y = 1.0 - absf(step_sin) * 0.11
			visuals.scale.x = (1.0 + absf(step_sin) * 0.06) * facing_sign
			if absf(step_sin) > 0.92 and _step_dust_timer <= 0.0:
				EffectsHelper.spawn_dust_puff(get_parent(), global_position + Vector2(0, 16.0))
				_step_dust_timer = 0.35
		else:
			_walk_anim_phase += delta * 2.2
			visuals.position.y = move_toward(visuals.position.y, 0.0, delta * 15.0)
			visuals.rotation = move_toward(visuals.rotation, 0.0, delta * 2.0)
			visuals.scale.y = 1.0 + sin(_walk_anim_phase) * 0.035
			visuals.scale.x = (1.0 - sin(_walk_anim_phase) * 0.02) * facing_sign
	elif is_skitter:
		if is_moving:
			_walk_anim_phase += delta * 22.0
			visuals.position.y = -absf(sin(_walk_anim_phase)) * 2.8
			visuals.rotation = sin(_walk_anim_phase) * 0.14
			visuals.scale.y = 1.0 + sin(_walk_anim_phase * 2.0) * 0.07
			visuals.scale.x = (1.0 - sin(_walk_anim_phase * 2.0) * 0.05) * facing_sign
		else:
			_walk_anim_phase += delta * 4.0
			visuals.position.y = move_toward(visuals.position.y, 0.0, delta * 15.0)
			visuals.rotation = move_toward(visuals.rotation, 0.0, delta * 3.0)
			visuals.scale.y = 1.0 + sin(_walk_anim_phase) * 0.03
			visuals.scale.x = facing_sign
	elif is_slime:
		_walk_anim_phase += delta * (12.0 if is_moving else 3.8)
		var squash: float = sin(_walk_anim_phase) * 0.24
		visuals.scale.y = 1.0 + squash
		visuals.scale.x = (1.0 - squash * 0.5) * facing_sign
		visuals.position.y = -absf(sin(_walk_anim_phase)) * 5.5
	else:
		if is_moving:
			_walk_anim_phase += delta * 14.5
			var step_sin: float = sin(_walk_anim_phase)
			visuals.position.y = -absf(step_sin) * 3.6
			visuals.rotation = clampf(velocity.x / 180.0, -1.0, 1.0) * 0.12 + step_sin * 0.05
			visuals.scale.y = 1.0 + sin(_walk_anim_phase * 2.0) * 0.05
			visuals.scale.x = (1.0 - sin(_walk_anim_phase * 2.0) * 0.03) * facing_sign
			if absf(step_sin) > 0.9 and _step_dust_timer <= 0.0:
				EffectsHelper.spawn_dust_puff(get_parent(), global_position + Vector2(0, 12.0))
				_step_dust_timer = 0.25
		else:
			_walk_anim_phase += delta * 2.6
			visuals.position.y = move_toward(visuals.position.y, 0.0, delta * 15.0)
			visuals.rotation = move_toward(visuals.rotation, 0.0, delta * 2.0)
			visuals.scale.y = 1.0 + sin(_walk_anim_phase) * 0.03
			visuals.scale.x = (1.0 - sin(_walk_anim_phase) * 0.015) * facing_sign
	
	# Анимация шагания стоп (LeftFoot / RightFoot)
	if _left_foot != null and _right_foot != null and _left_foot.visible:
		var foot_base_x: float = 6.0 if is_heavy else 4.5
		var foot_base_y: float = 16.0 if is_heavy else 13.0
		if is_moving:
			var l_stride: float = sin(_walk_anim_phase)
			var r_stride: float = sin(_walk_anim_phase + PI)
			_left_foot.position = Vector2(-foot_base_x + l_stride * 5.0, foot_base_y - maxf(0.0, cos(_walk_anim_phase)) * 3.8)
			_right_foot.position = Vector2(foot_base_x + r_stride * 5.0, foot_base_y - maxf(0.0, cos(_walk_anim_phase + PI)) * 3.8)
			_left_foot.rotation = l_stride * 0.28
			_right_foot.rotation = r_stride * 0.28
		else:
			_left_foot.position = _left_foot.position.lerp(Vector2(-foot_base_x, foot_base_y), delta * 14.0)
			_right_foot.position = _right_foot.position.lerp(Vector2(foot_base_x, foot_base_y), delta * 14.0)
			_left_foot.rotation = lerpf(_left_foot.rotation, 0.0, delta * 14.0)
			_right_foot.rotation = lerpf(_right_foot.rotation, 0.0, delta * 14.0)
	
	# Динамическое наведение и дыхание оружия врага
	if _weapon_pivot != null and _weapon_pivot.visible and not _is_attack_animating:
		var target_ang: float = 0.0 if facing_sign > 0.0 else PI
		if is_instance_valid(player_target):
			target_ang = (player_target.global_position - global_position).angle()
		var idle_sway: float = sin(_walk_anim_phase) * 0.08
		_weapon_pivot.rotation = lerp_angle(_weapon_pivot.rotation, target_ang + idle_sway, delta * 12.0)
		if _weapon_sprite != null:
			_weapon_sprite.flip_v = cos(_weapon_pivot.rotation) < 0.0
	
	if _eye_light != null:
		_eye_light.energy = _base_eye_energy + sin(_walk_anim_phase * 2.0) * 0.12
	_clamp_to_room()

func _is_in_dungeon_room() -> bool:
	var p: Node = get_parent()
	return p != null and (p.name == "EnemiesContainer" or p is DungeonRoom)

func _clamp_to_room() -> void:
	if _is_in_dungeon_room():
		position.x = clampf(position.x, 85.0, 1195.0)
		position.y = clampf(position.y, 85.0, 635.0)

func _clamp_local_pos(pos: Vector2) -> Vector2:
	if _is_in_dungeon_room():
		return Vector2(clampf(pos.x, 85.0, 1195.0), clampf(pos.y, 85.0, 635.0))
	return pos

func can_block_frontal_hit(hitbox: HitboxComponent) -> bool:
	if enemy_data != null and enemy_data.has_front_shield and is_instance_valid(hitbox) and not is_collapsed:
		var hit_dir: Vector2 = (hitbox.global_position - global_position).normalized()
		var facing_dir: Vector2 = Vector2.RIGHT
		if is_instance_valid(player_target):
			facing_dir = (player_target.global_position - global_position).normalized()
		if hit_dir.dot(facing_dir) > 0.15:
			return true
	return false

func try_block_frontal_hit(hitbox: HitboxComponent) -> bool:
	if can_block_frontal_hit(hitbox):
		_flash_shield_block()
		return true
	return false

func _on_hit_received(_dmg: int, _crit: bool, hitbox: HitboxComponent) -> void:
	# Проверка щита рыцаря-стража: блок спереди, уязвим со спины
	if can_block_frontal_hit(hitbox):
		health_component.heal(_dmg) # Поглощаем урон щитом при прямом вызове
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
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, enemy_data.color if enemy_data else Color.WHITE, 5)

func _flash_red() -> void:
	EffectsHelper.apply_hit_flash(visuals, 0.1, Color(1.0, 0.35, 0.35, 1.0))
	var facing_sign: float = -1.0 if visuals.scale.x < 0.0 else 1.0
	visuals.scale = Vector2(1.18 * facing_sign, 0.78)
	visuals.rotation = -0.22 * facing_sign
	var sq_tween: Tween = create_tween().set_parallel(true)
	sq_tween.tween_property(visuals, "scale:y", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sq_tween.tween_property(visuals, "scale:x", 1.0 * facing_sign, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sq_tween.tween_property(visuals, "rotation", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	
	# Формируем кучу костей на полу (смена спрайта + скрытие ног и оружия)
	body_rect.scale = Vector2(1.4, 0.35)
	body_rect.color = Color(0.8, 0.8, 0.75, 1.0)
	if visuals != null:
		var enemy_sprite: Sprite2D = visuals.get_node_or_null("EnemySprite") as Sprite2D
		if enemy_sprite != null:
			enemy_sprite.texture = SpriteGenerator.get_bone_pile_texture()
			enemy_sprite.scale = Vector2(1.0, 1.0)
	if _left_foot != null:
		_left_foot.visible = false
	if _right_foot != null:
		_right_foot.visible = false
	if _weapon_pivot != null:
		_weapon_pivot.visible = false
	
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(0.88, 0.85, 0.76, 1.0), 8)
	
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
	
	# Восстановление стилизованного векторного спрайта монстра, ног и оружия
	var type_key: String = enemy_data.id if not enemy_data.id.is_empty() else enemy_data.enemy_type
	var enemy_tex: Texture2D = SpriteGenerator.get_enemy_texture(type_key)
	if enemy_tex != null and visuals != null:
		var enemy_sprite: Sprite2D = visuals.get_node_or_null("EnemySprite") as Sprite2D
		if enemy_sprite == null:
			enemy_sprite = Sprite2D.new()
			enemy_sprite.name = "EnemySprite"
			enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			visuals.add_child(enemy_sprite)
		enemy_sprite.texture = enemy_tex
		var is_heavy: bool = type_key in ["goblin_brute", "troll_brute", "troll_regenerator", "knight_guard", "frost_golem", "purgatory_executioner"]
		enemy_sprite.scale = Vector2(0.88, 0.88) if is_heavy else Vector2(0.76, 0.76)
		if body_rect != null:
			body_rect.visible = false
		if visuals.has_node("EyeLeft"):
			visuals.get_node("EyeLeft").visible = false
		if visuals.has_node("EyeRight"):
			visuals.get_node("EyeRight").visible = false
	if _left_foot != null:
		_left_foot.visible = true
	if _right_foot != null:
		_right_foot.visible = true
	if _weapon_pivot != null:
		_weapon_pivot.visible = true
	
	var revive_hp: int = int(round(enemy_data.max_hp * 0.55))
	health_component.reset(revive_hp)
	hp_bar.max_value = enemy_data.max_hp
	hp_bar.value = revive_hp
	
	# Зелёная некромантическая вспышка оживления
	EffectsHelper.spawn_shockwave(get_parent(), global_position, 36.0, 0.25, Color(0.2, 1.0, 0.5, 0.85))
	var tween: Tween = create_tween()
	visuals.modulate = Color(0.2, 2.5, 0.5, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.35)
	EventBus.screen_shake_requested.emit(4.0, 0.2)

func _permanent_death() -> void:
	permanently_died.emit(self)
	remove_from_group("enemies")
	attack_shape.disabled = true
	hurtbox_component.set_deferred("monitoring", false)
	
	if enemy_data != null:
		GameState.add_gold(enemy_data.gold_reward)
		if enemy_data.souls_reward > 0:
			MetaProgress.add_souls(enemy_data.souls_reward)
		GameState.run_stats["kills"] = GameState.run_stats.get("kills", 0) + 1
	
	if enemy_data != null and (enemy_data.id == "lava_slime" or enemy_data.enemy_type == "lava_slime"):
		_spawn_death_lava_puddle()
	
	EffectsHelper.spawn_death_burst(get_parent(), global_position, enemy_data.color if enemy_data else Color(0.85, 0.2, 0.2))
	
	var dissolve_color: Color = Color(2.8, 0.95, 0.15, 1.0)
	if enemy_data != null:
		if enemy_data.id.begins_with("frost_") or enemy_data.enemy_type.begins_with("frost_"):
			dissolve_color = Color(0.4, 1.8, 2.8, 1.0)
		elif enemy_data.id.begins_with("void_") or enemy_data.enemy_type.begins_with("void_"):
			dissolve_color = Color(2.2, 0.4, 2.6, 1.0)
	
	EffectsHelper.apply_burn_dissolve(visuals, 0.32, dissolve_color)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.32)
	tween.tween_property(self, "scale", scale * 1.1, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)

func perform_attack() -> void:
	if not is_instance_valid(player_target) or attack_timer > 0.0 or is_collapsed:
		return
	if status_effect_manager != null and (status_effect_manager.is_frozen() or status_effect_manager.is_stunned()):
		return
	
	attack_timer = enemy_data.attack_cooldown if enemy_data else 1.2
	
	var atk_type: String = enemy_data.id if (enemy_data and not enemy_data.id.is_empty()) else (enemy_data.enemy_type if enemy_data else "melee")
	match atk_type:
		"ranged", "goblin_archer":
			_shoot_arrow()
		"crossbowman", "skeleton_crossbowman":
			_shoot_crossbow()
		"boulder_thrower", "stone_thrower":
			_throw_boulder()
		"necromancer", "necromancer_acolyte":
			_cast_necromancy()
		"frost_wraith", "ice_wraith":
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
		"support", "goblin_shaman":
			_try_heal_or_attack()
		"heavy", "goblin_brute", "troll_brute", "knight_guard":
			_heavy_attack()
		_:
			_melee_attack()

func _animate_ranged_weapon_recoil(recoil_px: float = -6.0, duration: float = 0.14) -> void:
	if _weapon_sprite == null:
		return
	var w_tween: Tween = create_tween()
	w_tween.tween_property(_weapon_sprite, "position:x", 11.0 + recoil_px, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	w_tween.tween_property(_weapon_sprite, "position:x", 11.0, duration * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _melee_attack() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var base_ang: float = dir.angle()
	attack_hitbox.rotation = base_ang
	attack_hitbox.reset_hits()
	
	_is_attack_animating = true
	var start_pos: Vector2 = position
	var facing_sign: float = -1.0 if visuals.scale.x < 0.0 else 1.0
	
	var tween: Tween = create_tween()
	# 1. Замах (Wind-up): отвод оружия назад и лёгкое приседание
	if _weapon_pivot != null:
		tween.tween_property(_weapon_pivot, "rotation", base_ang - 1.15 * facing_sign, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_interval(0.06)
	
	# 2. Резкий рубящий удар (Strike) с выпадом вперёд и дугой взмаха
	tween.tween_callback(func():
		attack_shape.disabled = false
		AudioManager.play_sfx_named("swing")
		var slash_col: Color = enemy_data.color if enemy_data else Color(1.0, 0.4, 0.3, 0.85)
		slash_col.a = 0.88
		EffectsHelper.spawn_slash_arc(get_parent(), global_position + dir * 20.0, base_ang, 26.0, slash_col)
	)
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang + 1.05 * facing_sign, 0.09).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos + dir * 22.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. Возврат в стойку (Recovery)
	tween.tween_callback(func(): attack_shape.disabled = true)
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _is_attack_animating = false)

func _heavy_attack() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	var base_ang: float = dir.angle()
	attack_hitbox.rotation = base_ang
	attack_hitbox.knockback_force = 420.0
	attack_hitbox.reset_hits()
	
	_is_attack_animating = true
	var start_pos: Vector2 = position
	var facing_sign: float = -1.0 if visuals.scale.x < 0.0 else 1.0
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.0, 1.2, 0.4, 1.0)
	# Замах тяжёлой булавой/дубиной над головой
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang - 1.5 * facing_sign, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos - dir * 10.0, 0.2)
	
	# Сокрушительный удар
	tween.tween_callback(func():
		attack_shape.disabled = false
		visuals.modulate = Color.WHITE
		AudioManager.play_sfx_named("swing")
		var slash_col: Color = Color(1.2, 0.7, 0.2, 0.92)
		EffectsHelper.spawn_slash_arc(get_parent(), global_position + dir * 26.0, base_ang, 34.0, slash_col)
		EffectsHelper.spawn_shockwave(get_parent(), global_position + dir * 24.0, 28.0, 0.18, Color(1.0, 0.65, 0.25, 0.7))
		EventBus.screen_shake_requested.emit(4.0, 0.15)
	)
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang + 1.25 * facing_sign, 0.11).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos + dir * 28.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func(): attack_shape.disabled = true)
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _is_attack_animating = false)

func _throw_boulder() -> void:
	var dir: Vector2 = (player_target.global_position - global_position).normalized()
	_animate_ranged_weapon_recoil(7.0, 0.18)
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
		_animate_ranged_weapon_recoil(-6.5, 0.14)
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
	_animate_ranged_weapon_recoil(5.0, 0.16)
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
	_animate_ranged_weapon_recoil(-5.5, 0.14)
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
	_animate_ranged_weapon_recoil(6.0, 0.16)
	if global_position.distance_to(player_target.global_position) < 100.0:
		var teleport_offset: Vector2 = -dir * 110.0 + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		position = _clamp_local_pos(position + teleport_offset)
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
	
	var leap_target: Vector2 = _clamp_local_pos(position + dir * 85.0)
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
	
	var bounce_target: Vector2 = _clamp_local_pos(position + dir * 65.0)
	var tween: Tween = create_tween()
	visuals.scale = Vector2(1.3, 0.7)
	tween.tween_property(visuals, "scale", Vector2(0.8, 1.3), 0.12)
	tween.tween_callback(func(): attack_shape.disabled = false)
	tween.tween_property(self, "position", bounce_target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
	
	var strike_target: Vector2 = _clamp_local_pos(position + dir * 75.0)
	var tween: Tween = create_tween()
	visuals.modulate = Color(0.4, 2.5, 0.6, 1.0)
	tween.tween_callback(func(): attack_shape.disabled = false)
	tween.tween_property(self, "position", strike_target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
		_animate_ranged_weapon_recoil(7.0, 0.16)
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
		_clamp_to_room()
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
	var base_ang: float = dir.angle()
	attack_hitbox.rotation = base_ang
	attack_hitbox.knockback_force = 480.0
	attack_hitbox.applied_effect = null
	attack_hitbox.reset_hits()
	
	_is_attack_animating = true
	var start_pos: Vector2 = position
	var facing_sign: float = -1.0 if visuals.scale.x < 0.0 else 1.0
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.3, 0.8, 1.0)
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang - 1.65 * facing_sign, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos - dir * 14.0, 0.26)
	tween.tween_callback(func():
		attack_shape.disabled = false
		visuals.modulate = Color.WHITE
		AudioManager.play_sfx_named("swing")
		EffectsHelper.spawn_slash_arc(get_parent(), global_position + dir * 28.0, base_ang, 40.0, Color(1.0, 0.15, 0.5, 0.92))
		EffectsHelper.spawn_shockwave(get_parent(), global_position + dir * 28.0, 36.0, 0.22, Color(0.95, 0.15, 0.45, 0.8))
		EventBus.screen_shake_requested.emit(7.0, 0.2)
	)
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang + 1.45 * facing_sign, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos + dir * 32.0, 0.12)
	tween.tween_callback(func(): attack_shape.disabled = true)
	if _weapon_pivot != null:
		tween.parallel().tween_property(_weapon_pivot, "rotation", base_ang, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", start_pos, 0.15)
	tween.tween_callback(func(): _is_attack_animating = false)

func _cast_flame_pillar() -> void:
	var target_pos: Vector2 = player_target.global_position
	_animate_ranged_weapon_recoil(6.0, 0.2)
	EffectsHelper.spawn_telegraph_circle(get_parent(), target_pos, 32.0, 0.5, Color(1.0, 0.35, 0.1, 0.55))
	
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func():
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

