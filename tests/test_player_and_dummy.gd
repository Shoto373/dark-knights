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
