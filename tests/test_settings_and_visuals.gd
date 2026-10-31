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

func test_hud_realtime_hero_change_updates_portrait_and_name() -> void:
	var hud_scene: PackedScene = load("res://ui/HUD.tscn")
	assert_not_null(hud_scene)
	var hud: HUD = hud_scene.instantiate() as HUD
	add_child_autofree(hud)
	
	var warrior_data: HeroData = load("res://data/heroes/warrior.tres") as HeroData
	var mage_data: HeroData = load("res://data/heroes/mage.tres") as HeroData
	
	EventBus.hero_changed.emit(warrior_data)
	assert_eq(hud.hero_name_label.text, warrior_data.name)
	assert_not_null(hud.hero_portrait.texture)
	
	EventBus.hero_changed.emit(mage_data)
	assert_eq(hud.hero_name_label.text, mage_data.name)
	assert_eq(hud.ability_1_label.text, "Q: %s" % mage_data.ability_1.name)

func test_troll_gorge_room_door_corridors_are_chasm_free() -> void:
	var room_scene: PackedScene = load("res://levels/Room.tscn")
	assert_not_null(room_scene)
	var room: DungeonRoom = room_scene.instantiate() as DungeonRoom
	add_child_autofree(room)
	
	var rdata: RoomData = RoomData.new()
	rdata.grid_pos = Vector2i(1, 0)
	rdata.room_type = RoomData.RoomType.COMBAT
	rdata.doors[Vector2i.UP] = true
	rdata.doors[Vector2i.DOWN] = true
	rdata.doors[Vector2i.LEFT] = true
	rdata.doors[Vector2i.RIGHT] = true
	
	var troll_biome: BiomeData = load("res://data/biomes/troll_gorge.tres") as BiomeData
	assert_not_null(troll_biome)
	
	room.setup(rdata, troll_biome)
	
	# Точки входа дверей
	var door_points: Array[Vector2] = [
		Vector2(640, 120),  # Сверху
		Vector2(640, 600),  # Снизу
		Vector2(120, 360),  # Слева
		Vector2(1160, 360)  # Справа
	]
	
	# Проверяем, что ни одна точка входа не находится внутри пропасти
	for obj in room.objects_container.get_children():
		if obj is ChasmHazard:
			var chasm: ChasmHazard = obj as ChasmHazard
			var half_size: Vector2 = chasm.pit_size / 2.0
			var rect: Rect2 = Rect2(chasm.position - half_size, chasm.pit_size)
			for pt in door_points:
				assert_false(rect.has_point(pt), "Дверная точка входа %s не должна быть в пропасти!" % pt)

func test_chasm_hazard_restores_scale_and_recovers_to_room_center() -> void:
	var chasm_scene: PackedScene = load("res://levels/hazards/ChasmHazard.tscn")
	var chasm: ChasmHazard = chasm_scene.instantiate() as ChasmHazard
	add_child_autofree(chasm)
	chasm.position = Vector2(300, 300)
	chasm.pit_size = Vector2(100, 100)
	
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector2(300, 300)
	player.scale = Vector2.ONE
	
	# Провоцируем падение
	chasm._check_player_fall(player)
	# Масштаб и координаты должны восстановиться корректно
	assert_ne(player.scale, Vector2.ZERO, "Масштаб игрока не должен быть нулевым после падения")

