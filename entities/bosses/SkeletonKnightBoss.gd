class_name SkeletonKnightBoss
extends CharacterBody2D

## Босс биома 3: Рыцарь-скелет (3 фазы боя, индикаторы на полу, призыв армии, ярость)

signal phase_changed(new_phase: int)
signal boss_defeated

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")
const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const ITEM_PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var attack_shape: CollisionShape2D = %AttackShape

@onready var visuals: Node2D = %Visuals
@onready var body_rect: ColorRect = %BodyRect
@onready var shield_rect: ColorRect = %ShieldRect
@onready var sword_rect: ColorRect = %SwordRect
@onready var floor_telegraph: ColorRect = %FloorTelegraph

@export var boss_data: BossData

var player_target: Node2D = null
var current_phase: int = 1

var attack_timer: float = 0.0
var special_timer: float = 3.0
var is_acting: bool = false

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")
	
	collision_layer = 4
	collision_mask = 1 | 4
	
	attack_hitbox.is_player_hitbox = false
	attack_hitbox.source_owner = self
	attack_shape.disabled = true
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.is_player_hurtbox = false
	
	if boss_data == null:
		boss_data = load("res://data/enemies/boss_skeleton_knight.tres") as BossData
	
	if boss_data != null:
		health_component.max_health = boss_data.max_hp
		health_component.reset(boss_data.max_hp)
		movement_component.max_speed = boss_data.speed
		hurtbox_component.armor = boss_data.armor
		attack_hitbox.base_damage = boss_data.damage
	
	# Стилизованный спрайт босса
	var boss_tex: Texture2D = SpriteGenerator.get_boss_texture("skeleton_knight")
	if boss_tex != null and visuals != null:
		var boss_sprite: Sprite2D = visuals.get_node_or_null("BossSprite") as Sprite2D
		if boss_sprite == null:
			boss_sprite = Sprite2D.new()
			boss_sprite.name = "BossSprite"
			boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			boss_sprite.scale = Vector2(1.9, 1.9)
			visuals.add_child(boss_sprite)
		boss_sprite.texture = boss_tex
		for child in visuals.get_children():
			if child != boss_sprite and child != shield_rect and child is CanvasItem:
				(child as CanvasItem).visible = false
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	floor_telegraph.visible = false
	EventBus.boss_spawned.emit(boss_data.name if boss_data else "Рыцарь-скелет", health_component.max_health)

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
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
		var dist: float = to_player.length()
		var dir: Vector2 = to_player.normalized()
		
		# Выбор поведения по фазам
		if special_timer <= 0.0:
			_perform_special_ability(dir)
		elif dist <= 80.0 and attack_timer <= 0.0:
			_perform_telegraphed_slash(dir)
		else:
			movement_component.move(self, dir, delta)

func _on_damaged(_amount: int, current_hp: int, max_hp: int) -> void:
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	_flash_red()
	
	# Фаза 2: при 66% HP (порог 400 из 600)
	if current_phase == 1 and current_hp <= int(max_hp * 0.66):
		_enter_phase_2()
	# Фаза 3 (Ярость): при 33% HP (порог 200 из 600)
	elif current_phase == 2 and current_hp <= int(max_hp * 0.33):
		_enter_phase_3()

func _enter_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	
	movement_component.max_speed *= 1.2
	EventBus.screen_shake_requested.emit(10.0, 0.4)
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.8, 1.2, 2.2, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.4)
	
	# Фаза 2: призыв армии скелетов
	_summon_skeleton_army()

func _enter_phase_3() -> void:
	current_phase = 3
	phase_changed.emit(3)
	
	movement_component.max_speed *= 1.35
	attack_hitbox.base_damage = int(round(attack_hitbox.base_damage * 1.35))
	
	# Сбрасывает щит и зажигает меч проклятым огнём
	shield_rect.visible = false
	sword_rect.scale = Vector2(1.5, 1.5)
	sword_rect.modulate = Color(0.2, 1.8, 3.0, 1.0) # Синее проклятое пламя
	
	EventBus.screen_shake_requested.emit(16.0, 0.6)
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.5, 0.2, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.5)

func _flash_red() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.3, 0.3, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)

# --- АТАКИ И ТЕЛЕГРАФИРОВАНИЕ ---

func _perform_telegraphed_slash(dir: Vector2) -> void:
	is_acting = true
	attack_timer = 1.2 if current_phase < 3 else 0.7
	
	# Показываем красный предупреждающий индикатор на полу
	floor_telegraph.visible = true
	floor_telegraph.position = dir * 35.0 - Vector2(30, 30)
	floor_telegraph.size = Vector2(60, 60)
	floor_telegraph.color = Color(1.0, 0.15, 0.1, 0.4)
	
	var tween: Tween = create_tween()
	tween.tween_property(floor_telegraph, "color:a", 0.85, 0.35)
	tween.tween_callback(func():
		floor_telegraph.visible = false
		_strike_sword(dir)
	)

func _strike_sword(dir: Vector2) -> void:
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.reset_hits()
	attack_shape.disabled = false
	
	EventBus.screen_shake_requested.emit(6.0, 0.2)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + dir * 25.0, 0.1)
	tween.tween_callback(func(): attack_shape.disabled = true)
	tween.tween_property(self, "position", position, 0.12)
	tween.tween_callback(func(): is_acting = false)

func _perform_special_ability(dir: Vector2) -> void:
	match current_phase:
		1:
			# Фаза 1: Рывок-выпад с длинным индикатором на полу
			_perform_dash_thrust(dir)
		2:
			# Фаза 2: Спиральный залп костяных копий
			_perform_bone_barrage()
		3:
			# Фаза 3: Тройное комбо в ярости с волной проклятой энергии
			_perform_enrage_combo(dir)

func _perform_dash_thrust(dir: Vector2) -> void:
	is_acting = true
	special_timer = 4.0
	
	# Линейный прямоугольный телеграф на полу
	floor_telegraph.visible = true
	floor_telegraph.position = Vector2.ZERO
	floor_telegraph.rotation = dir.angle()
	floor_telegraph.size = Vector2(240, 40)
	floor_telegraph.position = -Vector2(0, 20)
	floor_telegraph.color = Color(1.0, 0.2, 0.1, 0.5)
	
	var tween: Tween = create_tween()
	tween.tween_property(floor_telegraph, "color:a", 0.9, 0.4)
	tween.tween_callback(func():
		floor_telegraph.visible = false
		floor_telegraph.rotation = 0
		_execute_dash_thrust(dir)
	)

func _execute_dash_thrust(dir: Vector2) -> void:
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.reset_hits()
	attack_shape.disabled = false
	EventBus.screen_shake_requested.emit(8.0, 0.25)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + dir * 200.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		attack_shape.disabled = true
		is_acting = false
	)

func _summon_skeleton_army() -> void:
	var skel_data: EnemyData = load("res://data/enemies/skeleton_swordsman.tres") as EnemyData
	var bow_data: EnemyData = load("res://data/enemies/skeleton_crossbowman.tres") as EnemyData
	
	var offsets: Array[Vector2] = [Vector2(-70, 40), Vector2(70, 40)]
	var datas: Array[EnemyData] = [skel_data, bow_data]
	
	for i in range(2):
		var minion: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
		get_parent().add_child(minion)
		minion.global_position = global_position + offsets[i]
		if datas[i] != null:
			minion.setup_from_data(datas[i])

func _perform_bone_barrage() -> void:
	is_acting = true
	special_timer = 4.5
	
	var tween: Tween = create_tween()
	visuals.modulate = Color(1.5, 0.8, 2.5, 1.0)
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		visuals.modulate = Color.WHITE
		_fire_bone_spears_ring()
		is_acting = false
	)

func _fire_bone_spears_ring() -> void:
	var count: int = 8
	var step: float = TAU / float(count)
	for i in range(count):
		var angle: float = i * step
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position
		proj.setup(dir, 300.0, 16, false, 480.0, 220.0, Color(0.85, 0.85, 0.9, 1.0))

func _perform_enrage_combo(dir: Vector2) -> void:
	is_acting = true
	special_timer = 3.2
	
	# Серия из двух быстрых ударов и выброса проклятой волны
	_perform_telegraphed_slash(dir)
	var timer: SceneTreeTimer = get_tree().create_timer(0.4)
	timer.timeout.connect(func():
		if is_instance_valid(self) and not health_component.is_dead:
			_fire_cursed_cross_wave()
	)

func _fire_cursed_cross_wave() -> void:
	var cardinal_dirs: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for c_dir in cardinal_dirs:
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position
		proj.setup(c_dir, 380.0, 20, false, 500.0, 240.0, Color(0.2, 1.6, 2.8, 1.0))
	EventBus.screen_shake_requested.emit(10.0, 0.3)

func _on_died() -> void:
	remove_from_group("bosses")
	remove_from_group("enemies")
	attack_shape.disabled = true
	floor_telegraph.visible = false
	
	EventBus.boss_defeated.emit(boss_data.name if boss_data else "Рыцарь-скелет")
	boss_defeated.emit()
	
	if boss_data != null:
		GameState.add_gold(boss_data.gold_reward)
		MetaProgress.add_souls(boss_data.souls_reward)
	
	# Спавн выбора 1 из 3 благословений
	_spawn_blessing_choice()
	
	# Спавн экрана развилки и портала перехода
	_spawn_fork_exit()
	
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

func _spawn_fork_exit() -> void:
	var portal_scene: PackedScene = load("res://levels/Portal.tscn")
	if portal_scene == null:
		return
	var portal = portal_scene.instantiate()
	get_parent().add_child(portal)
	portal.global_position = global_position + Vector2(0, -90.0)
	if portal.get_node_or_null("%PromptLabel") != null:
		portal.prompt_label.text = "[F] Развилка Миров"
	
	portal.on_enter_callback = func():
		var cutscene_scene: PackedScene = load("res://ui/CutsceneScreen.tscn")
		if cutscene_scene != null:
			var cutscene: CutsceneScreen = cutscene_scene.instantiate() as CutsceneScreen
			get_tree().root.add_child(cutscene)
			cutscene.show_victory_cutscene(func():
				var branch_scene: PackedScene = load("res://ui/BranchChoiceDialog.tscn")
				if branch_scene != null:
					var branch_inst = branch_scene.instantiate()
					get_tree().root.add_child(branch_inst)
			)
		else:
			var branch_scene: PackedScene = load("res://ui/BranchChoiceDialog.tscn")
			if branch_scene != null:
				var branch_inst = branch_scene.instantiate()
				get_tree().root.add_child(branch_inst)
