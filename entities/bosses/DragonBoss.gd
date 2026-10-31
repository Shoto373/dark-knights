class_name DragonBoss
extends CharacterBody2D

## Босс биома «Мир огня»: Магматический Дракон
## 3 фазы: дыхание огнем, взлет с метеоритным шквалом и приземлением, магматическое исступление

signal phase_changed(new_phase: int)
signal boss_defeated

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")
const LAVA_HAZARD_SCENE = preload("res://levels/hazards/LavaHazard.tscn")
const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const ITEM_PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var attack_shape: CollisionShape2D = %AttackShape
@onready var tail_hitbox: HitboxComponent = %TailHitbox
@onready var tail_shape: CollisionShape2D = %TailShape
@onready var status_effect_manager: StatusEffectManager = %StatusEffectManager

@onready var visuals: Node2D = %Visuals
@onready var shadow_rect: ColorRect = %ShadowRect
@onready var wing_left: ColorRect = %WingLeft
@onready var wing_right: ColorRect = %WingRight
@onready var floor_telegraph: ColorRect = %FloorTelegraph

@export var boss_data: BossData

var player_target: Node2D = null
var current_phase: int = 1

var attack_timer: float = 0.0
var special_timer: float = 3.5
var is_acting: bool = false
var is_airborne: bool = false
var has_used_flight: bool = false

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")
	
	collision_layer = 4
	collision_mask = 1 | 4
	
	attack_hitbox.is_player_hitbox = false
	attack_hitbox.source_owner = self
	attack_hitbox.damage_type = "fire"
	attack_hitbox.tags = ["fire"]
	attack_shape.disabled = true
	
	tail_hitbox.is_player_hitbox = false
	tail_hitbox.source_owner = self
	tail_hitbox.damage_type = "fire"
	tail_hitbox.tags = ["fire"]
	tail_shape.disabled = true
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.is_player_hurtbox = false
	
	if boss_data == null:
		boss_data = load("res://data/enemies/boss_dragon.tres") as BossData
	
	if boss_data != null:
		health_component.max_health = boss_data.max_hp
		health_component.reset(boss_data.max_hp)
		movement_component.max_speed = boss_data.speed
		hurtbox_component.armor = boss_data.armor
		attack_hitbox.base_damage = boss_data.damage
		tail_hitbox.base_damage = int(round(boss_data.damage * 0.85))
	
	# Стилизованный спрайт босса
	var boss_tex: Texture2D = SpriteGenerator.get_boss_texture("dragon")
	if boss_tex != null and visuals != null:
		var boss_sprite: Sprite2D = visuals.get_node_or_null("BossSprite") as Sprite2D
		if boss_sprite == null:
			boss_sprite = Sprite2D.new()
			boss_sprite.name = "BossSprite"
			boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			boss_sprite.scale = Vector2(2.2, 2.2)
			visuals.add_child(boss_sprite)
		boss_sprite.texture = boss_tex
		for child in visuals.get_children():
			if child != boss_sprite and child is CanvasItem:
				(child as CanvasItem).visible = false
	
	if status_effect_manager != null:
		status_effect_manager.immunities = ["burn", "fire", "stun"]
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	floor_telegraph.visible = false
	EventBus.boss_spawned.emit(boss_data.name if boss_data else "Магматический Дракон", health_component.max_health)

func _physics_process(delta: float) -> void:
	if health_component.is_dead or is_airborne:
		return
	
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
	
	if is_instance_valid(player_target):
		var to_player: Vector2 = player_target.global_position - global_position
		var dir: Vector2 = to_player.normalized()
		var dist: float = to_player.length()
		
		# Поворот визуала в сторону игрока
		if dir.x < 0:
			visuals.scale.x = -1.0
		elif dir.x > 0:
			visuals.scale.x = 1.0
		
		if dist < 85.0 and attack_timer <= 0.0:
			_perform_tail_swipe()
		elif special_timer <= 0.0:
			_perform_flame_breath(dir)
		elif attack_timer <= 0.0:
			_perform_claw_dash(dir)
		else:
			# Преследование игрока
			if dist > 140.0:
				movement_component.move(self, dir, delta)
			else:
				movement_component.stop(self)

func _on_damaged(_amount: int, current_hp: int, max_hp: int) -> void:
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	_flash_red()
	
	# Фаза 2: при 60% HP дракон взмывает в воздух и обрушивает метеориты
	if current_phase == 1 and current_hp <= int(max_hp * 0.60):
		_enter_phase_2()
	# Фаза 3: при 30% HP ярость и лавовый шторм
	elif current_phase == 2 and current_hp <= int(max_hp * 0.30):
		_enter_phase_3()

func _flash_red() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(3.0, 0.4, 0.2, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)

func _enter_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	_take_flight()

func _enter_phase_3() -> void:
	current_phase = 3
	phase_changed.emit(3)
	
	movement_component.max_speed *= 1.35
	attack_hitbox.base_damage = int(round(attack_hitbox.base_damage * 1.3))
	
	EventBus.screen_shake_requested.emit(15.0, 0.6)
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(3.5, 1.2, 0.2, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.5)
	
	# Призыв лавовых слизней
	_summon_lava_slimes()

# --- СПОСОБНОСТИ И АТАКИ ---

func _perform_flame_breath(dir: Vector2) -> void:
	is_acting = true
	special_timer = 4.0 if current_phase == 1 else 2.8
	
	floor_telegraph.visible = true
	floor_telegraph.position = dir * 40.0 - Vector2(40, 40)
	floor_telegraph.size = Vector2(80, 80)
	floor_telegraph.color = Color(1.0, 0.3, 0.05, 0.45)
	
	var tween: Tween = create_tween()
	tween.tween_property(floor_telegraph, "color:a", 0.9, 0.35)
	tween.tween_callback(func():
		floor_telegraph.visible = false
		_emit_flame_cone(dir)
	)

func _emit_flame_cone(dir: Vector2) -> void:
	EventBus.screen_shake_requested.emit(7.0, 0.25)
	var base_ang: float = dir.angle()
	var count: int = 5 if current_phase < 3 else 7
	var spread: float = 0.55
	
	for i in range(count):
		var angle_offset: float = -spread / 2.0 + (float(i) / float(count - 1)) * spread
		var pdir: Vector2 = Vector2(cos(base_ang + angle_offset), sin(base_ang + angle_offset))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 30.0
		proj.setup(
			pdir,
			360.0,
			boss_data.damage if boss_data else 28,
			false,
			450.0,
			220.0,
			Color(1.0, 0.4, 0.05, 1.0),
			"fire",
			["fire"]
		)
	
	# В 3 фазе также вылетает круговая магма-нова
	if current_phase == 3:
		_emit_magma_nova()
	
	is_acting = false

func _emit_magma_nova() -> void:
	for i in range(10):
		var ang: float = (TAU / 10.0) * i
		var pdir: Vector2 = Vector2(cos(ang), sin(ang))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + pdir * 32.0
		proj.setup(
			pdir,
			280.0,
			20,
			false,
			400.0,
			200.0,
			Color(1.0, 0.6, 0.15, 1.0),
			"fire",
			["fire"]
		)

func _perform_tail_swipe() -> void:
	is_acting = true
	attack_timer = 1.6
	
	floor_telegraph.visible = true
	floor_telegraph.position = Vector2(-50, -50)
	floor_telegraph.size = Vector2(100, 100)
	floor_telegraph.color = Color(1.0, 0.15, 0.05, 0.4)
	
	var tween: Tween = create_tween()
	tween.tween_property(floor_telegraph, "color:a", 0.85, 0.3)
	tween.tween_callback(func():
		floor_telegraph.visible = false
		tail_hitbox.reset_hits()
		tail_shape.disabled = false
		EventBus.screen_shake_requested.emit(8.0, 0.2)
	)
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		tail_shape.disabled = true
		is_acting = false
	)

func _perform_claw_dash(dir: Vector2) -> void:
	is_acting = true
	attack_timer = 1.8
	
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.reset_hits()
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.8, 0.2, 1.0)
	tween.tween_property(self, "position", position - dir * 15.0, 0.2)
	tween.tween_callback(func():
		attack_shape.disabled = false
		visuals.modulate = Color.WHITE
		EventBus.screen_shake_requested.emit(6.0, 0.15)
	)
	tween.tween_property(self, "position", position + dir * 80.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		attack_shape.disabled = true
		is_acting = false
	)

# --- ФАЗА 2: ВЗЛЁТ, МЕТЕОРИТНЫЙ ШКВАЛ И ПРИЗЕМЛЕНИЕ ---

func _take_flight() -> void:
	is_airborne = true
	is_acting = true
	has_used_flight = true
	health_component.set_invulnerable(true)
	
	EventBus.screen_shake_requested.emit(10.0, 0.4)
	
	# Анимация взлёта дракона в воздух (увеличение масштаба и сдвиг тени)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visuals, "position:y", -60.0, 0.5)
	tween.tween_property(visuals, "scale", Vector2(1.4, 1.4), 0.5)
	tween.tween_property(shadow_rect, "scale", Vector2(0.7, 0.7), 0.5)
	tween.chain().tween_callback(_start_meteor_barrage)

func _start_meteor_barrage() -> void:
	var meteor_points: Array[Vector2] = [
		Vector2(420, 240),
		Vector2(860, 240),
		Vector2(640, 360),
		Vector2(420, 480),
		Vector2(860, 480),
		Vector2(520, 360),
		Vector2(760, 360)
	]
	
	for i in range(meteor_points.size()):
		var pt: Vector2 = meteor_points[i]
		var delay: float = 0.3 * i
		var tween: Tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func(): _drop_single_meteor(pt))
	
	# Через 2.8 секунды дракон с грохотом приземляется
	var land_tween: Tween = create_tween()
	land_tween.tween_interval(2.8)
	land_tween.tween_callback(_land_from_flight)

func _drop_single_meteor(target_pos: Vector2) -> void:
	var marker: ColorRect = ColorRect.new()
	marker.size = Vector2(70, 70)
	marker.position = target_pos - Vector2(35, 35)
	marker.color = Color(1.0, 0.25, 0.05, 0.45)
	get_parent().add_child(marker)
	
	var tween: Tween = create_tween()
	tween.tween_property(marker, "color:a", 0.95, 0.4)
	tween.tween_callback(func():
		marker.queue_free()
		EventBus.screen_shake_requested.emit(8.0, 0.25)
		
		# Снаряд метеоритного удара
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = target_pos
		proj.scale = Vector2(2.5, 2.5)
		proj.setup(
			Vector2.ZERO,
			0.001,
			25,
			false,
			10.0,
			260.0,
			Color(1.0, 0.5, 0.1, 1.0),
			"fire",
			["fire"]
		)
		var p_tween: Tween = proj.create_tween()
		p_tween.tween_interval(0.25)
		p_tween.tween_callback(proj.queue_free)
		
		# Оставляет временную лужу лавы на месте падения
		var lava: LavaHazard = LAVA_HAZARD_SCENE.instantiate() as LavaHazard
		lava.lifetime = 4.5
		lava.scale = Vector2(0.45, 0.45)
		get_parent().add_child(lava)
		lava.global_position = target_pos
	)

func _land_from_flight() -> void:
	is_airborne = false
	is_acting = false
	health_component.set_invulnerable(false)
	
	# Дракон пикирует в центр комнаты
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", Vector2(640, 360), 0.3)
	tween.tween_property(visuals, "position:y", 0.0, 0.3)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.3)
	tween.tween_property(shadow_rect, "scale", Vector2.ONE, 0.3)
	
	tween.chain().tween_callback(func():
		# Ударная волна при приземлении
		EventBus.screen_shake_requested.emit(18.0, 0.6)
		for i in range(8):
			var ang: float = (TAU / 8.0) * i
			var pdir: Vector2 = Vector2(cos(ang), sin(ang))
			var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
			get_parent().add_child(proj)
			proj.global_position = global_position + pdir * 36.0
			proj.setup(
				pdir,
				320.0,
				22,
				false,
				500.0,
				240.0,
				Color(1.0, 0.45, 0.1, 1.0),
				"fire",
				["fire"]
			)
	)

func _summon_lava_slimes() -> void:
	var offsets: Array[Vector2] = [Vector2(-90, 40), Vector2(90, 40)]
	var slime_data: EnemyData = load("res://data/enemies/lava_slime.tres") as EnemyData
	for off in offsets:
		var slime: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
		get_parent().add_child(slime)
		slime.global_position = global_position + off
		if slime_data != null:
			slime.setup_from_data(slime_data)

func _on_died() -> void:
	remove_from_group("bosses")
	remove_from_group("enemies")
	attack_shape.disabled = true
	tail_shape.disabled = true
	floor_telegraph.visible = false
	
	EventBus.boss_defeated.emit(boss_data.name if boss_data else "Магматический Дракон")
	boss_defeated.emit()
	
	if boss_data != null:
		GameState.add_gold(boss_data.gold_reward)
		MetaProgress.add_souls(boss_data.souls_reward)
	
	# Выбор 1 из 3 благословений
	_spawn_blessing_choice()
	
	# Спавн портала в Чистилище
	_spawn_portal_exit()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0)
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
		ped.global_position = global_position + Vector2(x_offsets[i], 40.0)
		ped.setup(choices[i], 0, true)

func _spawn_portal_exit() -> void:
	var portal_scene = load("res://levels/Portal.tscn")
	var portal = portal_scene.instantiate()
	get_parent().add_child(portal)
	portal.global_position = global_position + Vector2(0, -90.0)
	if portal.get_node_or_null("%PromptLabel") != null:
		portal.prompt_label.text = "[F] Войти в Чистилище"
	portal.next_world_node_id = "purgatory"
