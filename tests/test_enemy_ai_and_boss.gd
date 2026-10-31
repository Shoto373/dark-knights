extends GutTest

func test_load_all_enemy_and_boss_resources() -> void:
	var slasher: EnemyData = load("res://data/enemies/goblin_slasher.tres") as EnemyData
	var archer: EnemyData = load("res://data/enemies/goblin_archer.tres") as EnemyData
	var shaman: EnemyData = load("res://data/enemies/goblin_shaman.tres") as EnemyData
	var brute: EnemyData = load("res://data/enemies/goblin_brute.tres") as EnemyData
	var boss: BossData = load("res://data/enemies/boss_goblin_chieftain.tres") as BossData
	
	assert_not_null(slasher, "Slasher data must load")
	assert_not_null(archer, "Archer data must load")
	assert_not_null(shaman, "Shaman data must load")
	assert_not_null(brute, "Brute data must load")
	assert_not_null(boss, "Boss data must load")
	
	assert_eq(slasher.enemy_type, "melee")
	assert_eq(archer.enemy_type, "ranged")
	assert_eq(shaman.enemy_type, "support")
	assert_eq(brute.enemy_type, "heavy")
	assert_eq(boss.max_hp, 350)
	assert_eq(boss.armor, 2)

func test_state_machine_transitions() -> void:
	var enemy_scene: PackedScene = load("res://entities/enemies/EnemyBase.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	add_child_autofree(enemy)
	
	assert_eq(enemy.state_machine.current_state_name, "idle", "Initial state must be idle")
	
	watch_signals(enemy.state_machine)
	enemy.state_machine.change_state("chase")
	assert_eq(enemy.state_machine.current_state_name, "chase", "State should transition to chase")
	assert_signal_emitted_with_parameters(enemy.state_machine, "state_changed", ["idle", "chase"])
	
	enemy.state_machine.change_state("attack")
	assert_eq(enemy.state_machine.current_state_name, "attack", "State should transition to attack")

func test_shaman_heals_wounded_ally() -> void:
	var enemy_scene: PackedScene = load("res://entities/enemies/EnemyBase.tscn")
	var shaman_data: EnemyData = load("res://data/enemies/goblin_shaman.tres") as EnemyData
	var slasher_data: EnemyData = load("res://data/enemies/goblin_slasher.tres") as EnemyData
	
	var shaman: EnemyBase = enemy_scene.instantiate() as EnemyBase
	add_child_autofree(shaman)
	shaman.setup_from_data(shaman_data)
	
	var slasher: EnemyBase = enemy_scene.instantiate() as EnemyBase
	add_child_autofree(slasher)
	slasher.setup_from_data(slasher_data)
	
	slasher.health_component.take_damage(30)
	assert_eq(slasher.health_component.current_health, 15, "Slasher is wounded to 15 HP")
	
	var ally: EnemyBase = shaman._find_wounded_ally()
	assert_not_null(ally, "Shaman should find wounded ally")
	assert_eq(ally, slasher, "Wounded ally is slasher")
	
	shaman._try_heal_or_attack()
	assert_eq(slasher.health_component.current_health, 35, "Slasher should be healed by 20 to 35 HP")

func test_boss_phase_2_transition_at_50_percent_hp() -> void:
	var boss_scene: PackedScene = load("res://entities/bosses/GoblinBoss.tscn")
	var boss: GoblinBoss = boss_scene.instantiate() as GoblinBoss
	add_child_autofree(boss)
	
	assert_eq(boss.current_phase, 1, "Boss starts in phase 1")
	var initial_speed: float = boss.movement_component.max_speed
	var initial_damage: int = boss.attack_hitbox.base_damage
	
	watch_signals(boss)
	boss.health_component.take_damage(180)
	
	assert_eq(boss.current_phase, 2, "Boss must enter phase 2")
	assert_signal_emitted_with_parameters(boss, "phase_changed", [2])
	assert_gt(boss.movement_component.max_speed, initial_speed, "Phase 2 speed must increase")
	assert_gt(boss.attack_hitbox.base_damage, initial_damage, "Phase 2 damage must increase")

func test_wave_spawner_budget_and_entities() -> void:
	var spawner: WaveSpawner = WaveSpawner.new()
	var room_scene: PackedScene = load("res://levels/Room.tscn")
	var room: DungeonRoom = room_scene.instantiate() as DungeonRoom
	add_child_autofree(room)
	
	var combat_data: RoomData = RoomData.new()
	combat_data.room_type = RoomData.RoomType.COMBAT
	combat_data.distance_from_start = 3
	
	var enemies: Array[Node2D] = spawner.spawn_room_enemies(room, combat_data)
	assert_gte(enemies.size(), 2, "Combat room should spawn at least 2 enemies")
	for e in enemies:
		assert_true(e is EnemyBase, "Spawned entity must be EnemyBase")
		assert_true(e.is_in_group("enemies"), "Enemy must be in 'enemies' group")
		e.free()
	
	var boss_data: RoomData = RoomData.new()
	boss_data.room_type = RoomData.RoomType.BOSS
	var boss_spawned: Array[Node2D] = spawner.spawn_room_enemies(room, boss_data)
	assert_eq(boss_spawned.size(), 1, "Boss room must spawn 1 boss")
	assert_true(boss_spawned[0] is GoblinBoss, "Boss must be GoblinBoss")
	boss_spawned[0].free()
