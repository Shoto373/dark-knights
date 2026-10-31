class_name PurgatoryLordBoss
extends CharacterBody2D

## Финальный босс игры: «Владыка Чистилища»
## 3 фазы: Призма стихий (огонь и лед), Призыв эхо-душ и гравитация, Истинный облик и вращающийся луч пустоты

signal phase_changed(new_phase: int)
signal boss_defeated

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")
const VOID_RIFT_SCENE = preload("res://levels/hazards/VoidRiftTrap.tscn")
const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const VICTORY_SCREEN_SCENE = preload("res://ui/VictoryScreen.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var attack_shape: CollisionShape2D = %AttackShape
@onready var status_effect_manager: StatusEffectManager = %StatusEffectManager

@onready var visuals: Node2D = %Visuals
@onready var wings_node: Node2D = %Wings
@onready var halo_rect: ColorRect = %HaloRect
@onready var floor_telegraph: ColorRect = %FloorTelegraph
@onready var beam_pivot: Node2D = %BeamPivot
@onready var beam_hitbox: HitboxComponent = %BeamHitbox
@onready var beam_shape: CollisionShape2D = %BeamShape
@onready var beam_visual: ColorRect = %BeamVisual

@export var boss_data: BossData

var player_target: Node2D = null
var current_phase: int = 1

var attack_timer: float = 0.0
var special_timer: float = 3.2
var teleport_timer: float = 5.5
var is_acting: bool = false
var is_beam_active: bool = false
var beam_rotation_speed: float = 1.4

var active_rifts: Array[Node2D] = []

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")
	
	collision_layer = 4
	collision_mask = 1 | 4
	
	attack_hitbox.is_player_hitbox = false
	attack_hitbox.source_owner = self
	attack_hitbox.damage_type = "astral"
	attack_shape.disabled = true
	
	beam_hitbox.is_player_hitbox = false
	beam_hitbox.source_owner = self
	beam_hitbox.damage_type = "astral"
	beam_shape.disabled = true
	beam_visual.visible = false
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.is_player_hurtbox = false
	
	if boss_data == null:
		boss_data = load("res://data/enemies/boss_purgatory_lord.tres") as BossData
	
	if boss_data != null:
		health_component.max_health = boss_data.max_hp
		health_component.reset(boss_data.max_hp)
		movement_component.max_speed = boss_data.speed
		hurtbox_component.armor = boss_data.armor
		attack_hitbox.base_damage = boss_data.damage
		beam_hitbox.base_damage = int(round(boss_data.damage * 0.7))
	
	# Стилизованный спрайт босса
	var boss_tex: Texture2D = SpriteGenerator.get_boss_texture("purgatory_lord")
	if boss_tex != null and visuals != null:
		var boss_sprite: Sprite2D = visuals.get_node_or_null("BossSprite") as Sprite2D
		if boss_sprite == null:
			boss_sprite = Sprite2D.new()
			boss_sprite.name = "BossSprite"
			boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			boss_sprite.scale = Vector2(2.2, 2.2)
			visuals.add_child(boss_sprite)
		boss_sprite.texture = boss_tex
		if visuals.has_node("BodyRect"):
			visuals.get_node("BodyRect").visible = false
		if visuals.has_node("ChestCore"):
			visuals.get_node("ChestCore").visible = false
		if visuals.has_node("EyesRect"):
			visuals.get_node("EyesRect").visible = false
	
	if status_effect_manager != null:
		status_effect_manager.immunities = ["freeze", "burn", "poison", "stun"]
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	floor_telegraph.visible = false
	EventBus.boss_spawned.emit(boss_data.name if boss_data else "Владыка Чистилища", health_component.max_health)

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return
	
	# Вращение луча пустоты в Фазе 3
	if is_beam_active and beam_pivot != null:
		beam_pivot.rotation += beam_rotation_speed * delta
	
	if not is_instance_valid(player_target):
		for p in get_tree().get_nodes_in_group("player"):
			player_target = p as Node2D
			break
	
	if is_acting:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
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
		
		# Телепортация при близком контакте или таймеру
		if (dist < 110.0 or teleport_timer <= 0.0) and not is_acting:
			teleport_timer = 5.0
			_teleport_with_flash()
			return
		
		if special_timer <= 0.0:
			_perform_phase_special(dir)
		elif attack_timer <= 0.0:
			attack_timer = 1.6 if current_phase == 1 else 1.1
			_shoot_elemental_lances(dir)
		else:
			# Удержание дистанции
			if dist > 240.0:
				movement_component.move(self, dir, delta)
			elif dist < 170.0:
				movement_component.move(self, -dir, delta)
			else:
				movement_component.stop(self)

func _on_damaged(_amount: int, current_hp: int, max_hp: int) -> void:
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	_flash_purple()
	
	# Фаза 2: при 60% HP
	if current_phase == 1 and current_hp <= int(max_hp * 0.60):
		_enter_phase_2()
	# Фаза 3: при 30% HP
	elif current_phase == 2 and current_hp <= int(max_hp * 0.30):
		_enter_phase_3()

func _flash_purple() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 1.2, 3.5, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)

func _enter_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	
	movement_component.max_speed *= 1.2
	EventBus.screen_shake_requested.emit(12.0, 0.5)
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.8, 0.8, 3.2, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.4)
	
	# Призыв эхо-душ
	_summon_echoes()
	# Разлом в центре арены
	_spawn_center_rift()

func _enter_phase_3() -> void:
	current_phase = 3
	phase_changed.emit(3)
	
	movement_component.max_speed *= 1.35
	attack_hitbox.base_damage = int(round(attack_hitbox.base_damage * 1.3))
	
	EventBus.screen_shake_requested.emit(20.0, 0.8)
	
	# Трансформация: раскрываются крылья пустоты
	wings_node.visible = true
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visuals, "scale", Vector2(1.35, 1.35), 0.5)
	tween.tween_property(halo_rect, "modulate", Color(2.0, 1.0, 3.5, 1.0), 0.5)
	
	# Активация вращающегося луча пустоты
	_activate_spinning_void_beam()

# --- СПОСОБНОСТИ И АТАКИ ---

func _shoot_elemental_lances(dir: Vector2) -> void:
	# Выпускает двойные копья стихий (одно огненное, одно ледяное)
	var base_ang: float = dir.angle()
	var angles: Array[float] = [base_ang - 0.2, base_ang + 0.2]
	
	# Огненное копьё
	var pdir_fire: Vector2 = Vector2(cos(angles[0]), sin(angles[0]))
	var p_fire: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(p_fire)
	p_fire.global_position = global_position + pdir_fire * 26.0
	p_fire.setup(
		pdir_fire,
		380.0,
		boss_data.damage if boss_data else 28,
		false,
		550.0,
		200.0,
		Color(1.0, 0.4, 0.1, 1.0),
		"fire",
		["fire"]
	)
	
	# Ледяное копьё
	var pdir_frost: Vector2 = Vector2(cos(angles[1]), sin(angles[1]))
	var p_frost: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(p_frost)
	p_frost.global_position = global_position + pdir_frost * 26.0
	p_frost.setup(
		pdir_frost,
		380.0,
		boss_data.damage if boss_data else 28,
		false,
		550.0,
		200.0,
		Color(0.3, 0.85, 1.0, 1.0),
		"freeze",
		["frost", "ice"]
	)

func _perform_phase_special(dir: Vector2) -> void:
	is_acting = true
	special_timer = 4.5 if current_phase == 1 else 3.2
	
	if current_phase == 1:
		_cast_rift_and_nova()
	elif current_phase == 2:
		_cast_void_spiral_storm(dir)
	else:
		_cast_apocalyptic_nova()

func _cast_rift_and_nova() -> void:
	floor_telegraph.visible = true
	floor_telegraph.position = Vector2(-70, -70)
	floor_telegraph.size = Vector2(140, 140)
	floor_telegraph.color = Color(0.6, 0.2, 0.9, 0.45)
	
	var tween: Tween = create_tween()
	tween.tween_property(floor_telegraph, "color:a", 0.9, 0.4)
	tween.tween_callback(func():
		floor_telegraph.visible = false
		EventBus.screen_shake_requested.emit(8.0, 0.25)
		# Круговая волна астральных сфер
		for i in range(8):
			var ang: float = (TAU / 8.0) * i
			var pdir: Vector2 = Vector2(cos(ang), sin(ang))
			var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
			get_parent().add_child(proj)
			proj.global_position = global_position + pdir * 28.0
			proj.setup(
				pdir,
				320.0,
				22,
				false,
				480.0,
				220.0,
				Color(0.8, 0.4, 1.0, 1.0),
				"astral",
				["astral"]
			)
		is_acting = false
	)

func _cast_void_spiral_storm(_dir: Vector2) -> void:
	var flash: Tween = create_tween()
	visuals.modulate = Color(3.0, 1.5, 4.0, 1.0)
	flash.tween_property(visuals, "modulate", Color.WHITE, 0.25)
	
	EventBus.screen_shake_requested.emit(10.0, 0.35)
	for i in range(12):
		var ang: float = (TAU / 12.0) * i
		var pdir: Vector2 = Vector2(cos(ang), sin(ang))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 30.0
		proj.setup(
			pdir,
			340.0,
			24,
			false,
			550.0,
			240.0,
			Color(0.9, 0.5, 1.0, 1.0),
			"astral",
			["astral"]
		)
	is_acting = false

func _cast_apocalyptic_nova() -> void:
	EventBus.screen_shake_requested.emit(14.0, 0.4)
	# Чередующаяся волна из 16 снарядов всех стихий
	for i in range(16):
		var ang: float = (TAU / 16.0) * i
		var pdir: Vector2 = Vector2(cos(ang), sin(ang))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 32.0
		
		var dtype: String = "fire" if i % 2 == 0 else "freeze"
		var pcolor: Color = Color(1.0, 0.45, 0.1, 1.0) if i % 2 == 0 else Color(0.3, 0.9, 1.0, 1.0)
		proj.setup(
			pdir,
			300.0,
			22,
			false,
			500.0,
			200.0,
			pcolor,
			dtype,
			[dtype]
		)
	is_acting = false

func _activate_spinning_void_beam() -> void:
	is_beam_active = true
	beam_shape.disabled = false
	beam_visual.visible = true
	
	# Пульсация луча
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(beam_visual, "modulate:a", 0.6, 0.25)
	tween.tween_property(beam_visual, "modulate:a", 1.0, 0.25)

func _summon_echoes() -> void:
	var echo_paths: Array[String] = [
		"res://data/enemies/shadow_chimera.tres",
		"res://data/enemies/fallen_archon.tres"
	]
	var offsets: Array[Vector2] = [Vector2(-120, -50), Vector2(120, -50)]
	
	for i in range(offsets.size()):
		var edata: EnemyData = load(echo_paths[i]) as EnemyData
		var echo: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
		get_parent().add_child(echo)
		echo.global_position = global_position + offsets[i]
		if edata != null:
			echo.setup_from_data(edata)

func _spawn_center_rift() -> void:
	var rift: VoidRiftTrap = VOID_RIFT_SCENE.instantiate() as VoidRiftTrap
	get_parent().add_child(rift)
	rift.global_position = Vector2(640, 360)
	active_rifts.append(rift)

func _teleport_with_flash() -> void:
	var corners: Array[Vector2] = [
		Vector2(380, 220),
		Vector2(900, 220),
		Vector2(380, 500),
		Vector2(900, 500),
		Vector2(640, 200)
	]
	var best_pos: Vector2 = corners[0]
	var max_dist: float = -1.0
	var p_pos: Vector2 = player_target.global_position if is_instance_valid(player_target) else Vector2(640, 360)
	for pt in corners:
		var d: float = pt.distance_to(p_pos)
		if d > max_dist:
			max_dist = d
			best_pos = pt
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		global_position = best_pos
		visuals.modulate = Color(3.0, 2.0, 4.0, 1.0)
	)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.2)

func _on_died() -> void:
	remove_from_group("bosses")
	remove_from_group("enemies")
	attack_shape.disabled = true
	beam_shape.disabled = true
	is_beam_active = false
	beam_visual.visible = false
	floor_telegraph.visible = false
	
	# Очищаем разломы
	for r in active_rifts:
		if is_instance_valid(r):
			r.queue_free()
	active_rifts.clear()
	
	EventBus.boss_defeated.emit(boss_data.name if boss_data else "Владыка Чистилища")
	boss_defeated.emit()
	
	if boss_data != null:
		GameState.add_gold(boss_data.gold_reward)
		MetaProgress.add_souls(boss_data.souls_reward)
	
	# Триумфальный экран победы!
	_trigger_victory_sequence()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 1.2)
	tween.chain().tween_callback(queue_free)

func _trigger_victory_sequence() -> void:
	EventBus.screen_shake_requested.emit(25.0, 1.2)
	
	var victory: VictoryScreen = VICTORY_SCREEN_SCENE.instantiate() as VictoryScreen
	get_tree().root.add_child(victory)

