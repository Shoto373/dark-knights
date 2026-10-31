extends GutTest

func test_stat_calculator_formula() -> void:
	# Формула: S = (S0 + ΣA) * (1 + ΣP)
	var mod1: StatModifier = StatModifier.new()
	mod1.stat_name = "damage"
	mod1.operation = "add"
	mod1.value = 10.0
	
	var mod2: StatModifier = StatModifier.new()
	mod2.stat_name = "damage"
	mod2.operation = "mult"
	mod2.value = 0.20 # +20%
	
	var item: ItemData = ItemData.new()
	item.modifiers = [mod1, mod2]
	
	# Базовый урон = 20. (20 + 10) * 1.20 = 36.0
	var calculated: float = StatCalculator.calculate_stat(20.0, [item], "damage")
	assert_almost_eq(calculated, 36.0, 0.001, "Formula S = (20 + 10) * 1.2 = 36.0")

func test_stat_calculator_synergies() -> void:
	var item1: ItemData = ItemData.new()
	item1.tags = ["fire"]
	
	var item2: ItemData = ItemData.new()
	item2.tags = ["fire", "blade"]
	
	var item3: ItemData = ItemData.new()
	item3.tags = ["blade"]
	
	# 2 fire (+15% mult), 2 blade (+6 flat)
	# Базовый урон 20 -> (20 + 6) * (1 + 0.15) = 26 * 1.15 = 29.9
	var calculated: float = StatCalculator.calculate_stat(20.0, [item1, item2, item3], "damage")
	assert_almost_eq(calculated, 29.9, 0.01, "Fire and Blade synergies should apply correctly")

func test_loot_table_weighted_roll_and_unique() -> void:
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	assert_not_null(loot_table, "default_loot_table must exist")
	assert_gte(loot_table.items.size(), 20, "LootTable must contain at least 20 items")
	
	var rolled: ItemData = loot_table.roll_item()
	assert_not_null(rolled, "Rolled item must not be null")
	
	var unique_3: Array[ItemData] = loot_table.roll_multiple_unique(3)
	assert_eq(unique_3.size(), 3, "Must roll 3 unique items")
	assert_ne(unique_3[0].id, unique_3[1].id, "Item 1 and 2 must be distinct")
	assert_ne(unique_3[1].id, unique_3[2].id, "Item 2 and 3 must be distinct")

func test_player_recalculate_stats_with_items() -> void:
	GameState.inventory_items.clear()
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	var warrior: HeroData = load("res://data/heroes/warrior.tres") as HeroData
	player.apply_hero_data(warrior)
	assert_eq(player.health_component.max_health, 120, "Warrior base HP is 120")
	
	# Добавляем яблоко (+20 HP)
	var apple: ItemData = load("res://data/items/apple.tres") as ItemData
	GameState.inventory_items.append({ "item_ref": apple })
	player.recalculate_stats()
	
	assert_eq(player.health_component.max_health, 140, "Player max HP should increase to 140 with apple")

func test_treasure_chest_requires_key() -> void:
	var chest_scene: PackedScene = load("res://entities/loot/TreasureChest.tscn")
	var chest: TreasureChest = chest_scene.instantiate() as TreasureChest
	add_child_autofree(chest)
	chest.requires_key = true
	
	GameState.keys = 0
	chest._try_open()
	assert_false(chest.is_opened, "Chest must not open without key")
	
	GameState.keys = 1
	chest._try_open()
	assert_true(chest.is_opened, "Chest must open with key")
	assert_eq(GameState.keys, 0, "Key must be consumed on chest open")

func test_item_pedestal_purchase_and_blessing() -> void:
	var ped1: ItemPedestal = (load("res://entities/loot/ItemPedestal.tscn") as PackedScene).instantiate()
	var ped2: ItemPedestal = (load("res://entities/loot/ItemPedestal.tscn") as PackedScene).instantiate()
	add_child_autofree(ped1)
	add_child_autofree(ped2)
	
	var item1: ItemData = load("res://data/items/rusty_sword.tres") as ItemData
	var item2: ItemData = load("res://data/items/leather_boots.tres") as ItemData
	
	ped1.setup(item1, 0, true) # Blessing choice
	ped2.setup(item2, 0, true) # Sibling blessing choice
	
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	ped1.player_ref = player
	
	# Выбираем ped1 -> ped2 должен быть уничтожен
	ped1._try_collect()
	assert_true(ped2.is_queued_for_deletion(), "Sibling blessing pedestal must be freed when one is picked")

