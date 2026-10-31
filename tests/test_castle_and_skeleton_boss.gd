class_name TestCastleAndSkeletonBoss
extends GutTest

## Тесты для Спринта 7: Замок Рыцаря-скелета, ловушки, секретный рычаг, скелеты и босс

const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const SKELETON_BOSS_SCENE = preload("res://entities/bosses/SkeletonKnightBoss.tscn")
const FIRE_GRATE_SCENE = preload("res://levels/hazards/FireGrateTrap.tscn")
const CHANDELIER_SCENE = preload("res://levels/hazards/FallingChandelierTrap.tscn")
const SECRET_LEVER_SCENE = preload("res://levels/hazards/SecretLever.tscn")
const BRANCH_DIALOG_SCENE = preload("res://ui/BranchChoiceDialog.tscn")
const PLAYER_SCENE = preload("res://entities/player/Player.tscn")

func before_each() -> void:
	GameState.start_new_run("warrior", 7777)

func after_each() -> void:
	GameState.end_run(false)

func test_skeleton_swordsman_reassembly_and_permanent_death() -> void:
	var enemy: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
	add_child_autofree(enemy)
	
	var skel_data: EnemyData = load("res://data/enemies/skeleton_swordsman.tres") as EnemyData
	assert_not_null(skel_data)
	assert_true(skel_data.can_reassemble, "Skeleton swordsman must have can_reassemble = true")
	
	enemy.setup_from_data(skel_data)
	assert_eq(enemy.health_component.current_health, 45)
	
	# 1. Первый смертельный урон: скелет рассыпается в кучу костей
	enemy.health_component.take_damage(50)
	assert_true(enemy.is_collapsed, "Skeleton must collapse into bone pile on first lethal damage")
	assert_true(enemy.has_reassembled, "Flag has_reassembled must be marked")
	assert_eq(enemy.health_component.current_health, skel_data.bone_pile_hp, "Bone pile must have specified bone_pile_hp")
	
	# 2. Не трогаем кости 4.1 секунды: скелет собирается обратно!
	enemy._physics_process(4.1)
	assert_false(enemy.is_collapsed, "Skeleton must reassemble after timer expires")
	assert_gt(enemy.health_component.current_health, 20, "Skeleton must revive with partial HP")
	
	# 3. Второй смертельный урон: куча костей разбита или скелет убит второй раз -> перманентная гибель
	enemy.health_component.take_damage(100)
	assert_true(enemy.is_queued_for_deletion() or enemy.health_component.is_dead, "Second death must be permanent")

func test_knight_guard_front_shield_blocks_damage_and_back_vulnerable() -> void:
	var enemy: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
	add_child_autofree(enemy)
	
	var guard_data: EnemyData = load("res://data/enemies/knight_guard.tres") as EnemyData
	assert_not_null(guard_data)
	assert_true(guard_data.has_front_shield, "Knight guard must have front shield")
	
	enemy.setup_from_data(guard_data)
	enemy.global_position = Vector2(200, 200)
	
	# Создаем игрока справа от рыцаря-стража (рыцарь смотрит направо)
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector2(300, 200)
	enemy.player_target = player
	
	var hp_before: int = enemy.health_component.current_health
	
	# Удар спереди (откуда смотрит щит)
	var front_hitbox: HitboxComponent = HitboxComponent.new()
	add_child_autofree(front_hitbox)
	front_hitbox.global_position = Vector2(280, 200) # спереди
	
	enemy.health_component.take_damage(30)
	enemy._on_hit_received(30, false, front_hitbox)
	assert_eq(enemy.health_component.current_health, hp_before, "Frontal attack must be blocked by shield")
	
	# Удар со спины (слева)
	var back_hitbox: HitboxComponent = HitboxComponent.new()
	add_child_autofree(back_hitbox)
	back_hitbox.global_position = Vector2(50, 200) # со спины
	
	enemy.health_component.take_damage(30)
	enemy._on_hit_received(30, false, back_hitbox)
	# Со спины урон НЕ поглощается щитом
	assert_lt(enemy.health_component.current_health, hp_before, "Attack from behind must deal damage")

func test_fire_grate_trap_cycles_and_deals_fire_damage() -> void:
	var trap: FireGrateTrap = FIRE_GRATE_SCENE.instantiate() as FireGrateTrap
	add_child_autofree(trap)
	
	assert_eq(trap.current_state, FireGrateTrap.TrapState.OFF)
	assert_true(trap.collision_shape.disabled, "Collision shape must be disabled when trap is OFF")
	assert_eq(trap.hitbox.damage_type, "fire", "Grate trap must deal fire damage")
	assert_true(trap.hitbox.tags.has("fire"), "Grate trap must have fire tag")
	
	# Переход в WARNING
	trap._physics_process(trap.cycle_off_time + 0.1)
	assert_eq(trap.current_state, FireGrateTrap.TrapState.WARNING)
	assert_true(trap.warning_glow.visible)
	
	# Переход в BURST (выброс огня)
	trap._physics_process(trap.cycle_warning_time + 0.1)
	assert_eq(trap.current_state, FireGrateTrap.TrapState.BURST)
	assert_true(trap.flames_visual.visible)
	assert_false(trap.collision_shape.disabled, "Collision shape must be active during BURST")

func test_falling_chandelier_trap_drops_and_impacts() -> void:
	var chandelier: FallingChandelierTrap = CHANDELIER_SCENE.instantiate() as FallingChandelierTrap
	add_child_autofree(chandelier)
	
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.global_position = chandelier.global_position
	
	assert_false(chandelier.is_triggered)
	assert_false(chandelier.has_fallen)
	
	# Игрок активирует зону падения
	chandelier._on_trigger_body_entered(player)
	assert_true(chandelier.is_triggered, "Trap must trigger when player enters radius")
	
	# Завершаем падение
	chandelier._drop_chandelier()
	chandelier._on_impact()
	assert_true(chandelier.has_fallen, "Chandelier must have fallen")

func test_secret_lever_reveals_treasure() -> void:
	var lever: SecretLever = SECRET_LEVER_SCENE.instantiate() as SecretLever
	add_child_autofree(lever)
	
	assert_false(lever.is_activated)
	watch_signals(lever)
	
	lever.activate_lever()
	assert_true(lever.is_activated, "Lever must be marked activated")
	assert_signal_emitted(lever, "lever_activated")

func test_skeleton_knight_boss_3_phases_and_telegraphs() -> void:
	var boss: SkeletonKnightBoss = SKELETON_BOSS_SCENE.instantiate() as SkeletonKnightBoss
	add_child_autofree(boss)
	
	assert_eq(boss.current_phase, 1, "Boss must start in phase 1 (sword duel)")
	assert_eq(boss.health_component.max_health, 600)
	assert_true(boss.shield_rect.visible, "Shield must be active in phase 1")
	
	watch_signals(boss)
	
	# Наносим урон до перехода во 2 фазу (HP <= 66% -> 390 HP)
	boss.health_component.take_damage(210) # 390 HP
	assert_eq(boss.current_phase, 2, "Boss must transition to phase 2 at <= 66% HP")
	assert_signal_emitted(boss, "phase_changed")
	
	# Наносим урон до перехода в 3 фазу (HP <= 33% -> 190 HP)
	boss.health_component.take_damage(210) # 180 HP
	assert_eq(boss.current_phase, 3, "Boss must transition to phase 3 (enrage) at <= 33% HP")
	assert_false(boss.shield_rect.visible, "Shield must be discarded in phase 3 enrage")

func test_branch_choice_dialog_saves_branch_to_game_state() -> void:
	var dialog: BranchChoiceDialog = BRANCH_DIALOG_SCENE.instantiate() as BranchChoiceDialog
	add_child_autofree(dialog)
	
	# Выбираем ветку холода
	dialog._choose_branch("frost_world")
	
	assert_eq(GameState.current_world_node_id, "frost_world", "Branch choice must save chosen node to GameState")
	assert_true(GameState.visited_world_nodes.has("frost_world"), "Visited world nodes must record the chosen branch")
	assert_eq(GameState.get_current_biome().id, "frost_world")

func test_full_world_progression_1_to_3_biomes() -> void:
	# 1. Биом 1: Темница гоблинов
	assert_eq(GameState.current_world_node_id, "goblin_dungeon")
	assert_eq(GameState.current_floor_index, 1)
	
	# 2. Переход в Биом 2: Ущелье троллей
	var troll_node: WorldNodeData = GameState.world_graph.get_node("troll_gorge")
	GameState.advance_to_world_node(troll_node)
	assert_eq(GameState.current_world_node_id, "troll_gorge")
	assert_eq(GameState.current_floor_index, 2)
	
	# 3. Переход в Биом 3: Замок Рыцаря-скелета
	var skeleton_node: WorldNodeData = GameState.world_graph.get_node("skeleton_castle")
	GameState.advance_to_world_node(skeleton_node)
	assert_eq(GameState.current_world_node_id, "skeleton_castle")
	assert_eq(GameState.current_floor_index, 3)
	assert_eq(GameState.get_current_biome().id, "skeleton_castle")
	
	# 4. Развилка в Биоме 3: проверяем наличие обоих путей
	var next_branches: Array[WorldNodeData] = skeleton_node.next_nodes
	assert_eq(next_branches.size(), 2, "Castle must branch into 2 paths")
	var branch_ids: Array[String] = [next_branches[0].id, next_branches[1].id]
	assert_true(branch_ids.has("frost_world") and branch_ids.has("fire_world"))
