extends GutTest

## GUT-тесты для Спринта 10:
## Финальный биом «Чистилище», гравитационные разломы (VoidRiftTrap),
## 4 элитных врага, 3 фазы Владыки Чистилища, луч пустоты, VictoryScreen и мета-прогресс.

const PLAYER_SCENE = preload("res://entities/player/Player.tscn")
const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const VOID_RIFT_SCENE = preload("res://levels/hazards/VoidRiftTrap.tscn")
const PURG_BOSS_SCENE = preload("res://entities/bosses/PurgatoryLordBoss.tscn")
const VICTORY_SCREEN_SCENE = preload("res://ui/VictoryScreen.tscn")

var player: Player

func before_each() -> void:
	GameState.start_new_run("warrior", 7777)
	GameState.current_world_node_id = "purgatory"
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector2(200, 200)

func after_each() -> void:
	GameState.end_run(false)

func test_void_rift_trap_gravitational_pull_and_damage() -> void:
	var rift: VoidRiftTrap = VOID_RIFT_SCENE.instantiate() as VoidRiftTrap
	add_child_autofree(rift)
	rift.global_position = Vector2(300, 200)
	
	# Игрок входит в зону гравитационного притяжения
	rift._on_body_entered(player)
	assert_true(rift.bodies_in_range.has(player), "Игрок обнаружен в зоне притяжения разлома")
	
	# Прокручиваем физику притяжения
	player.velocity = Vector2.ZERO
	rift._physics_process(0.1)
	assert_gt(player.velocity.x, 0.0, "Гравитация разлома притягивает игрока по горизонтали к центру")
	
	# Проверка периодического урона в эпицентре
	player.global_position = Vector2(310, 200) # На расстоянии 10 пикселей от центра
	var initial_hp: int = player.health_component.current_health
	rift._tick_core_damage()
	assert_eq(player.health_component.current_health, initial_hp - rift.core_damage, "Разлом нанес урон в ядре")

func test_purgatory_enemies_data() -> void:
	var chimera: EnemyData = load("res://data/enemies/shadow_chimera.tres") as EnemyData
	var archon: EnemyData = load("res://data/enemies/fallen_archon.tres") as EnemyData
	var specter: EnemyData = load("res://data/enemies/void_specter.tres") as EnemyData
	var exec: EnemyData = load("res://data/enemies/purgatory_executioner.tres") as EnemyData
	
	assert_not_null(chimera, "shadow_chimera.tres существует")
	assert_not_null(archon, "fallen_archon.tres существует")
	assert_not_null(specter, "void_specter.tres существует")
	assert_not_null(exec, "purgatory_executioner.tres существует")
	
	assert_true(chimera.immunities.has("poison"), "Химера теней иммунна к яду")
	assert_true(archon.immunities.has("stun"), "Падший архонт иммунен к оглушению")
	assert_true(specter.immunities.has("freeze"), "Спектр пустоты иммунен к заморозке")
	assert_true(exec.immunities.has("stun"), "Палач иммунен к оглушению")
	assert_eq(exec.armor, 4, "Палач обладает тяжелой броней 4")

func test_purgatory_lord_boss_3_phases_and_spinning_beam() -> void:
	var boss: PurgatoryLordBoss = PURG_BOSS_SCENE.instantiate() as PurgatoryLordBoss
	add_child_autofree(boss)
	boss.global_position = Vector2(640, 360)
	
	assert_eq(boss.current_phase, 1, "Начальная фаза Владыки Чистилища — 1")
	assert_eq(boss.health_component.max_health, 900, "Здоровье босса равно 900")
	assert_false(boss.is_beam_active, "Луч пустоты не активен в начале")
	
	# Нанесение урона ниже 60% HP (порог 540 HP): переход в Фазу 2
	boss.health_component.take_damage(380) # 900 - 380 = 520
	assert_eq(boss.current_phase, 2, "При падении ниже 60% HP босс переходит во 2 фазу")
	
	# Нанесение урона ниже 30% HP (порог 270 HP): переход в Фазу 3 (Ascension)
	boss.health_component.take_damage(270) # 520 - 270 = 250
	assert_eq(boss.current_phase, 3, "При падении ниже 30% HP босс переходит в Фазу 3 (Истинный облик)")
	assert_true(boss.wings_node.visible, "В 3 фазе раскрываются крылья пустоты")
	assert_true(boss.is_beam_active, "В 3 фазе активирован вращающийся луч пустоты")
	assert_false(boss.beam_shape.disabled, "Хитбокс луча пустоты включен")
	
	# Вращение луча в физическом процессе
	var prev_beam_rot: float = boss.beam_pivot.rotation
	boss._physics_process(0.1)
	assert_gt(boss.beam_pivot.rotation, prev_beam_rot, "Луч пустоты непрерывно вращается вокруг босса")
	
	# Финальное добивание босса
	watch_signals(boss)
	boss.health_component.take_damage(260)
	assert_signal_emitted(boss, "boss_defeated", "Владыка Чистилища повержен")
	
	for child in get_tree().root.get_children():
		if child is VictoryScreen:
			child.queue_free()

func test_victory_screen_meta_progress_and_rewards() -> void:
	GameState.gold = 150
	var prev_victories: int = MetaProgress.lifetime_stats.get("victories", 0)
	var prev_souls: int = MetaProgress.souls
	
	var victory: VictoryScreen = VICTORY_SCREEN_SCENE.instantiate() as VictoryScreen
	add_child_autofree(victory)
	
	# Бонус: 50 + 150/5 = 80 душ
	assert_eq(victory.run_souls_awarded, 80, "Корректный расчет душ за победу")
	assert_eq(MetaProgress.souls, prev_souls + 80, "Души за победу начислены в MetaProgress")
	assert_eq(MetaProgress.lifetime_stats["victories"], prev_victories + 1, "Счетчик побед увеличен на 1")
	assert_false(GameState.is_run_active, "Забег успешно завершен с победой")

func test_purgatory_biome_data_and_final_node_in_world_graph() -> void:
	var purg_biome: BiomeData = load("res://data/biomes/purgatory.tres") as BiomeData
	assert_not_null(purg_biome, "purgatory.tres существует")
	assert_eq(purg_biome.enemy_pool.size(), 4, "В пуле врагов Чистилища 4 типа врагов")
	assert_not_null(purg_biome.elite_enemy, "Элитный враг назначен")
	assert_not_null(purg_biome.boss_data, "Данные финального босса назначены")
	assert_eq(purg_biome.boss_scene_path, "res://entities/bosses/PurgatoryLordBoss.tscn", "Сцена финального босса указана корректно")
	
	var graph: WorldGraph = WorldGraph.new()
	var final_node: WorldNodeData = graph.get_node("purgatory")
	assert_not_null(final_node, "Узел purgatory найден в графе мира")
	assert_true(final_node.is_final, "Чистилище является финальной вершиной графа мира")
	assert_true(final_node.next_nodes.is_empty(), "У финальной вершины нет последующих узлов")
