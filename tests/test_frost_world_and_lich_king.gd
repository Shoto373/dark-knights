extends GutTest

## GUT-тесты для Спринта 8:
## Механика статусов (Заморозка, Горение, Яд, Оглушение), Лед, 4 морозных врага,
## 5 морозных предметов и синергии, 3 фазы Короля-лича и Филактерия.

const PLAYER_SCENE = preload("res://entities/player/Player.tscn")
const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const ICE_PATCH_SCENE = preload("res://levels/hazards/IcePatch.tscn")
const LICH_BOSS_SCENE = preload("res://entities/bosses/LichKingBoss.tscn")
const PHYLACTERY_SCENE = preload("res://entities/bosses/Phylactery.tscn")

var player: Player
var enemy: EnemyBase

func before_each() -> void:
	GameState.start_new_run("warrior", 8888)
	GameState.current_world_node_id = "frost_world"
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector2(200, 200)

func after_each() -> void:
	GameState.end_run(false)

func test_status_effect_freeze_stacks_and_frozen_solid() -> void:
	var mgr: StatusEffectManager = player.status_effect_manager
	assert_not_null(mgr, "StatusEffectManager должен присутствовать у игрока")
	
	var freeze_res: StatusEffect = load("res://data/status_effects/freeze.tres") as StatusEffect
	assert_not_null(freeze_res, "Ресурс freeze.tres должен существовать")
	
	# Базовая скорость
	assert_eq(mgr.get_speed_multiplier(), 1.0, "Начальный множитель скорости равен 1.0")
	assert_false(mgr.is_frozen(), "Игрок не должен быть заморожен в начале")
	
	# 1 стак: замедление на 25% (множитель 0.75)
	mgr.apply_effect(freeze_res, 1)
	assert_almost_eq(mgr.get_speed_multiplier(), 0.75, 0.01, "1 стак заморозки снижает скорость на 25%")
	assert_false(mgr.is_frozen(), "1 стак еще не обездвиживает целиком")
	
	# 2 стака: замедление на 50% (множитель 0.50)
	mgr.apply_effect(freeze_res, 1)
	assert_almost_eq(mgr.get_speed_multiplier(), 0.50, 0.01, "2 стака заморозки снижают скорость на 50%")
	assert_false(mgr.is_frozen(), "2 стака еще не обездвиживают целиком")
	
	# 3 стака: ПОЛНАЯ ЗАМОРОЗКА В ГЛЫБУ ЛЬДА (скорость 0.0, is_frozen = true)
	mgr.apply_effect(freeze_res, 1)
	assert_eq(mgr.get_speed_multiplier(), 0.0, "3 стака дают множитель скорости 0.0")
	assert_true(mgr.is_frozen(), "3 стака заморозки полностью парализуют цель")
	
	# По истечении времени статус спадает
	mgr.process_effects(3.2)
	assert_false(mgr.is_frozen(), "После окончания времени заморозка спадает")
	assert_eq(mgr.get_speed_multiplier(), 1.0, "Скорость восстанавливается")

func test_status_effect_burn_damage_ticks() -> void:
	var burn_res: StatusEffect = load("res://data/status_effects/burn.tres") as StatusEffect
	assert_not_null(burn_res, "Ресурс burn.tres должен существовать")
	
	var mgr: StatusEffectManager = player.status_effect_manager
	var initial_hp: int = player.health_component.current_health
	
	mgr.apply_effect(burn_res, 1)
	assert_true(mgr.has_effect("burn"), "Эффект горения должен быть активен")
	
	# Прокручиваем 1.0 секунду (tick_interval горения = 0.5с -> 2 тика по 4 урона = 8 урона)
	mgr.process_effects(1.05)
	assert_eq(player.health_component.current_health, initial_hp - 8, "Горение нанесло 2 тика урона (8 урона)")

func test_status_effect_immunity_on_frost_enemies() -> void:
	var wraith_data: EnemyData = load("res://data/enemies/ice_wraith.tres") as EnemyData
	assert_not_null(wraith_data, "ice_wraith.tres должен существовать")
	assert_true(wraith_data.immunities.has("freeze"), "Ледяной призрак должен быть иммунен к заморозке")
	
	var wraith: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
	add_child_autofree(wraith)
	wraith.setup_from_data(wraith_data)
	
	var freeze_res: StatusEffect = load("res://data/status_effects/freeze.tres") as StatusEffect
	wraith.status_effect_manager.apply_effect(freeze_res, 3)
	
	assert_false(wraith.status_effect_manager.is_frozen(), "Враг с иммунитетом не может быть заморожен")
	assert_eq(wraith.status_effect_manager.get_speed_multiplier(), 1.0, "Скорость не снижается")

func test_slippery_ice_physics_and_ice_patch() -> void:
	var patch: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
	add_child_autofree(patch)
	patch.global_position = Vector2(300, 300)
	
	assert_false(player.movement_component.is_on_ice, "Игрок изначально не на льду")
	
	# Игрок наступает на лед
	patch._on_body_entered(player)
	assert_true(player.movement_component.is_on_ice, "MovementComponent переключился в режим скольжения по льду")
	
	# Игрок сходит со льда
	patch._on_body_exited(player)
	assert_false(player.movement_component.is_on_ice, "MovementComponent восстановил обычное трение")

func test_frost_items_and_stat_synergies() -> void:
	var shard: ItemData = load("res://data/items/frost_shard.tres") as ItemData
	var armor: ItemData = load("res://data/items/glacier_armor.tres") as ItemData
	var orb: ItemData = load("res://data/items/blizzard_orb.tres") as ItemData
	var heart: ItemData = load("res://data/items/frozen_heart.tres") as ItemData
	var amulet: ItemData = load("res://data/items/absolute_zero_amulet.tres") as ItemData
	
	assert_not_null(shard, "frost_shard.tres загружен")
	assert_not_null(armor, "glacier_armor.tres загружен")
	assert_not_null(orb, "blizzard_orb.tres загружен")
	assert_not_null(heart, "frozen_heart.tres загружен")
	assert_not_null(amulet, "absolute_zero_amulet.tres загружен")
	
	# Проверка синергии 2 морозных предметов (frost >= 2)
	# +2 к броне и +12% к урону
	var items_pair: Array = [shard, armor]
	var calc_armor: float = StatCalculator.calculate_stat(4.0, items_pair, "armor")
	# Базовая 4 + 3 (от glacier_armor) + 2 (синергия холода) = 9
	assert_eq(calc_armor, 9.0, "Синергия 2 морозных предметов дает +2 к броне")
	
	var calc_dmg: float = StatCalculator.calculate_stat(20.0, items_pair, "damage")
	# Базовый 20 + 4 (frost_shard) = 24. mult = +12% от синергии: 24 * 1.12 = 26.88
	assert_almost_eq(calc_dmg, 26.88, 0.05, "Синергия 2 морозных предметов дает +12% к урону")
	
	# Проверка синергии 4 морозных предметов (frost >= 4)
	# +10% к шансу крита
	var items_quad: Array = [shard, armor, orb, amulet]
	var calc_crit: float = StatCalculator.calculate_stat(0.10, items_quad, "crit_chance")
	# Базовый 0.10 + 0.15 (amulet) + 0.10 (синергия 4 frost) = 0.35
	assert_almost_eq(calc_crit, 0.35, 0.01, "Синергия 4 морозных предметов дает +10% к шансу крита")

func test_frozen_heart_item_grants_ice_and_slow_immunity() -> void:
	var heart: ItemData = load("res://data/items/frozen_heart.tres") as ItemData
	GameState.inventory_items.append({"item_ref": heart})
	player.recalculate_stats()
	
	# Иммунитет к заморозке
	assert_true(player.status_effect_manager.immunities.has("freeze"), "Замерзшее сердце наделяет иммунитетом к холоду")
	
	# Проверка: наступив на IcePatch, игрок с Замерзшим сердцем не начинает скользить
	var patch: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
	add_child_autofree(patch)
	patch._on_body_entered(player)
	assert_false(player.movement_component.is_on_ice, "Игрок с Замерзшим сердцем не скользит по льду")

func test_lich_king_boss_3_phases_and_phylactery_mechanic() -> void:
	var boss: LichKingBoss = LICH_BOSS_SCENE.instantiate() as LichKingBoss
	add_child_autofree(boss)
	boss.global_position = Vector2(640, 360)
	
	assert_eq(boss.current_phase, 1, "Начальная фаза босса — 1")
	assert_eq(boss.health_component.max_health, 650, "Здоровье Короля-лича равно 650")
	
	# Опускаем здоровье до 380 (ниже 60% = 390)
	boss.health_component.take_damage(270)
	assert_eq(boss.current_phase, 2, "При падении ниже 60% HP босс переходит во 2 фазу")
	
	# Опускаем здоровье босса до 0 HP: вход в Фазу 3 и призыв Филактерии!
	boss.health_component.take_damage(380)
	assert_eq(boss.current_phase, 3, "При истощении HP босс переходит в Фазу 3")
	assert_true(boss.health_component.is_invulnerable, "В Фазе 3 Король-лич бестелесен и неуязвим")
	assert_not_null(boss.phylactery_instance, "Филактерия должна быть заспавнена в 3 фазе")
	assert_eq(boss.phylactery_instance.health_component.current_health, 180, "Здоровье филактерии равно 180")
	
	# Попытка нанести урон боссу напрямую в 3 фазе не срабатывает из-за неуязвимости
	boss.health_component.take_damage(50)
	assert_true(boss.health_component.is_invulnerable, "Босс остается неуязвимым")
	
	# Игрок разбивает Филактерию (180 урона)
	watch_signals(boss)
	boss.phylactery_instance.health_component.take_damage(180)
	
	assert_false(boss.health_component.is_invulnerable, "После уничтожения филактерии неуязвимость спадает")
	assert_signal_emitted(boss, "boss_defeated", "Босс окончательно побежден после уничтожения филактерии")

func test_frost_world_and_caves_biome_data_and_graph() -> void:
	var frost_biome: BiomeData = load("res://data/biomes/frost_world.tres") as BiomeData
	assert_not_null(frost_biome, "frost_world.tres должен существовать")
	assert_eq(frost_biome.enemy_pool.size(), 4, "В пуле врагов Мира холода должно быть 4 врага")
	assert_not_null(frost_biome.elite_enemy, "Элитный враг должен быть назначен")
	assert_not_null(frost_biome.boss_data, "Данные босса должны быть назначены")
	assert_eq(frost_biome.boss_scene_path, "res://entities/bosses/LichKingBoss.tscn", "Сцена босса Короля-лича указана корректно")
	
	var caves_biome: BiomeData = load("res://data/biomes/frost_caves.tres") as BiomeData
	assert_not_null(caves_biome, "frost_caves.tres должен существовать")
	assert_gte(caves_biome.enemy_pool.size(), 3, "В пуле ледяных пещер как минимум 3 типа врагов")
	
	# Проверка связей в графе мира
	var graph: WorldGraph = WorldGraph.new()
	assert_true(graph.can_reach("frost_world", "purgatory"), "Из frost_world можно дойти до purgatory")
	assert_true(graph.can_reach("frost_world", "frost_caves"), "Из frost_world есть ответвление в frost_caves")
	assert_true(graph.can_reach("frost_caves", "purgatory"), "Из frost_caves путь сходится в purgatory")
