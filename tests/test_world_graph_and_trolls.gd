class_name TestWorldGraphAndTrolls
extends GutTest

## Тесты для Спринта 6: Граф мира, Ущелье троллей, тролли и босс Король троллей

const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const TROLL_KING_SCENE = preload("res://entities/bosses/TrollKingBoss.tscn")
const PLAYER_SCENE = preload("res://entities/player/Player.tscn")
const CHASM_SCENE = preload("res://levels/hazards/ChasmHazard.tscn")
const BRIDGE_SCENE = preload("res://levels/hazards/BridgeArea.tscn")

func before_each() -> void:
	GameState.start_new_run("warrior", 4242)

func after_each() -> void:
	GameState.end_run(false)

func test_world_graph_loading_and_connectivity() -> void:
	var graph: WorldGraph = WorldGraph.new()
	var nodes: Dictionary = graph.get_all_nodes()
	
	assert_true(nodes.has("hub"), "Hub node must exist in world graph")
	assert_true(nodes.has("goblin_dungeon"), "Goblin Dungeon must exist in world graph")
	assert_true(nodes.has("troll_gorge"), "Troll Gorge must exist in world graph")
	assert_true(nodes.has("skeleton_castle"), "Skeleton Castle must exist in world graph")
	assert_true(nodes.has("frost_world"), "Frost World must exist in world graph")
	assert_true(nodes.has("fire_world"), "Fire World must exist in world graph")
	assert_true(nodes.has("frost_caves"), "Frost Caves side branch must exist in world graph")
	assert_true(nodes.has("fire_mines"), "Fire Mines side branch must exist in world graph")
	assert_true(nodes.has("purgatory"), "Purgatory must exist in world graph")
	
	# Проверка связей графа
	var hub_node: WorldNodeData = graph.get_node("hub")
	assert_eq(hub_node.next_nodes.size(), 1, "Hub should point to goblin dungeon")
	assert_eq(hub_node.next_nodes[0].id, "goblin_dungeon")
	
	var goblin_node: WorldNodeData = graph.get_node("goblin_dungeon")
	assert_eq(goblin_node.next_nodes.size(), 1, "Goblin dungeon should point to troll gorge")
	assert_eq(goblin_node.next_nodes[0].id, "troll_gorge")
	
	var troll_node: WorldNodeData = graph.get_node("troll_gorge")
	assert_eq(troll_node.next_nodes.size(), 1, "Troll gorge should point to skeleton castle")
	assert_eq(troll_node.next_nodes[0].id, "skeleton_castle")
	
	# Развилка в Замке скелета
	var skeleton_node: WorldNodeData = graph.get_node("skeleton_castle")
	assert_eq(skeleton_node.next_nodes.size(), 2, "Skeleton castle must have 2 branching next nodes")
	var fork_ids: Array[String] = [skeleton_node.next_nodes[0].id, skeleton_node.next_nodes[1].id]
	assert_true(fork_ids.has("frost_world") and fork_ids.has("fire_world"), "Fork must branch into frost and fire worlds")
	
	# Чистилище — финальный рубеж
	var purgatory_node: WorldNodeData = graph.get_node("purgatory")
	assert_true(purgatory_node.is_final, "Purgatory must be final node")
	assert_eq(purgatory_node.next_nodes.size(), 0, "Purgatory has no next nodes")
	
	# Проверка проходимости всего графа
	assert_true(graph.can_reach("hub", "purgatory"), "Path from hub to purgatory must be fully connected")
	assert_true(graph.can_reach("goblin_dungeon", "troll_gorge"), "Goblin dungeon must reach troll gorge")
	assert_true(graph.can_reach("troll_gorge", "purgatory"), "Troll gorge must reach purgatory")

func test_extensibility_add_custom_node_without_code_changes() -> void:
	var graph: WorldGraph = WorldGraph.new()
	
	# Создаем динамический узел через Resource без изменения GDScript кода
	var custom_node: WorldNodeData = WorldNodeData.new()
	custom_node.id = "secret_mines"
	custom_node.name = "Тайные копи"
	custom_node.floors_count = 2
	custom_node.map_position = Vector2(500, 200)
	
	graph.add_node(custom_node)
	
	assert_not_null(graph.get_node("secret_mines"), "Dynamically added node must be accessible via graph")
	assert_eq(graph.get_node("secret_mines").name, "Тайные копи")
	
	# Подключаем узел к троллям
	var troll_node: WorldNodeData = graph.get_node("troll_gorge")
	troll_node.next_nodes.append(custom_node)
	
	assert_true(graph.can_reach("troll_gorge", "secret_mines"), "Custom node must be reachable from troll gorge")

func test_game_state_world_progression_goblin_to_troll() -> void:
	assert_eq(GameState.current_world_node_id, "goblin_dungeon")
	assert_eq(GameState.current_floor_index, 1)
	assert_eq(GameState.get_current_biome().id, "goblin_dungeon")
	
	var troll_node: WorldNodeData = GameState.world_graph.get_node("troll_gorge")
	assert_not_null(troll_node)
	
	# Переход в биом 2 по графу
	GameState.advance_to_world_node(troll_node)
	
	assert_eq(GameState.current_world_node_id, "troll_gorge")
	assert_eq(GameState.current_floor_index, 2)
	assert_true(GameState.visited_world_nodes.has("goblin_dungeon"))
	assert_true(GameState.visited_world_nodes.has("troll_gorge"))
	assert_eq(GameState.get_current_biome().id, "troll_gorge")

func test_troll_regenerator_healing_after_3_seconds() -> void:
	var enemy: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
	add_child_autofree(enemy)
	
	var regen_data: EnemyData = load("res://data/enemies/troll_regenerator.tres") as EnemyData
	assert_not_null(regen_data)
	assert_true(regen_data.can_regenerate)
	assert_eq(regen_data.regen_delay_seconds, 3.0)
	
	enemy.setup_from_data(regen_data)
	assert_eq(enemy.health_component.current_health, 85)
	
	# Наносим урон
	enemy.health_component.take_damage(35)
	assert_eq(enemy.health_component.current_health, 50)
	enemy.time_since_damage = 0.0 # сброс таймера урона
	
	# Симулируем 1.5 секунды (меньше 3.0 секунд задержки регенерации)
	enemy._physics_process(1.5)
	assert_eq(enemy.health_component.current_health, 50, "Troll should not regenerate before 3 seconds without damage")
	
	# Симулируем преодоление порога 3.0 секунд и тик регенерации (1.0с)
	enemy._physics_process(2.0) # time_since_damage = 3.5, первый тик регенерации (+6 -> 56)
	enemy._physics_process(1.0) # второй тик регенерации (+6 -> 62)
	
	assert_gt(enemy.health_component.current_health, 50, "Troll must heal after 3+ seconds without taking damage")
	assert_eq(enemy.health_component.current_health, 62)

func test_troll_regenerator_fire_damage_cancels_regeneration() -> void:
	var enemy: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
	add_child_autofree(enemy)
	
	var regen_data: EnemyData = load("res://data/enemies/troll_regenerator.tres") as EnemyData
	enemy.setup_from_data(regen_data)
	enemy.health_component.take_damage(30)
	assert_eq(enemy.health_component.current_health, 55)
	
	# Создаем атаку с тегом "fire"
	var fire_hitbox: HitboxComponent = HitboxComponent.new()
	add_child_autofree(fire_hitbox)
	fire_hitbox.damage_type = "fire"
	fire_hitbox.tags = ["fire"]
	
	# Передаем урон от огня
	enemy._on_hit_received(10, false, fire_hitbox)
	assert_true(enemy.is_burning, "Enemy must catch fire")
	assert_gt(enemy.burn_timer, 0.0)
	
	# Симулируем 3.5 секунды: пока горит, регенерация ЗАБЛОКИРОВАНА
	enemy._physics_process(3.5)
	assert_eq(enemy.health_component.current_health, 55, "Regeneration must be blocked while burning")

func test_troll_king_boss_mechanics_and_fire_extinguishes_regen() -> void:
	var boss: TrollKingBoss = TROLL_KING_SCENE.instantiate() as TrollKingBoss
	add_child_autofree(boss)
	
	assert_eq(boss.health_component.max_health, 500)
	assert_eq(boss.health_component.current_health, 500)
	
	# Наносим урон
	boss.health_component.take_damage(60)
	assert_eq(boss.health_component.current_health, 440)
	boss.time_since_damage = 2.0
	
	# Тик регенерации (1.5с) без огня
	boss._physics_process(1.6)
	assert_eq(boss.health_component.current_health, 450, "Troll King should passively regenerate health")
	
	# Атакуем огнем
	watch_signals(boss)
	var fire_hitbox: HitboxComponent = HitboxComponent.new()
	add_child_autofree(fire_hitbox)
	fire_hitbox.damage_type = "fire"
	fire_hitbox.tags = ["fire"]
	
	boss._on_hit_received(15, false, fire_hitbox)
	assert_true(boss.is_burning, "Troll King must ignite on fire damage")
	assert_signal_emitted(boss, "regeneration_interrupted")
	
	# В процессе горения регенерация не срабатывает
	boss.health_component.take_damage(20) # HP = 430
	boss.time_since_damage = 2.0
	boss._physics_process(1.6)
	assert_eq(boss.health_component.current_health, 430, "Fire must extinguish Troll King's regeneration")

func test_chasm_hazard_falling_damage_and_bridge_safety() -> void:
	var chasm: ChasmHazard = CHASM_SCENE.instantiate() as ChasmHazard
	add_child_autofree(chasm)
	chasm.position = Vector2(300, 300)
	chasm.pit_size = Vector2(100, 100)
	chasm.safe_respawn_position = Vector2(100, 100)
	
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector2(300, 300)
	
	var initial_hp: int = player.health_component.current_health
	
	# 1. Игрок падает в пропасть без моста и без рывка
	chasm._check_player_fall(player)
	assert_lt(player.health_component.current_health, initial_hp, "Player must take fall damage when falling into chasm")
	assert_eq(player.global_position, Vector2(100, 100), "Player must respawn at safe position")
	
	# 2. Игрок на мосту в безопасности
	var current_hp: int = player.health_component.current_health
	player.add_to_group("on_bridge")
	chasm.falling_players.clear()
	chasm._check_player_fall(player)
	assert_eq(player.health_component.current_health, current_hp, "Player on bridge must NOT fall into chasm")
	player.remove_from_group("on_bridge")
	
	# 3. Игрок в рывке (dash) перелетает пропасть
	player.is_dashing = true
	chasm._check_player_fall(player)
	assert_eq(player.health_component.current_health, current_hp, "Player dashing must NOT fall into chasm")
