extends GutTest

## GUT-тесты для Спринта 9:
## Мир огня, лава (LavaHazard), лавовые гейзеры (LavaGeyserTrap),
## 4 огненных врага, 5 предметов огня и синергии, 3 фазы Дракона и граф мира.

const PLAYER_SCENE = preload("res://entities/player/Player.tscn")
const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const LAVA_HAZARD_SCENE = preload("res://levels/hazards/LavaHazard.tscn")
const LAVA_GEYSER_SCENE = preload("res://levels/hazards/LavaGeyserTrap.tscn")
const DRAGON_BOSS_SCENE = preload("res://entities/bosses/DragonBoss.tscn")

var player: Player

func before_each() -> void:
	GameState.start_new_run("warrior", 9999)
	GameState.current_world_node_id = "fire_world"
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector2(200, 200)

func after_each() -> void:
	GameState.end_run(false)

func test_lava_hazard_deals_damage_and_burns() -> void:
	var lava: LavaHazard = LAVA_HAZARD_SCENE.instantiate() as LavaHazard
	add_child_autofree(lava)
	lava.global_position = Vector2(200, 200)
	
	var initial_hp: int = player.health_component.current_health
	
	# Игрок наступает на лаву
	lava._on_body_entered(player)
	
	# Нанесение урона от лавы (6 урона) и наложение статуса горения
	assert_eq(player.health_component.current_health, initial_hp - 6, "Лава нанесла первоначальный урон 6 ед.")
	assert_true(player.status_effect_manager.has_effect("burn"), "Лава наложила эффект горения")
	
	# Прокручиваем тик урона лавы
	lava._tick_damage()
	assert_eq(player.health_component.current_health, initial_hp - 12, "Лава нанесла второй тик урона")

func test_magma_boots_protect_from_lava_and_burning() -> void:
	var boots: ItemData = load("res://data/items/magma_boots.tres") as ItemData
	assert_not_null(boots, "magma_boots.tres должен существовать")
	
	GameState.inventory_items.append({"item_ref": boots})
	player.recalculate_stats()
	
	assert_true(player.status_effect_manager.immunities.has("burn"), "Сапоги магмы дают иммунитет к горению")
	
	var lava: LavaHazard = LAVA_HAZARD_SCENE.instantiate() as LavaHazard
	add_child_autofree(lava)
	lava.global_position = Vector2(200, 200)
	
	var initial_hp: int = player.health_component.current_health
	
	# Игрок в магматических сапогах наступает на лаву
	lava._on_body_entered(player)
	lava._tick_damage()
	
	assert_eq(player.health_component.current_health, initial_hp, "Игрок в сапогах магмы не получает урона от лавы")
	assert_false(player.status_effect_manager.has_effect("burn"), "Игрок в сапогах магмы не загорается")

func test_lava_geyser_trap_cycling_and_erupt_damage() -> void:
	var geyser: LavaGeyserTrap = LAVA_GEYSER_SCENE.instantiate() as LavaGeyserTrap
	add_child_autofree(geyser)
	geyser.global_position = Vector2(300, 300)
	
	assert_eq(geyser.current_state, LavaGeyserTrap.GeyserState.DORMANT, "Гейзер стартует в состоянии DORMANT")
	assert_true(geyser.collision_shape.disabled, "Хитбокс выключен во время спячки")
	
	# Переход в режим бурления (BUBBLING)
	geyser._set_state(LavaGeyserTrap.GeyserState.BUBBLING)
	assert_true(geyser.bubble_visual.visible, "Индикатор бурления активен")
	assert_true(geyser.collision_shape.disabled, "Хитбокс все еще выключен во время предупреждения")
	
	# Переход в извержение (ERUPTING)
	geyser._set_state(LavaGeyserTrap.GeyserState.ERUPTING)
	assert_true(geyser.eruption_visual.visible, "Индикатор извержения активен")
	assert_false(geyser.collision_shape.disabled, "Хитбокс активен во время извержения")
	assert_eq(geyser.hitbox.damage_type, "fire", "Гейзер наносит огненный урон")

func test_fire_enemies_data_and_lava_slime_death_puddle() -> void:
	var slime_data: EnemyData = load("res://data/enemies/lava_slime.tres") as EnemyData
	var elem_data: EnemyData = load("res://data/enemies/fire_elemental.tres") as EnemyData
	var cult_data: EnemyData = load("res://data/enemies/flame_cultist.tres") as EnemyData
	var worm_data: EnemyData = load("res://data/enemies/magma_worm.tres") as EnemyData
	
	assert_not_null(slime_data, "lava_slime.tres загружен")
	assert_not_null(elem_data, "fire_elemental.tres загружен")
	assert_not_null(cult_data, "flame_cultist.tres загружен")
	assert_not_null(worm_data, "magma_worm.tres загружен")
	
	assert_true(slime_data.immunities.has("burn"), "Слизень иммунен к горению")
	assert_true(elem_data.immunities.has("burn"), "Элементаль иммунен к горению")
	assert_true(cult_data.immunities.has("burn"), "Культист иммунен к горению")
	assert_true(worm_data.immunities.has("burn"), "Червь иммунен к горению")
	
	# Проверка: при гибели лавовый слизень оставляет лужу лавы
	var slime: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
	add_child_autofree(slime)
	slime.setup_from_data(slime_data)
	
	# Спавним лужу
	slime._spawn_death_lava_puddle()
	
	var found_puddle: bool = false
	for child in get_children():
		if child is LavaHazard:
			found_puddle = true
			assert_gt(child.lifetime, 0.0, "Лужа от слизня имеет таймер жизни")
			child.queue_free()
			break
	assert_true(found_puddle, "При гибели слизня создана временная лужа лавы")

func test_fire_items_and_stat_synergies() -> void:
	var boots: ItemData = load("res://data/items/magma_boots.tres") as ItemData
	var ring: ItemData = load("res://data/items/pyroclast_ring.tres") as ItemData
	var shield: ItemData = load("res://data/items/flame_shield.tres") as ItemData
	var core: ItemData = load("res://data/items/molten_core.tres") as ItemData
	var tome: ItemData = load("res://data/items/infernal_wrath_tome.tres") as ItemData
	
	assert_not_null(boots, "magma_boots.tres загружен")
	assert_not_null(ring, "pyroclast_ring.tres загружен")
	assert_not_null(shield, "flame_shield.tres загружен")
	assert_not_null(core, "molten_core.tres загружен")
	assert_not_null(tome, "infernal_wrath_tome.tres загружен")
	
	# Синергия 2 огненных предметов: +15% к урону
	var items_pair: Array = [boots, ring]
	var calc_dmg: float = StatCalculator.calculate_stat(20.0, items_pair, "damage")
	# Базовый 20, mult = 0.15 (ring) + 0.15 (синергия fire) = +30%: 20 * 1.30 = 26.0
	assert_almost_eq(calc_dmg, 26.0, 0.05, "Синергия 2 огненных предметов дает +15% к урону")
	
	# Синергия 4 огненных предметов: +25% к множителю крита
	var items_quad: Array = [boots, ring, shield, tome]
	var calc_crit_mult: float = StatCalculator.calculate_stat(2.0, items_quad, "crit_multiplier")
	# Базовый 2.0, mult = 0.25 (tome) + 0.25 (синергия 4 fire) = +50%: 2.0 * 1.50 = 3.0
	assert_almost_eq(calc_crit_mult, 3.0, 0.05, "Синергия 4 огненных предметов дает +25% к множителю крита")

func test_dragon_boss_3_phases_and_flight_mechanic() -> void:
	var dragon: DragonBoss = DRAGON_BOSS_SCENE.instantiate() as DragonBoss
	add_child_autofree(dragon)
	dragon.global_position = Vector2(640, 360)
	
	assert_eq(dragon.current_phase, 1, "Начальная фаза Дракона — 1")
	assert_eq(dragon.health_component.max_health, 750, "Здоровье Дракона равно 750")
	assert_false(dragon.is_airborne, "Дракон начинает бой на земле")
	
	# Опускаем здоровье ниже 60% (450 HP): переход в Фазу 2 и взлёт
	dragon.health_component.take_damage(320)
	assert_eq(dragon.current_phase, 2, "При падении ниже 60% HP босс переходит во 2 фазу")
	assert_true(dragon.is_airborne, "Дракон поднялся в воздух")
	assert_true(dragon.health_component.is_invulnerable, "Во время полета Дракон неуязвим")
	
	# Дракон завершает полет и приземляется
	dragon._land_from_flight()
	assert_false(dragon.is_airborne, "Дракон приземлился")
	assert_false(dragon.health_component.is_invulnerable, "После приземления неуязвимость снята")
	
	# Опускаем здоровье ниже 30% (225 HP): переход в Фазу 3 (Исступление)
	dragon.health_component.take_damage(250)
	assert_eq(dragon.current_phase, 3, "При падении ниже 30% HP босс переходит в Фазу 3 (Исступление)")
	
	# Окончательная победа над Драконом
	watch_signals(dragon)
	dragon.health_component.take_damage(200)
	assert_signal_emitted(dragon, "boss_defeated", "Босс повержен после истощения всех HP")

func test_fire_world_and_mines_biome_data_and_graph() -> void:
	var fire_biome: BiomeData = load("res://data/biomes/fire_world.tres") as BiomeData
	assert_not_null(fire_biome, "fire_world.tres должен существовать")
	assert_eq(fire_biome.enemy_pool.size(), 4, "В пуле врагов Мира огня должно быть 4 врага")
	assert_not_null(fire_biome.elite_enemy, "Элитный враг должен быть назначен")
	assert_not_null(fire_biome.boss_data, "Данные босса должны быть назначены")
	assert_eq(fire_biome.boss_scene_path, "res://entities/bosses/DragonBoss.tscn", "Сцена босса Дракона указана корректно")
	
	var mines_biome: BiomeData = load("res://data/biomes/fire_mines.tres") as BiomeData
	assert_not_null(mines_biome, "fire_mines.tres должен существовать")
	assert_gte(mines_biome.enemy_pool.size(), 3, "В пуле шахт как минимум 3 врага")
	
	# Проверка связей в графе мира
	var graph: WorldGraph = WorldGraph.new()
	assert_true(graph.can_reach("fire_world", "purgatory"), "Из fire_world можно дойти до purgatory")
	assert_true(graph.can_reach("fire_world", "fire_mines"), "Из fire_world есть ответвление в fire_mines")
	assert_true(graph.can_reach("fire_mines", "purgatory"), "Из fire_mines путь сходится в purgatory")
