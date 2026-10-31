extends GutTest

func test_load_all_heroes_resources() -> void:
	var warrior: HeroData = load("res://data/heroes/warrior.tres") as HeroData
	var mage: HeroData = load("res://data/heroes/mage.tres") as HeroData
	var ranger: HeroData = load("res://data/heroes/ranger.tres") as HeroData
	
	assert_not_null(warrior, "Warrior resource should load.")
	assert_not_null(mage, "Mage resource should load.")
	assert_not_null(ranger, "Ranger resource should load.")
	
	assert_eq(warrior.id, "warrior")
	assert_eq(warrior.attack_type, "melee")
	assert_eq(warrior.max_hp, 120)
	assert_eq(warrior.armor, 3)
	assert_not_null(warrior.ability_1, "Warrior must have ability 1.")
	assert_not_null(warrior.ability_2, "Warrior must have ability 2.")
	
	assert_eq(mage.id, "mage")
	assert_eq(mage.attack_type, "ranged")
	assert_eq(mage.max_hp, 85)
	assert_not_null(mage.ability_1, "Mage must have fireball ability.")
	assert_not_null(mage.ability_2, "Mage must have teleport ability.")
	
	assert_eq(ranger.id, "ranger")
	assert_eq(ranger.attack_type, "ranged")
	assert_eq(ranger.unlock_cost_souls, 10)
	assert_false(ranger.unlocked_by_default, "Ranger should be locked by default.")

func test_player_applies_hero_data_correctly() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	var warrior: HeroData = load("res://data/heroes/warrior.tres") as HeroData
	player.apply_hero_data(warrior)
	
	assert_eq(player.health_component.max_health, 120, "Player max HP should be 120 for Warrior")
	assert_eq(player.hurtbox_component.armor, 3, "Player armor should be 3 for Warrior")
	assert_eq(player.movement_component.max_speed, 210.0, "Player speed should be 210 for Warrior")
	
	var mage: HeroData = load("res://data/heroes/mage.tres") as HeroData
	player.apply_hero_data(mage)
	
	assert_eq(player.health_component.max_health, 85, "Player max HP should change to 85 for Mage")
	assert_eq(player.hurtbox_component.armor, 0, "Player armor should change to 0 for Mage")
	assert_eq(player.hero_data.attack_type, "ranged", "Player attack type should be ranged for Mage")

func test_custom_hero_data_creation_without_code_changes() -> void:
	# Проверка критерия: новый герой создается только как Resource без изменения кода систем
	var custom_hero: HeroData = HeroData.new()
	custom_hero.id = "paladin"
	custom_hero.name = "Паладин"
	custom_hero.max_hp = 180
	custom_hero.armor = 5
	custom_hero.speed = 190.0
	custom_hero.attack_damage = 35
	
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	player.apply_hero_data(custom_hero)
	assert_eq(player.health_component.max_health, 180, "Custom hero max HP applied correctly")
	assert_eq(player.hurtbox_component.armor, 5, "Custom hero armor applied correctly")
	assert_eq(player.movement_component.max_speed, 190.0, "Custom hero speed applied correctly")

func test_hero_unlock_with_souls() -> void:
	MetaProgress.souls = 15
	MetaProgress.unlocked_heroes = ["warrior"]
	
	assert_false(MetaProgress.is_hero_unlocked("ranger"), "Ranger should be locked initially")
	
	var unlocked: bool = MetaProgress.unlock_hero("ranger")
	assert_true(unlocked, "unlock_hero should return true on success")
	assert_true(MetaProgress.is_hero_unlocked("ranger"), "Ranger is now unlocked")
