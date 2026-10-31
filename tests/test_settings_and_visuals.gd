extends GutTest

## Тесты настроек экрана, разрешений и процедурной графики (SpriteGenerator, SettingsManager)

func test_settings_manager_resolutions_and_modes() -> void:
	assert_gt(SettingsManager.RESOLUTIONS.size(), 0, "Список разрешений не пуст")
	assert_gt(SettingsManager.RESOLUTION_NAMES.size(), 0, "Список названий разрешений не пуст")
	assert_eq(SettingsManager.RESOLUTIONS.size(), SettingsManager.RESOLUTION_NAMES.size(), "Разрешения соответствуют названиям")
	assert_eq(SettingsManager.WINDOW_MODES.size(), 3, "Поддерживаются 3 режима экрана")
	
	SettingsManager.set_master_volume(0.75)
	assert_almost_eq(SettingsManager.master_volume, 0.75, 0.01, "Громкость установлена корректно")
	
	SettingsManager.set_master_volume(2.5)
	assert_almost_eq(SettingsManager.master_volume, 1.0, 0.01, "Громкость ограничена 1.0")

func test_sprite_generator_heroes_textures() -> void:
	var warrior_tex: Texture2D = SpriteGenerator.get_hero_texture("warrior")
	var mage_tex: Texture2D = SpriteGenerator.get_hero_texture("mage")
	var ranger_tex: Texture2D = SpriteGenerator.get_hero_texture("ranger")
	
	assert_not_null(warrior_tex, "Текстура воина сгенерирована")
	assert_not_null(mage_tex, "Текстура мага сгенерирована")
	assert_not_null(ranger_tex, "Текстура следопыта сгенерирована")
	
	assert_eq(warrior_tex.get_width(), 32)
	assert_eq(warrior_tex.get_height(), 32)

func test_sprite_generator_hero_icons() -> void:
	var icon: Texture2D = SpriteGenerator.get_hero_icon("warrior")
	assert_not_null(icon, "Иконка героя сгенерирована")
	assert_eq(icon.get_width(), 40)
	assert_eq(icon.get_height(), 40)

func test_sprite_generator_enemies_textures() -> void:
	var types: Array[String] = [
		"goblin_slasher", "goblin_archer", "goblin_shaman", "goblin_brute",
		"troll_brute", "stone_thrower", "troll_regenerator",
		"skeleton_swordsman", "skeleton_crossbowman", "necromancer_acolyte", "knight_guard",
		"ice_wraith", "frost_golem", "lich_apprentice", "ice_spider",
		"lava_slime", "fire_elemental", "flame_cultist", "magma_worm",
		"shadow_chimera", "fallen_archon", "void_specter", "purgatory_executioner"
	]
	
	for t in types:
		var tex: Texture2D = SpriteGenerator.get_enemy_texture(t)
		assert_not_null(tex, "Текстура врага '%s' сгенерирована" % t)
		assert_eq(tex.get_width(), 32)

func test_sprite_generator_bosses_textures() -> void:
	var bosses: Array[String] = [
		"goblin_boss", "troll_king", "skeleton_knight", "lich_king", "dragon", "purgatory_lord"
	]
	
	for b in bosses:
		var tex: Texture2D = SpriteGenerator.get_boss_texture(b)
		assert_not_null(tex, "Текстура босса '%s' сгенерирована" % b)
		assert_eq(tex.get_width(), 48)

func test_settings_dialog_instantiation() -> void:
	var sd_scene: PackedScene = load("res://ui/SettingsDialog.tscn")
	assert_not_null(sd_scene)
	var dialog: SettingsDialog = sd_scene.instantiate() as SettingsDialog
	add_child_autofree(dialog)
	assert_not_null(dialog.mode_option)
	assert_not_null(dialog.res_option)
	assert_not_null(dialog.volume_slider)
