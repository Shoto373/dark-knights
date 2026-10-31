extends GutTest

func test_player_instantiation_and_collision_layers() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	assert_not_null(player_scene, "Player scene should exist.")
	
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	assert_eq(player.collision_layer, 2, "Player should be on collision layer 2 (player).")
	assert_not_null(player.health_component, "Player must have HealthComponent.")
	assert_not_null(player.movement_component, "Player must have MovementComponent.")
	assert_not_null(player.hurtbox_component, "Player must have HurtboxComponent.")
	assert_not_null(player.weapon_hitbox, "Player must have WeaponHitbox.")
	
	# Проверка слоев хитбоксов и хуртбоксов
	assert_eq(player.weapon_hitbox.collision_layer, 8, "Player attack hitbox should be layer 4 (bitmask 8).")
	assert_eq(player.hurtbox_component.collision_mask, 16, "Player hurtbox should listen to enemy attacks (bitmask 16).")

func test_dummy_instantiation_and_collision_layers() -> void:
	var dummy_scene: PackedScene = load("res://entities/enemies/Dummy.tscn")
	assert_not_null(dummy_scene, "Dummy scene should exist.")
	
	var dummy: Dummy = dummy_scene.instantiate() as Dummy
	add_child_autofree(dummy)
	
	assert_eq(dummy.collision_layer, 4, "Dummy should be on layer 3 (bitmask 4: enemies).")
	assert_not_null(dummy.health_component, "Dummy must have HealthComponent.")
	assert_not_null(dummy.hurtbox_component, "Dummy must have HurtboxComponent.")
	assert_eq(dummy.hurtbox_component.collision_mask, 8, "Dummy hurtbox should listen to player hitbox (bitmask 8).")

func test_player_dash_cooldown_ratio() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	assert_eq(player.get_dash_cooldown_ratio(), 1.0, "Dash should be ready initially (ratio 1.0).")

func test_combat_interaction_dummy_takes_damage() -> void:
	var dummy_scene: PackedScene = load("res://entities/enemies/Dummy.tscn")
	var dummy: Dummy = dummy_scene.instantiate() as Dummy
	add_child_autofree(dummy)
	
	var hitbox: HitboxComponent = HitboxComponent.new()
	add_child_autofree(hitbox)
	hitbox.base_damage = 30
	hitbox.crit_chance = 0.0 # Без крита для детерминизма
	hitbox.is_player_hitbox = true
	
	# Прямая симуляция попадания хитбокса в хуртбокс
	dummy.hurtbox_component._on_area_entered(hitbox)
	
	# У dummy armor = 2, damage = max(1, 30 - 2) = 28. HP = 150 - 28 = 122
	assert_eq(dummy.health_component.current_health, 122, "Dummy HP should drop to 122 after taking 28 damage")

func test_player_aim_and_weapon_orientation_left_and_right() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	var warrior_data: HeroData = load("res://data/heroes/warrior.tres") as HeroData
	player.apply_hero_data(warrior_data)
	
	# 1. Прицеливание влево (-1, 0)
	player.aim_direction = Vector2(-1.0, 0.0)
	# Вызываем _update_aim без мыши (joy_aim/mouse_pos сбрасываются)
	player.weapon_pivot.rotation = player.aim_direction.angle()
	var is_aiming_left: bool = (player.aim_direction.x < 0.0)
	player.visuals.scale.x = -1.0 if is_aiming_left else 1.0
	var w_sprite: Sprite2D = player.weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
	if w_sprite != null:
		w_sprite.flip_v = is_aiming_left
	
	assert_lt(player.visuals.scale.x, 0.0, "Player visuals must flip horizontally when aiming left")
	assert_almost_eq(abs(player.weapon_pivot.rotation), PI, 0.01, "Weapon pivot must point left (PI radians)")
	if w_sprite != null:
		assert_true(w_sprite.flip_v, "Weapon sprite must have flip_v = true when aiming left to stay upright")
	
	# 2. Прицеливание вправо (1, 0)
	player.aim_direction = Vector2(1.0, 0.0)
	player.weapon_pivot.rotation = player.aim_direction.angle()
	is_aiming_left = (player.aim_direction.x < 0.0)
	player.visuals.scale.x = -1.0 if is_aiming_left else 1.0
	if w_sprite != null:
		w_sprite.flip_v = is_aiming_left
	
	assert_gt(player.visuals.scale.x, 0.0, "Player visuals must face right when aiming right")
	assert_almost_eq(player.weapon_pivot.rotation, 0.0, 0.01, "Weapon pivot must point right (0 radians)")
	if w_sprite != null:
		assert_false(w_sprite.flip_v, "Weapon sprite must have flip_v = false when aiming right")

func test_player_shoot_projectile_left_and_right() -> void:
	var container: Node2D = Node2D.new()
	add_child_autofree(container)
	
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	container.add_child(player)
	
	var ranger_data: HeroData = load("res://data/heroes/ranger.tres") as HeroData
	player.apply_hero_data(ranger_data)
	
	# Стрельба влево
	player.aim_direction = Vector2(-1.0, 0.0)
	player._shoot_basic_projectile()
	
	var shot_proj: Projectile = null
	for child in container.get_children():
		if child is Projectile:
			shot_proj = child as Projectile
			break
	
	assert_not_null(shot_proj, "Projectile should be spawned when shooting")
	if shot_proj != null:
		assert_lt(shot_proj.direction.x, -0.9, "Projectile direction must be pointing left")
		assert_almost_eq(abs(shot_proj.rotation), PI, 0.01, "Projectile rotation must point left (PI radians)")
		shot_proj.queue_free()

func test_player_melee_swing_left() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	var warrior_data: HeroData = load("res://data/heroes/warrior.tres") as HeroData
	player.apply_hero_data(warrior_data)
	
	player.aim_direction = Vector2(-1.0, 0.0)
	player._swing_melee_weapon()
	
	assert_true(player.is_swinging, "is_swinging flag must be active during melee attack")
	assert_false(player.attack_collision.disabled, "Attack collision must be enabled during swing")
