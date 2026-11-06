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
var is_swinging: bool = false
var dash_direction: Vector2 = Vector2.RIGHT
var aim_direction: Vector2 = Vector2.RIGHT

var ability_1_timer: Timer
var ability_2_timer: Timer
var shield_barrier: ShieldBarrier = null
var _walk_anim_phase: float = 0.0
var _ghost_timer: float = 0.0
var _facing_left: bool = false
var _shadow_sprite: Sprite2D = null
var _left_boot: Sprite2D = null
var _right_boot: Sprite2D = null
var _eye_light: PointLight2D = null
var _base_eye_energy: float = 0.65
var _step_dust_timer: float = 0.0

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
	_setup_character_shadow()
	
	# Мягкий динамический фонарь героя (Forward+ Vulkan 2D Lighting)
	var lantern_light: PointLight2D = LightTextureGenerator.create_point_light(Color(1.0, 0.92, 0.8), 0.82, 2.8)
	lantern_light.name = "LanternLight"
	add_child(lantern_light)
	
	# Визуальный щит и руническая эгида (Warrior block / charge)
	var shield_scene: PackedScene = load("res://entities/player/ShieldBarrier.tscn")
	if shield_scene != null:
		shield_barrier = shield_scene.instantiate() as ShieldBarrier
		add_child(shield_barrier)
	
	EventBus.player_spawned.emit(self)

func apply_hero_data(data: HeroData) -> void:
	if data == null:
		return
	hero_data = data
	
	health_component.max_health = hero_data.max_hp
	if GameState.is_run_active and GameState.current_hp > 0:
		health_component.current_health = mini(GameState.current_hp, health_component.max_health)
	else:
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

	# Установка анимированных сапог героя
	var boot_tex: Texture2D = SpriteGenerator.get_hero_boot_texture(hero_id)
	if boot_tex != null and visuals != null:
		if _left_boot == null:
			_left_boot = Sprite2D.new()
			_left_boot.name = "LeftBoot"
			_left_boot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_left_boot.z_index = -1
			visuals.add_child(_left_boot)
		_left_boot.texture = boot_tex
		_left_boot.position = Vector2(-5.0, 16.0)
		
		if _right_boot == null:
			_right_boot = Sprite2D.new()
			_right_boot.name = "RightBoot"
			_right_boot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_right_boot.z_index = -1
			visuals.add_child(_right_boot)
		_right_boot.texture = boot_tex
		_right_boot.position = Vector2(5.0, 16.0)

	# Стилизованный светящийся взор героя (Forward+ Eye Glow Light)
	var eye_color: Color = Color(0.25, 0.9, 1.0)
	match hero_id:
		"warrior":
			eye_color = Color(0.25, 0.9, 1.0)
			_base_eye_energy = 0.7
		"mage":
			eye_color = Color(0.85, 0.35, 1.25)
			_base_eye_energy = 0.85
		"ranger":
			eye_color = Color(1.0, 0.8, 0.25)
			_base_eye_energy = 0.7
	if _eye_light == null and visuals != null:
		_eye_light = LightTextureGenerator.create_point_light(eye_color, _base_eye_energy, 0.7)
		_eye_light.name = "HeroEyeLight"
		_eye_light.position = Vector2(0, -6.0)
		visuals.add_child(_eye_light)
	elif _eye_light != null:
		_eye_light.color = eye_color
		_eye_light.energy = _base_eye_energy

	# Установка детализированного оружия героя
	var weapon_tex: Texture2D = SpriteGenerator.get_weapon_texture(hero_id)
	if weapon_pivot != null and weapon_tex != null:
		var weapon_sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
		if weapon_sprite == null:
			weapon_sprite = Sprite2D.new()
			weapon_sprite.name = "WeaponSprite"
			weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			weapon_pivot.add_child(weapon_sprite)
		weapon_sprite.texture = weapon_tex
		weapon_sprite.position = Vector2(18, 0)
		weapon_sprite.visible = true
		var old_w_visual: Node = weapon_pivot.get_node_or_null("WeaponVisual")
		if old_w_visual is CanvasItem:
			old_w_visual.visible = false
	
	if hero_data.ability_1 != null:
		ability_1_timer.wait_time = hero_data.ability_1.cooldown
	if hero_data.ability_2 != null:
		ability_2_timer.wait_time = hero_data.ability_2.cooldown
	
	recalculate_stats()
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)

func _setup_character_shadow() -> void:
	if _shadow_sprite == null:
		_shadow_sprite = Sprite2D.new()
		_shadow_sprite.name = "FloorShadow"
		_shadow_sprite.texture = EffectsHelper.get_spark_texture()
		_shadow_sprite.scale = Vector2(2.5, 0.9)
		_shadow_sprite.position = Vector2(0, 18.0)
		_shadow_sprite.modulate = Color(0, 0, 0, 0.5)
		_shadow_sprite.z_index = -1
		add_child(_shadow_sprite)
	EventBus.hero_changed.emit(hero_data)

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
	if is_instance_valid(shield_barrier):
		shield_barrier.update_aim(aim_direction)
	_handle_input()
	_update_procedural_animations(delta)
	_update_iframes_blink(delta)

func _update_procedural_animations(delta: float) -> void:
	_step_dust_timer = maxf(0.0, _step_dust_timer - delta)
	var cur_facing: float = -1.0 if _facing_left else 1.0

	if is_dashing:
		_ghost_timer += delta
		if _ghost_timer >= 0.035:
			_ghost_timer = 0.0
			var char_sprite: Sprite2D = visuals.get_node_or_null("CharacterSprite") as Sprite2D
			var tex: Texture2D = char_sprite.texture if char_sprite else null
			var ghost_tint: Color = hero_data.color if hero_data else Color(0.3, 0.8, 1.0, 0.7)
			ghost_tint.a = 0.65
			EffectsHelper.spawn_dash_ghost(get_parent(), global_position, tex, visuals.scale.x < 0, ghost_tint)
		if _shadow_sprite != null:
			_shadow_sprite.scale = Vector2(3.2, 0.65)
		return
	
	var is_moving: bool = velocity.length_squared() > 100.0
	if is_moving:
		_walk_anim_phase += delta * 15.0
		var step_sin: float = sin(_walk_anim_phase)
		
		# Динамическое покачивание корпуса (Bobbing)
		visuals.position.y = -abs(step_sin) * 4.2
		
		# Наклон корпуса по направлению бега (Running lean)
		var run_lean: float = clampf(velocity.x / 260.0, -1.0, 1.0) * 0.14
		visuals.rotation = run_lean + step_sin * 0.05
		
		# Пружинистый сквош и стретч при шаге
		var squash_y: float = 1.0 + sin(_walk_anim_phase * 2.0) * 0.06
		var squash_x: float = (1.0 - sin(_walk_anim_phase * 2.0) * 0.03) * cur_facing
		visuals.scale = Vector2(squash_x, squash_y)
		
		# Динамическая деформация тени под ногами
		if _shadow_sprite != null:
			_shadow_sprite.scale = Vector2(2.5 + abs(step_sin) * 0.35, 0.9 - abs(step_sin) * 0.18)
		
		# Пыль от шагов при приземлении стопы
		if abs(step_sin) > 0.88 and _step_dust_timer <= 0.0:
			var foot_offset: Vector2 = Vector2(-5.0 if step_sin > 0 else 5.0, 14.0)
			EffectsHelper.spawn_dust_puff(get_parent(), global_position + foot_offset)
			_step_dust_timer = 0.22

		# Анимированный шаг стопами в противофазе с дугой отрыва от пола
		if _left_boot != null and _right_boot != null:
			_left_boot.position.x = -5.0 - step_sin * 6.0
			_left_boot.position.y = 16.0 - maxf(0.0, -step_sin) * 4.0
			_left_boot.rotation = -step_sin * 0.25
			
			_right_boot.position.x = 5.0 + step_sin * 6.0
			_right_boot.position.y = 16.0 - maxf(0.0, step_sin) * 4.0
			_right_boot.rotation = step_sin * 0.25
	else:
		_walk_anim_phase += delta * 3.0
		visuals.position.y = move_toward(visuals.position.y, 0.0, delta * 25.0)
		visuals.rotation = move_toward(visuals.rotation, 0.0, delta * 4.0)
		
		if _left_boot != null and _right_boot != null:
			_left_boot.position = _left_boot.position.lerp(Vector2(-5.0, 16.0), delta * 12.0)
			_right_boot.position = _right_boot.position.lerp(Vector2(5.0, 16.0), delta * 12.0)
			_left_boot.rotation = lerp(_left_boot.rotation, 0.0, delta * 12.0)
			_right_boot.rotation = lerp(_right_boot.rotation, 0.0, delta * 12.0)
		
		# Живое дыхание очей
		if _eye_light != null:
			_eye_light.energy = _base_eye_energy + sin(_walk_anim_phase * 1.5) * 0.15
		
		# Живое дыхание в покое (Idle breathing)
		var breath: float = sin(_walk_anim_phase) * 0.035
		visuals.scale = Vector2((1.0 - breath * 0.5) * cur_facing, 1.0 + breath)
		
		# Плавное парение оружия в покое
		var w_sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
		if w_sprite != null and not is_swinging:
			w_sprite.position.y = sin(_walk_anim_phase * 1.3) * 1.8
		
		if _shadow_sprite != null:
			_shadow_sprite.scale = Vector2(2.5 + breath * 0.3, 0.9 - breath * 0.1)

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
	var joy_aim: Vector2 = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if joy_aim.length_squared() > 0.25:
		aim_direction = joy_aim.normalized()
	else:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var to_mouse: Vector2 = (mouse_pos - global_position)
		if to_mouse.length_squared() > 100.0:
			aim_direction = to_mouse.normalized()
	
	if not is_swinging:
		weapon_pivot.rotation = aim_direction.angle()
	
	# Дедзона по оси X для устранения мерцания переворота при прицеливании строго вверх/вниз
	if aim_direction.x < -0.08:
		_facing_left = true
	elif aim_direction.x > 0.08:
		_facing_left = false
	
	visuals.scale.x = -1.0 if _facing_left else 1.0
	
	var w_sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
	if w_sprite != null:
		w_sprite.flip_v = _facing_left
	
	# Оружие всегда отображается поверх персонажа и никогда не уходит под пол
	weapon_pivot.z_index = 1

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
	
	# Динамический наклон и аэродинамический стретч при рывке
	var cur_facing: float = -1.0 if _facing_left else 1.0
	visuals.scale = Vector2(1.35 * cur_facing, 0.72)
	visuals.rotation = dash_direction.angle() * 0.35
	
	EffectsHelper.spawn_dust_puff(get_parent(), global_position)
	EffectsHelper.spawn_shockwave(get_parent(), global_position, 110.0, 0.28, 0.035)
	AudioManager.play_sfx_named("dash")
	
	# Кинематографическая отдача камеры в сторону, противоположную рывку
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_kick"):
		cam.call("add_kick", -dash_direction, 7.5)
	
	dash_timer.start()
	dash_cooldown_timer.start()

func _on_dash_finished() -> void:
	is_dashing = false
	if iframes_timer.is_stopped():
		health_component.set_invulnerable(false)
	visuals.modulate.a = 1.0
	
	# Пружинный отскок после рывка
	var cur_facing: float = -1.0 if _facing_left else 1.0
	var bounce_tween: Tween = visuals.create_tween()
	bounce_tween.tween_property(visuals, "scale", Vector2(cur_facing, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(visuals, "rotation", 0.0, 0.1)

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
	is_swinging = true
	AudioManager.play_sfx_named("swing")
	
	var base_angle: float = aim_direction.angle()
	var is_aiming_left: bool = (aim_direction.x < 0.0)
	
	var start_angle: float = base_angle + (deg_to_rad(65.0) if is_aiming_left else -deg_to_rad(65.0))
	var end_angle: float = base_angle + (-deg_to_rad(65.0) if is_aiming_left else deg_to_rad(65.0))
	
	weapon_pivot.rotation = start_angle
	
	var slash_color: Color = Color(0.9, 0.95, 1.0, 0.85)
	if weapon_hitbox.damage_type == "fire" or weapon_hitbox.tags.has("fire"):
		slash_color = Color(1.0, 0.5, 0.1, 0.9)
	elif weapon_hitbox.damage_type == "freeze" or weapon_hitbox.tags.has("frost"):
		slash_color = Color(0.3, 0.85, 1.0, 0.9)
	EffectsHelper.spawn_slash_arc(get_parent(), global_position + aim_direction * 22.0, base_angle, 28.0, slash_color)

	# Отдача камеры при ударе
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_kick"):
		cam.call("add_kick", -aim_direction, 4.0)

	var tween: Tween = create_tween()
	tween.tween_property(weapon_pivot, "rotation", end_angle, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		attack_collision.disabled = true
	)
	tween.tween_property(weapon_pivot, "rotation", base_angle, 0.08)
	tween.tween_callback(func():
		is_swinging = false
	)

	# Выпад телом вперед и упругий возврат при ударе
	var cur_facing: float = -1.0 if _facing_left else 1.0
	var thrust_tween: Tween = visuals.create_tween()
	thrust_tween.tween_property(visuals, "position", aim_direction * 10.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	thrust_tween.tween_property(visuals, "position", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var squash_tween: Tween = visuals.create_tween()
	squash_tween.tween_property(visuals, "scale", Vector2(1.24 * cur_facing, 0.8), 0.07).set_trans(Tween.TRANS_QUAD)
	squash_tween.tween_property(visuals, "scale", Vector2(cur_facing, 1.0), 0.12).set_trans(Tween.TRANS_BACK)

	# Увеличение оружия на пике взмаха (Weapon scale pop)
	var w_sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
	if w_sprite != null:
		var w_pop: Tween = w_sprite.create_tween()
		w_pop.tween_property(w_sprite, "scale", Vector2(1.35, 1.35), 0.07).set_trans(Tween.TRANS_QUAD)
		w_pop.tween_property(w_sprite, "scale", Vector2(1.0, 1.0), 0.12)

func _shoot_basic_projectile() -> void:
	AudioManager.play_sfx_named("shoot")
	
	# Отдача камеры при выстреле/касте
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_kick"):
		cam.call("add_kick", -aim_direction, 5.0)

	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(proj)
	proj.global_position = global_position + aim_direction * 20.0
	
	# Отдача тела назад от выстрела/каста
	var cur_facing: float = -1.0 if _facing_left else 1.0
	var recoil_tween: Tween = visuals.create_tween()
	recoil_tween.tween_property(visuals, "position", -aim_direction * 6.0, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil_tween.tween_property(visuals, "position", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var stretch_tween: Tween = visuals.create_tween()
	stretch_tween.tween_property(visuals, "scale", Vector2(0.88 * cur_facing, 1.15), 0.06)
	stretch_tween.tween_property(visuals, "scale", Vector2(cur_facing, 1.0), 0.12).set_trans(Tween.TRANS_BACK)

	# Отдача оружия назад (Kickback)
	var w_sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
	if w_sprite != null:
		var kick_tween: Tween = w_sprite.create_tween()
		kick_tween.tween_property(w_sprite, "position:x", 10.0, 0.05).set_trans(Tween.TRANS_QUAD)
		kick_tween.tween_property(w_sprite, "position:x", 18.0, 0.12).set_trans(Tween.TRANS_BACK)

	# Вспышка искр на кончике посоха / лука
	var muzzle_color: Color = Color(0.9, 0.5, 1.4) if hero_data and hero_data.id == "mage" else Color(1.2, 1.1, 0.5)
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position + aim_direction * 26.0, muzzle_color, 5)

	var p_type: String = "magic" if hero_data and hero_data.id == "mage" else "arrow"
	if weapon_hitbox.damage_type == "fire" or weapon_hitbox.tags.has("fire"):
		p_type = "fireball"
	elif weapon_hitbox.damage_type == "freeze" or weapon_hitbox.tags.has("frost"):
		p_type = "frost"

	var proj_damage: int = weapon_hitbox.base_damage if weapon_hitbox.base_damage > 0 else (hero_data.attack_damage if hero_data else 20)
	proj.setup(
		aim_direction,
		hero_data.projectile_speed if hero_data else 500.0,
		proj_damage,
		true,
		hero_data.attack_range if hero_data else 500.0,
		180.0,
		hero_data.color if hero_data else Color.WHITE,
		weapon_hitbox.damage_type,
		weapon_hitbox.tags,
		p_type
	)
	if proj.hitbox != null:
		proj.hitbox.crit_chance = weapon_hitbox.crit_chance
		proj.hitbox.crit_multiplier = weapon_hitbox.crit_multiplier

func _trigger_ability(ability: AbilityData, timer: Timer) -> void:
	if not timer.is_stopped() or is_dashing:
		return
	
	AudioManager.play_sfx_named("cast")
	timer.start()
	
	# Сочный отклик каста: рунический круг под ногами, волна и сквош персонажа
	var cast_color: Color = Color(1.2, 0.9, 0.3)
	if hero_data != null:
		match hero_data.id:
			"mage":
				cast_color = Color(0.4, 0.85, 1.4)
			"ranger":
				cast_color = Color(0.3, 1.3, 0.6)
			_:
				cast_color = Color(1.2, 0.9, 0.3)
	
	EffectsHelper.spawn_cast_circle(get_parent(), global_position, cast_color)
	EffectsHelper.spawn_shockwave(get_parent(), global_position, 85.0, 0.22, 0.025)
	EffectsHelper.spawn_magic_burst(get_parent(), global_position, cast_color, 8)
	
	var cur_sx: float = signf(visuals.scale.x)
	var cast_tween: Tween = visuals.create_tween()
	cast_tween.tween_property(visuals, "scale", Vector2(1.22 * cur_sx, 0.78), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cast_tween.tween_property(visuals, "scale", Vector2(0.88 * cur_sx, 1.18), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cast_tween.tween_property(visuals, "scale", Vector2(cur_sx, 1.0), 0.08)
	
	var w_sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
	if w_sprite != null:
		EffectsHelper.apply_hit_flash(w_sprite, 0.14, Color(2.0, 2.0, 1.8))
	
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
	
	# Активируем физический щит и защитный купол
	if is_instance_valid(shield_barrier):
		shield_barrier.activate_block(ability.duration)
	
	visuals.modulate = Color(1.3, 1.3, 0.8, 1.0)
	var tween: Tween = create_tween()
	tween.tween_interval(ability.duration)
	tween.tween_callback(func():
		if iframes_timer.is_stopped():
			health_component.set_invulnerable(false)
		visuals.modulate = Color.WHITE
		if is_instance_valid(shield_barrier):
			shield_barrier.deactivate()
	)

func _apply_dash_ability(ability: AbilityData) -> void:
	is_dashing = true
	dash_direction = aim_direction
	health_component.set_invulnerable(true)
	
	# Выпад щитом вперед при таране
	if is_instance_valid(shield_barrier):
		shield_barrier.activate_charge(dash_direction, ability.duration)
	
	EffectsHelper.spawn_shockwave(get_parent(), global_position, 110.0, 0.28, 0.035)
	EffectsHelper.spawn_dust_puff(get_parent(), global_position)
	visuals.modulate = Color(1.5, 0.6, 0.6, 0.9)
	
	weapon_hitbox.base_damage = ability.base_damage
	weapon_hitbox.reset_hits()
	attack_collision.disabled = false
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "velocity", dash_direction * ability.speed, ability.duration)
	tween.tween_callback(func():
		is_dashing = false
		attack_collision.disabled = true
		recalculate_stats()
		health_component.set_invulnerable(false)
		visuals.modulate = Color.WHITE
	)

func _get_ability_scaled_damage(base_ability_damage: int) -> int:
	if hero_data == null or hero_data.attack_damage <= 0 or weapon_hitbox == null or weapon_hitbox.base_damage <= 0:
		return base_ability_damage
	var dmg_mult: float = float(weapon_hitbox.base_damage) / float(hero_data.attack_damage)
	return maxi(base_ability_damage, int(round(base_ability_damage * dmg_mult)))

func _apply_aoe_ability(ability: AbilityData) -> void:
	var target_pos: Vector2 = get_global_mouse_position()
	var dist: float = (target_pos - global_position).length()
	if dist > 350.0:
		target_pos = global_position + (target_pos - global_position).normalized() * 350.0
	
	var scaled_dmg: int = _get_ability_scaled_damage(ability.base_damage)
	var is_fire: bool = ability.id == "fireball" or ability.name.to_lower().contains("огн") or ability.name.to_lower().contains("fire")
	
	if is_fire:
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		var fly_dir: Vector2 = (target_pos - global_position).normalized()
		proj.global_position = global_position + fly_dir * 20.0
		var fly_time: float = clampf(dist / 650.0, 0.12, 0.42)
		proj.setup(fly_dir, 650.0, 0, true, dist + 60.0, 0.0, Color(1.4, 0.6, 0.1), "fire", ["fire"], "fireball")
		if proj.collision_shape != null:
			proj.collision_shape.disabled = true
		
		var fly_tween: Tween = create_tween()
		fly_tween.tween_interval(fly_time)
		fly_tween.tween_callback(func():
			if is_instance_valid(proj):
				proj.queue_free()
			var aoe: AreaOfEffect = AOE_SCENE.instantiate() as AreaOfEffect
			get_parent().add_child(aoe)
			aoe.setup(target_pos, ability.range_or_radius, scaled_dmg, true, 400.0, Color(1.3, 0.45, 0.1, 0.85))
			aoe.hitbox.damage_type = "fire"
			aoe.hitbox.tags = ["fire"]
			aoe.hitbox.crit_chance = weapon_hitbox.crit_chance
			aoe.hitbox.crit_multiplier = weapon_hitbox.crit_multiplier
			EffectsHelper.spawn_shockwave(get_parent(), target_pos, ability.range_or_radius * 1.3, 0.28, 0.045)
			EffectsHelper.spawn_hit_sparks(get_parent(), target_pos, Color(1.0, 0.65, 0.15), 14)
		)
	else:
		var aoe: AreaOfEffect = AOE_SCENE.instantiate() as AreaOfEffect
		get_parent().add_child(aoe)
		aoe.setup(target_pos, ability.range_or_radius, scaled_dmg, true, 400.0)
		aoe.hitbox.crit_chance = weapon_hitbox.crit_chance
		aoe.hitbox.crit_multiplier = weapon_hitbox.crit_multiplier
		EffectsHelper.spawn_shockwave(get_parent(), target_pos, ability.range_or_radius * 1.2, 0.25, 0.035)

func _apply_teleport_ability(ability: AbilityData) -> void:
	var old_pos: Vector2 = global_position
	var max_dist: float = ability.range_or_radius
	var target_pos: Vector2 = old_pos + aim_direction * max_dist
	
	# Проверка препятствий (слой 1: world) — маг не может телепортироваться сквозь стены
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space_state != null:
		var ray_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(old_pos, target_pos, 1) # Layer 1: World
		ray_query.collide_with_areas = false
		ray_query.collide_with_bodies = true
		var hit: Dictionary = space_state.intersect_ray(ray_query)
		if not hit.is_empty():
			var hit_dist: float = old_pos.distance_to(hit.position)
			var safe_dist: float = maxf(0.0, hit_dist - 24.0)
			target_pos = old_pos + aim_direction * safe_dist
	
	# Дополнительная проверка коллизии в целевой точке — отступаем, если задеваем стену
	var step_back_dir: Vector2 = (old_pos - target_pos).normalized()
	var test_attempts: int = 0
	while test_move(Transform2D(0.0, target_pos), Vector2.ZERO, null, 0.08, true) and test_attempts < 12 and target_pos.distance_to(old_pos) > 4.0:
		target_pos += step_back_dir * 4.0
		test_attempts += 1
	
	health_component.set_invulnerable(true)
	
	EffectsHelper.spawn_cast_circle(get_parent(), old_pos, Color(0.8, 0.4, 1.2))
	EffectsHelper.spawn_magic_burst(get_parent(), old_pos, Color(0.8, 0.4, 1.2), 14)
	EffectsHelper.spawn_shockwave(get_parent(), old_pos, 70.0, 0.2, 0.03)
	
	visuals.modulate.a = 0.0
	global_position = target_pos
	
	EffectsHelper.spawn_cast_circle(get_parent(), target_pos, Color(0.4, 0.8, 1.4))
	EffectsHelper.spawn_magic_burst(get_parent(), target_pos, Color(0.4, 0.8, 1.4), 16)
	EffectsHelper.spawn_shockwave(get_parent(), target_pos, 90.0, 0.22, 0.035)
	
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "modulate:a", 1.0, 0.12)
	tween.tween_callback(func():
		health_component.set_invulnerable(false)
	)

func _apply_projectile_ability(ability: AbilityData) -> void:
	var count: int = ability.projectile_count
	var half_spread: float = deg_to_rad(ability.spread_angle_deg) / 2.0
	var base_angle: float = aim_direction.angle()
	var scaled_dmg: int = _get_ability_scaled_damage(ability.base_damage)
	
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
			scaled_dmg,
			true,
			ability.range_or_radius,
			220.0,
			hero_data.color if hero_data else Color.WHITE,
			weapon_hitbox.damage_type,
			weapon_hitbox.tags
		)
		if proj.hitbox != null:
			proj.hitbox.crit_chance = weapon_hitbox.crit_chance
			proj.hitbox.crit_multiplier = weapon_hitbox.crit_multiplier

func _on_attack_cooldown_finished() -> void:
	can_attack = true

func _on_health_damaged(amount: int, current_hp: int, max_hp: int) -> void:
	GameState.current_hp = current_hp
	GameState.max_hp = max_hp
	GameState.run_stats["damage_taken"] = GameState.run_stats.get("damage_taken", 0) + amount
	EventBus.player_health_changed.emit(current_hp, max_hp)
	EventBus.screen_shake_requested.emit(5.0, 0.2)
	EventBus.hit_stop_requested.emit(40.0)
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(1.0, 0.3, 0.3, 1.0), 6)
	
	EffectsHelper.apply_hit_flash(visuals, 0.14, Color(1.0, 0.3, 0.3, 1.0))
	
	# Отклик на получение урона (Flinch & Squash)
	var cur_facing: float = -1.0 if _facing_left else 1.0
	var flinch_tween: Tween = visuals.create_tween()
	flinch_tween.tween_property(visuals, "scale", Vector2(1.25 * cur_facing, 0.78), 0.05).set_trans(Tween.TRANS_QUAD)
	flinch_tween.tween_property(visuals, "scale", Vector2(cur_facing, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if status_effect_manager == null or not status_effect_manager.is_processing_dot:
		health_component.set_invulnerable(true)
		iframes_timer.start()

func _on_health_healed(amount: int, current_hp: int, max_hp: int) -> void:
	GameState.current_hp = current_hp
	GameState.max_hp = max_hp
	EventBus.player_health_changed.emit(current_hp, max_hp)
	EventBus.player_healed.emit(amount)

func _on_health_died() -> void:
	is_dashing = false
	velocity = Vector2.ZERO
	if dash_timer != null and not dash_timer.is_stopped():
		dash_timer.stop()
	GameState.current_hp = 0
	EventBus.player_health_changed.emit(0, health_component.max_health)
	EventBus.player_died.emit()
	
	# Анимация поражения: распад искр души и падение
	EffectsHelper.spawn_death_burst(get_parent(), global_position, Color(0.85, 0.2, 0.2, 1.0))
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(1.0, 0.8, 0.2, 1.0), 10)
	var fall_tween: Tween = visuals.create_tween().set_parallel(true)
	fall_tween.tween_property(visuals, "rotation", deg_to_rad(85.0), 0.3).set_ease(Tween.EASE_OUT)
	fall_tween.tween_property(visuals, "position:y", 6.0, 0.3)
	fall_tween.tween_property(visuals, "modulate", Color(0.6, 0.2, 0.2, 0.5), 0.3)

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
	if dash_cooldown_timer == null or dash_cooldown_timer.is_stopped() or dash_cooldown_timer.wait_time <= 0.0:
		return 1.0
	return clampf(1.0 - (dash_cooldown_timer.time_left / dash_cooldown_timer.wait_time), 0.0, 1.0)

func get_dash_cooldown_time_left() -> float:
	if dash_cooldown_timer == null or dash_cooldown_timer.is_stopped():
		return 0.0
	return dash_cooldown_timer.time_left

func get_ability_cooldown_ratio(slot: int) -> float:
	var t: Timer = ability_1_timer if slot == 1 else ability_2_timer
	if t == null or t.is_stopped() or t.wait_time <= 0.0:
		return 1.0
	return clampf(1.0 - (t.time_left / t.wait_time), 0.0, 1.0)

func get_ability_cooldown_time_left(slot: int) -> float:
	var t: Timer = ability_1_timer if slot == 1 else ability_2_timer
	if t == null or t.is_stopped():
		return 0.0
	return t.time_left
