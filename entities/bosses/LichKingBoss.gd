class_name LichKingBoss
extends CharacterBody2D

## Босс биома «Мир холода»: Король-лич
## 3 фазы боя, столбы льда, метель, призыв нежити и ключевая механика Филактерии

signal phase_changed(new_phase: int)
signal boss_defeated

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")
const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const ITEM_PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")
const ICE_PILLAR_SCENE = preload("res://entities/bosses/IcePillar.tscn")
const PHYLACTERY_SCENE = preload("res://entities/bosses/Phylactery.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var attack_shape: CollisionShape2D = %AttackShape
@onready var status_effect_manager: StatusEffectManager = %StatusEffectManager

@onready var visuals: Node2D = %Visuals
@onready var crown_rect: ColorRect = %CrownRect
@onready var staff_rect: ColorRect = %StaffRect
@onready var floor_telegraph: ColorRect = %FloorTelegraph

@export var boss_data: BossData

var player_target: Node2D = null
var current_phase: int = 1

var attack_timer: float = 0.0
var special_timer: float = 3.0
var teleport_timer: float = 6.0
var is_acting: bool = false
var _acting_watchdog: float = 0.0
var _teleport_tween: Tween = null

var phylactery_instance: Phylactery = null
var active_pillars: Array[Node2D] = []
var _shadow_sprite: Sprite2D = null
var _eye_light: PointLight2D = null
var _float_phase: float = 0.0

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")
	
	collision_layer = 4
	collision_mask = 1 | 4
	
	attack_hitbox.is_player_hitbox = false
	attack_hitbox.source_owner = self
	attack_hitbox.damage_type = "freeze"
	attack_hitbox.tags = ["frost", "ice"]
	attack_shape.disabled = true
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.is_player_hurtbox = false
	
	if boss_data == null:
		boss_data = load("res://data/enemies/boss_lich_king.tres") as BossData
	
	if boss_data != null:
		health_component.max_health = boss_data.max_hp
		health_component.reset(boss_data.max_hp)
		movement_component.max_speed = boss_data.speed
		hurtbox_component.armor = boss_data.armor
		attack_hitbox.base_damage = boss_data.damage
	
	# Стилизованный спрайт босса
	var boss_tex: Texture2D = SpriteGenerator.get_boss_texture("lich_king")
	if boss_tex != null and visuals != null:
		var boss_sprite: Sprite2D = visuals.get_node_or_null("BossSprite") as Sprite2D
		if boss_sprite == null:
			boss_sprite = Sprite2D.new()
			boss_sprite.name = "BossSprite"
			boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			boss_sprite.scale = Vector2(1.05, 1.05)
			visuals.add_child(boss_sprite)
		boss_sprite.texture = boss_tex
		for child in visuals.get_children():
			if child != boss_sprite and child is CanvasItem:
				(child as CanvasItem).visible = false
	
	if status_effect_manager != null:
		status_effect_manager.immunities = ["freeze", "stun"]
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_health_depleted)
	
	floor_telegraph.visible = false
	
	# Тень босса
	if _shadow_sprite == null:
		_shadow_sprite = Sprite2D.new()
		_shadow_sprite.name = "FloorShadow"
		_shadow_sprite.texture = EffectsHelper.get_spark_texture()
		_shadow_sprite.modulate = Color(0, 0, 0, 0.45)
		_shadow_sprite.scale = Vector2(4.2, 1.3)
		_shadow_sprite.position = Vector2(0, 24.0)
		_shadow_sprite.z_index = -1
		add_child(_shadow_sprite)
	
	# Светящийся ледяной взор Короля-лича
	if _eye_light == null and visuals != null:
		_eye_light = LightTextureGenerator.create_point_light(Color(0.3, 0.9, 1.2), 0.9, 1.4)
		_eye_light.name = "BossEyeLight"
		_eye_light.position = Vector2(0, -10.0)
		visuals.add_child(_eye_light)
	
	EventBus.boss_spawned.emit(boss_data.name if boss_data else "Король-лич", health_component.max_health)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_target):
		for p in get_tree().get_nodes_in_group("player"):
			player_target = p as Node2D
			break
	
	if is_acting:
		_acting_watchdog += delta
		if _acting_watchdog > 3.5:
			# Аварийный сброс: предотвращает зависание Лича в невидимости или фазе атаки
			if _teleport_tween != null and _teleport_tween.is_valid():
				_teleport_tween.kill()
			modulate.a = 1.0
			visuals.modulate = Color.WHITE
			is_acting = false
			_acting_watchdog = 0.0
		velocity = Vector2.ZERO
		move_and_slide()
		return
	else:
		_acting_watchdog = 0.0
	
	if attack_timer > 0.0:
		attack_timer -= delta
	if special_timer > 0.0:
		special_timer -= delta
	if teleport_timer > 0.0:
		teleport_timer -= delta
	
	if is_instance_valid(player_target):
		var to_player: Vector2 = player_target.global_position - global_position
		var dir: Vector2 = to_player.normalized()
		var dist: float = to_player.length()
		
		# Телепортация при сокращении дистанции или по таймеру
		if (dist < 120.0 or teleport_timer <= 0.0) and not is_acting:
			teleport_timer = 5.0
			_teleport_away()
			return
		
		# Фазовое поведение
		if current_phase == 3:
			# Фаза 3: Лич парит, прикрывая филактерию и обстреливая ледяными залпами
			if attack_timer <= 0.0:
				attack_timer = 1.4
				_fire_phase3_frost_barrage(dir)
		else:
			if special_timer <= 0.0:
				_perform_phase_special(dir)
			elif attack_timer <= 0.0:
				attack_timer = 1.8 if current_phase == 1 else 1.2
				_shoot_frost_skull_barrage(dir)
			else:
				# Удержание дистанции
				if dist > 220.0:
					movement_component.move(self, dir, delta)
				elif dist < 160.0:
					movement_component.move(self, -dir, delta)
				else:
					movement_component.stop(self)

	# Левитация и покачивание ледяного владыки
	_clamp_to_room()
	_float_phase += delta * 2.8
	var hover_y: float = sin(_float_phase) * 6.5 - 6.0
	visuals.position.y = hover_y
	visuals.rotation = sin(_float_phase * 0.8) * 0.07
	if _shadow_sprite != null:
		var s_shrink: float = clampf(1.0 - (hover_y / -14.0) * 0.25, 0.7, 1.2)
		_shadow_sprite.scale = Vector2(4.2 * s_shrink, 1.3 * s_shrink)
	if _eye_light != null:
		_eye_light.energy = 0.85 + sin(_float_phase * 2.0) * 0.15

func _get_room_origin() -> Vector2:
	var p: Node = get_parent()
	if p is Node2D:
		return (p as Node2D).global_position
	return Vector2.ZERO

func _is_in_dungeon_room() -> bool:
	var p: Node = get_parent()
	return p != null and (p.name == "EnemiesContainer" or p is DungeonRoom)

func _clamp_to_room() -> void:
	if _is_in_dungeon_room():
		position.x = clampf(position.x, 90.0, 1190.0)
		position.y = clampf(position.y, 90.0, 630.0)

func _get_safe_reward_center() -> Vector2:
	if _is_in_dungeon_room():
		var room_origin: Vector2 = _get_room_origin()
		return room_origin + Vector2(
			clampf(position.x, 260.0, 1020.0),
			clampf(position.y, 220.0, 540.0)
		)
	return global_position

func _on_damaged(_amount: int, current_hp: int, max_hp: int) -> void:
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	_flash_blue()
	
	# Переход во 2 фазу при 60% HP
	if current_phase == 1 and current_hp <= int(max_hp * 0.60):
		_enter_phase_2()

func _flash_blue() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.8, 2.5, 3.5, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)

func _enter_phase_2() -> void:
	current_phase = 2
	if _teleport_tween != null and _teleport_tween.is_valid():
		_teleport_tween.kill()
	is_acting = false
	_acting_watchdog = 0.0
	modulate.a = 1.0
	phase_changed.emit(2)
	
	movement_component.max_speed *= 1.25
	attack_hitbox.base_damage = int(round(attack_hitbox.base_damage * 1.2))
	
	EventBus.screen_shake_requested.emit(14.0, 0.5)
	EffectsHelper.spawn_death_burst(get_parent(), global_position, Color(0.3, 0.9, 1.3))
	if _eye_light != null:
		_eye_light.energy = 1.3
		_eye_light.color = Color(0.5, 1.2, 1.8)
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(0.8, 1.8, 3.5, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.4)
	
	# Призыв ледяной нежити
	_summon_frost_army()
	# Призыв 2 дополнительных ледяных колонн
	_spawn_ice_pillars()

func _enter_phase_3() -> void:
	current_phase = 3
	if _teleport_tween != null and _teleport_tween.is_valid():
		_teleport_tween.kill()
	is_acting = false
	_acting_watchdog = 0.0
	modulate.a = 1.0
	phase_changed.emit(3)
	
	# Лич становится бестелесным призраком, пока жива филактерия
	health_component.set_invulnerable(true)
	health_component.current_health = health_component.max_health
	health_component.is_dead = false
	visuals.modulate = Color(0.6, 1.5, 2.8, 0.65)
	
	EventBus.screen_shake_requested.emit(18.0, 0.8)
	
	# Спавним Филактерию в центре арены
	var room_origin: Vector2 = _get_room_origin()
	var phyl: Phylactery = PHYLACTERY_SCENE.instantiate() as Phylactery
	get_parent().add_child(phyl)
	phyl.global_position = room_origin + Vector2(640, 360)
	phyl.destroyed.connect(_on_phylactery_destroyed)
	phylactery_instance = phyl
	EventBus.boss_spawned.emit("Филактерия Короля-лича", phyl.health_component.max_health)
	
	# Телепортируем самого Лича к северному краю арены
	global_position = room_origin + Vector2(640, 200)

func _on_health_depleted() -> void:
	if current_phase < 3:
		# Здоровье Лича упало до 0 — активация Филактерии (Фаза 3)!
		_enter_phase_3()
	else:
		# Если филактерия уже была уничтожена
		_permanent_defeat()

func _on_phylactery_destroyed() -> void:
	# Филактерия разбита! Душа лича рассеивается
	health_component.set_invulnerable(false)
	_permanent_defeat()

func _permanent_defeat() -> void:
	remove_from_group("bosses")
	remove_from_group("enemies")
	attack_shape.disabled = true
	floor_telegraph.visible = false
	
	# Очищаем колонны
	for pil in active_pillars:
		if is_instance_valid(pil):
			pil.queue_free()
	active_pillars.clear()
	
	EventBus.boss_defeated.emit(boss_data.name if boss_data else "Король-лич")
	boss_defeated.emit()
	
	if boss_data != null:
		GameState.add_gold(boss_data.gold_reward)
		MetaProgress.add_souls(boss_data.souls_reward)
	
	# Выбор 1 из 3 наград
	_spawn_blessing_choice()
	
	# Спавн портала в Чистилище и развилки
	_spawn_portal_exit()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0)
	tween.chain().tween_callback(queue_free)

# --- АТАКИ И СПОСОБНОСТИ ---

func _shoot_frost_skull_barrage(dir: Vector2) -> void:
	# Выпускает веер из 3 морозных черепов
	var base_ang: float = dir.angle()
	var angles: Array[float] = [base_ang - 0.28, base_ang, base_ang + 0.28]
	for a in angles:
		var pdir: Vector2 = Vector2(cos(a), sin(a))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 25.0
		proj.setup(
			pdir,
			360.0,
			boss_data.damage if boss_data else 24,
			false,
			500.0,
			220.0,
			Color(0.3, 0.8, 1.0, 1.0),
			"freeze",
			["frost", "ice", "freeze"]
		)

func _perform_phase_special(dir: Vector2) -> void:
	is_acting = true
	special_timer = 5.0 if current_phase == 1 else 3.8
	
	if current_phase == 1:
		_cast_ice_pillars_and_nova()
	else:
		_cast_blizzard_storm(dir)

func _cast_ice_pillars_and_nova() -> void:
	EffectsHelper.spawn_telegraph_circle(get_parent(), global_position, 80.0, 0.4, Color(0.3, 0.8, 1.4, 0.6))
	
	var tween: Tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func():
		_spawn_ice_pillars()
		_release_frost_nova()
		is_acting = false
	)

func _spawn_ice_pillars() -> void:
	# Очищаем старые мертвые колонны
	active_pillars = active_pillars.filter(func(p): return is_instance_valid(p))
	if active_pillars.size() >= 4:
		return
	
	var room_origin: Vector2 = _get_room_origin()
	var pillar_positions: Array[Vector2] = [
		room_origin + Vector2(440, 240),
		room_origin + Vector2(840, 240),
		room_origin + Vector2(440, 480),
		room_origin + Vector2(840, 480)
	]
	
	for pos in pillar_positions:
		var pillar: IcePillar = ICE_PILLAR_SCENE.instantiate() as IcePillar
		get_parent().add_child(pillar)
		pillar.global_position = pos
		active_pillars.append(pillar)
		if active_pillars.size() >= 4:
			break

func _release_frost_nova() -> void:
	EventBus.screen_shake_requested.emit(8.0, 0.3)
	for i in range(8):
		var ang: float = (TAU / 8.0) * i
		var pdir: Vector2 = Vector2(cos(ang), sin(ang))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 30.0
		proj.setup(
			pdir,
			300.0,
			18,
			false,
			450.0,
			200.0,
			Color(0.5, 0.9, 1.0, 1.0),
			"freeze",
			["frost", "freeze"]
		)

func _cast_blizzard_storm(_dir: Vector2) -> void:
	var flash: Tween = create_tween()
	visuals.modulate = Color(1.8, 3.0, 4.0, 1.0)
	flash.tween_property(visuals, "modulate", Color.WHITE, 0.3)
	
	# Спиральная метель из 12 морозных кристаллов
	for i in range(12):
		var ang: float = (TAU / 12.0) * i
		var pdir: Vector2 = Vector2(cos(ang), sin(ang))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 28.0
		proj.setup(
			pdir,
			320.0,
			20,
			false,
			550.0,
			220.0,
			Color(0.6, 0.95, 1.0, 1.0),
			"freeze",
			["frost", "ice"]
		)
	EventBus.screen_shake_requested.emit(10.0, 0.35)
	is_acting = false

func _fire_phase3_frost_barrage(dir: Vector2) -> void:
	for i in range(4):
		var offset_ang: float = (i - 1.5) * 0.18
		var pdir: Vector2 = dir.rotated(offset_ang)
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 24.0
		proj.setup(
			pdir,
			400.0,
			22,
			false,
			600.0,
			240.0,
			Color(0.2, 0.8, 1.0, 1.0),
			"freeze",
			["frost"]
		)

func _summon_frost_army() -> void:
	var pool_paths: Array[String] = [
		"res://data/enemies/ice_wraith.tres",
		"res://data/enemies/skeleton_swordsman.tres",
		"res://data/enemies/ice_spider.tres"
	]
	var offsets: Array[Vector2] = [Vector2(-120, -60), Vector2(120, -60), Vector2(0, 100)]
	
	for i in range(offsets.size()):
		var e_path: String = pool_paths[i % pool_paths.size()]
		var edata: EnemyData = load(e_path) as EnemyData
		var enemy: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
		get_parent().add_child(enemy)
		enemy.global_position = global_position + offsets[i]
		if edata != null:
			enemy.setup_from_data(edata)

func _teleport_away() -> void:
	if is_acting:
		return
	is_acting = true
	_acting_watchdog = 0.0
	teleport_timer = 5.0
	
	if _teleport_tween != null and _teleport_tween.is_valid():
		_teleport_tween.kill()
	
	var room_origin: Vector2 = _get_room_origin()
	var corners: Array[Vector2] = [
		room_origin + Vector2(400, 240),
		room_origin + Vector2(880, 240),
		room_origin + Vector2(400, 480),
		room_origin + Vector2(880, 480),
		room_origin + Vector2(640, 220)
	]
	# Выбираем точку, наиболее далекую от игрока
	var best_pos: Vector2 = corners[0]
	var max_dist: float = -1.0
	var p_pos: Vector2 = player_target.global_position if is_instance_valid(player_target) else (room_origin + Vector2(640, 360))
	for pt in corners:
		var d: float = pt.distance_to(p_pos)
		if d > max_dist:
			max_dist = d
			best_pos = pt
	
	_teleport_tween = create_tween()
	_teleport_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_teleport_tween.tween_callback(func():
		global_position = best_pos
		visuals.modulate = Color(2.5, 3.5, 4.0, 1.0)
	)
	_teleport_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	_teleport_tween.tween_property(visuals, "modulate", Color.WHITE, 0.2)
	_teleport_tween.tween_callback(func():
		modulate.a = 1.0
		is_acting = false
		_acting_watchdog = 0.0
	)

func _spawn_blessing_choice() -> void:
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	if loot_table == null:
		return
	
	var choices: Array[ItemData] = loot_table.roll_multiple_unique(3, GameState.rng)
	var x_offsets: Array[float] = [-140.0, 0.0, 140.0]
	var center: Vector2 = _get_safe_reward_center()
	
	for i in range(choices.size()):
		var ped: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		get_parent().add_child(ped)
		ped.global_position = center + Vector2(x_offsets[i], 40.0)
		ped.setup(choices[i], 0, true)

func _spawn_portal_exit() -> void:
	var portal_scene = load("res://levels/Portal.tscn")
	var portal = portal_scene.instantiate()
	get_parent().add_child(portal)
	portal.global_position = _get_safe_reward_center() + Vector2(0, -90.0)
	if portal.has_method("set_portal_title"):
		portal.set_portal_title("ПОРТАЛ ВЫХОДА")
	portal.prompt_label.text = "[F] Вперед"

