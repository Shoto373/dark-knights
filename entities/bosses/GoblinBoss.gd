class_name GoblinBoss
extends CharacterBody2D

## Босс биома 1: Вождь гоблинов (двухфазный бой)

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
@onready var crown_rect: ColorRect = %CrownRect

@export var boss_data: BossData

var player_target: Node2D = null
var current_phase: int = 1
var attack_timer: float = 0.0
var special_timer: float = 3.0
var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO

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
		boss_data = load("res://data/enemies/boss_goblin_chieftain.tres") as BossData
	
	if boss_data != null:
		health_component.max_health = boss_data.max_hp
		health_component.reset(boss_data.max_hp)
		movement_component.max_speed = boss_data.speed
		hurtbox_component.armor = boss_data.armor
		attack_hitbox.base_damage = boss_data.damage
	
	# Стилизованный спрайт босса
	var boss_tex: Texture2D = SpriteGenerator.get_boss_texture("goblin_boss")
	if boss_tex != null and visuals != null:
		var boss_sprite: Sprite2D = visuals.get_node_or_null("BossSprite") as Sprite2D
		if boss_sprite == null:
			boss_sprite = Sprite2D.new()
			boss_sprite.name = "BossSprite"
			boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			boss_sprite.scale = Vector2(1.8, 1.8)
			visuals.add_child(boss_sprite)
		boss_sprite.texture = boss_tex
		for child in visuals.get_children():
			if child != boss_sprite and child is CanvasItem:
				(child as CanvasItem).visible = false
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	EventBus.boss_spawned.emit(boss_data.name if boss_data else "Вождь гоблинов", health_component.max_health)

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return
	
	if not is_instance_valid(player_target):
		for p in get_tree().get_nodes_in_group("player"):
			player_target = p as Node2D
			break
	
	if attack_timer > 0.0:
		attack_timer -= delta
	if special_timer > 0.0:
		special_timer -= delta
	
	if is_charging:
		velocity = charge_direction * (movement_component.max_speed * 2.2)
		move_and_slide()
		return
	
	if is_instance_valid(player_target):
		var to_player: Vector2 = player_target.global_position - global_position
		var dist: float = to_player.length()
		
		if special_timer <= 0.0:
			_perform_special_ability(to_player.normalized())
		elif dist <= 60.0 and attack_timer <= 0.0:
			_melee_cleave(to_player.normalized())
		else:
			movement_component.move(self, to_player.normalized(), delta)

func _on_damaged(_amount: int, current_hp: int, max_hp: int) -> void:
	EventBus.boss_health_changed.emit(current_hp, max_hp)
	_flash_red()
	
	if current_phase == 1 and current_hp <= (max_hp / 2):
		_enter_phase_2()

func _enter_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	
	movement_component.max_speed *= 1.35
	attack_hitbox.base_damage = int(round(attack_hitbox.base_damage * 1.3))
	
	EventBus.screen_shake_requested.emit(10.0, 0.4)
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 0.5, 0.2, 1.0)
	crown_rect.color = Color(1.0, 0.1, 0.1, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.4)
	
	_summon_reinforcements()

func _summon_reinforcements() -> void:
	var slasher_data: EnemyData = load("res://data/enemies/goblin_slasher.tres") as EnemyData
	var offsets: Array[Vector2] = [Vector2(-60, 40), Vector2(60, 40)]
	
	for offset in offsets:
		var minion: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
		get_parent().add_child(minion)
		minion.global_position = global_position + offset
		if slasher_data != null:
			minion.setup_from_data(slasher_data)

func _melee_cleave(dir: Vector2) -> void:
	attack_timer = 1.0 if current_phase == 1 else 0.7
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.reset_hits()
	attack_shape.disabled = false
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + dir * 30.0, 0.15)
	tween.tween_callback(func(): attack_shape.disabled = true)
	tween.tween_property(self, "position", position, 0.15)

func _perform_special_ability(dir: Vector2) -> void:
	special_timer = 4.0 if current_phase == 1 else 2.5
	
	if current_phase == 1:
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 30.0
		proj.setup(dir, 420.0, attack_hitbox.base_damage, false, 500.0, 240.0, Color(0.9, 0.3, 0.1, 1.0))
	else:
		_start_charge(dir)

func _start_charge(dir: Vector2) -> void:
	is_charging = true
	charge_direction = dir
	attack_hitbox.reset_hits()
	attack_shape.disabled = false
	visuals.modulate = Color(2.5, 1.0, 0.2, 1.0)
	
	var tween: Tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func():
		is_charging = false
		attack_shape.disabled = true
		visuals.modulate = Color.WHITE
	)

func _flash_red() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.0, 0.3, 0.3, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.1)

func _on_died() -> void:
	remove_from_group("bosses")
	remove_from_group("enemies")
	attack_shape.disabled = true
	
	EventBus.boss_defeated.emit(boss_data.name if boss_data else "Вождь гоблинов")
	boss_defeated.emit()
	
	if boss_data != null:
		GameState.add_gold(boss_data.gold_reward)
		MetaProgress.add_souls(boss_data.souls_reward)
	
	# Спавн выбора 1 из 3 благословений (Isaac/Hades style)
	_spawn_blessing_choice()
	
	# Появление портала выхода на арене
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
		ped.setup(choices[i], 0, true) # is_blessing_choice = true!

func _spawn_exit_portal() -> void:
	var portal_scene = load("res://levels/Portal.tscn")
	var portal = portal_scene.instantiate()
	get_parent().add_child(portal)
	portal.global_position = global_position + Vector2(0, -90.0)
	portal.target_scene = "res://levels/DungeonFloor.tscn"
	if portal.has_method("set_portal_title"):
		portal.set_portal_title("УЩЕЛЬЕ ТРОЛЛЕЙ")
	portal.prompt_label.text = "[F] Перейти в Ущелье троллей"
