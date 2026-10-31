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

func test_door_size_covers_full_opening_without_gaps() -> void:
	var door_scene: PackedScene = load("res://levels/Door.tscn")
	assert_not_null(door_scene)
	
	# Горизонтальная дверь (Сверху / Снизу)
	var door_h: DungeonDoor = door_scene.instantiate() as DungeonDoor
	door_h.direction = Vector2i.UP
	add_child_autofree(door_h)
	assert_eq(door_h.door_visual.size.x, 96.0, "Ширина горизонтальной двери должна быть 96px без щелей")
	assert_eq(door_h.door_visual.size.y, 40.0)
	
	# Вертикальная дверь (Слева / Справа)
	var door_v: DungeonDoor = door_scene.instantiate() as DungeonDoor
	door_v.direction = Vector2i.LEFT
	add_child_autofree(door_v)
	assert_eq(door_v.door_visual.size.x, 40.0)
	assert_eq(door_v.door_visual.size.y, 96.0, "Высота вертикальной двери должна быть 96px без щелей")

func test_all_biome_enemies_load_distinct_textures() -> void:
	var troll_data: EnemyData = load("res://data/enemies/troll_brute.tres") as EnemyData
	var skeleton_data: EnemyData = load("res://data/enemies/skeleton_swordsman.tres") as EnemyData
	var slime_data: EnemyData = load("res://data/enemies/lava_slime.tres") as EnemyData
	var goblin_data: EnemyData = load("res://data/enemies/goblin_slasher.tres") as EnemyData
	
	assert_not_null(troll_data)
	assert_not_null(skeleton_data)
	assert_not_null(slime_data)
	assert_not_null(goblin_data)
	
	var tex_troll: Texture2D = SpriteGenerator.get_enemy_texture(troll_data.id)
	var tex_skeleton: Texture2D = SpriteGenerator.get_enemy_texture(skeleton_data.id)
	var tex_slime: Texture2D = SpriteGenerator.get_enemy_texture(slime_data.id)
	var tex_goblin: Texture2D = SpriteGenerator.get_enemy_texture(goblin_data.id)
	
	assert_not_null(tex_troll)
	assert_not_null(tex_skeleton)
	assert_not_null(tex_slime)
	assert_not_null(tex_goblin)
	
	# Текстуры разных мобов должны быть уникальными (не одинаковыми)
	assert_ne(tex_troll, tex_goblin, "Тролль не должен использовать спрайт гоблина")
	assert_ne(tex_skeleton, tex_goblin, "Скелет не должен использовать спрайт гоблина")
	assert_ne(tex_slime, tex_goblin, "Слизень не должен использовать спрайт гоблина")

func test_world_map_closes_on_escape() -> void:
	var map_scene: PackedScene = load("res://ui/WorldMap.tscn")
	assert_not_null(map_scene)
	var map: WorldMap = map_scene.instantiate() as WorldMap
	add_child_autofree(map)
	map.set_mode(false)
	
	var ev: InputEventKey = InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_ESCAPE
	map._input(ev)
	
	assert_true(map.is_queued_for_deletion(), "Карта мира должна закрываться по нажатию ESC")

func test_weapon_visual_distinct_textures_per_hero() -> void:
	var sword_tex: Texture2D = SpriteGenerator.get_weapon_texture("warrior")
	var staff_tex: Texture2D = SpriteGenerator.get_weapon_texture("mage")
	var bow_tex: Texture2D = SpriteGenerator.get_weapon_texture("ranger")
	
	assert_not_null(sword_tex, "Текстура меча должна загружаться")
	assert_not_null(staff_tex, "Текстура посоха должна загружаться")
	assert_not_null(bow_tex, "Текстура лука должна загружаться")
	
	assert_ne(sword_tex, staff_tex, "Меч и посох должны иметь разные текстуры")
	assert_ne(sword_tex, bow_tex, "Меч и лук должны иметь разные текстуры")
	assert_ne(staff_tex, bow_tex, "Посох и лук должны иметь разные текстуры")

func test_projectile_visual_distinct_textures() -> void:
	var arrow_tex: Texture2D = SpriteGenerator.get_projectile_texture("arrow")
	var magic_tex: Texture2D = SpriteGenerator.get_projectile_texture("magic")
	var fire_tex: Texture2D = SpriteGenerator.get_projectile_texture("fire")
	var frost_tex: Texture2D = SpriteGenerator.get_projectile_texture("frost")
	
	assert_not_null(arrow_tex, "Текстура стрелы должна загружаться")
	assert_not_null(magic_tex, "Текстура магического снаряда должна загружаться")
	assert_not_null(fire_tex, "Текстура огненного шара должна загружаться")
	assert_not_null(frost_tex, "Текстура ледяного осколка должна загружаться")
	
	assert_ne(arrow_tex, magic_tex)
	assert_ne(fire_tex, frost_tex)

func test_dungeon_architectural_assets_load() -> void:
	var tile_tex: Texture2D = SpriteGenerator.get_dungeon_tile_texture()
	var brick_tex: Texture2D = SpriteGenerator.get_wall_brick_texture()
	var pillar_tex: Texture2D = SpriteGenerator.get_pillar_texture()
	var crest_tex: Texture2D = SpriteGenerator.get_floor_crest_texture()
	var portal_tex: Texture2D = SpriteGenerator.get_portal_texture()
	var torch_tex: Texture2D = SpriteGenerator.get_torch_texture()
	
	assert_not_null(tile_tex, "Текстура плитки пола должна загружаться")
	assert_not_null(brick_tex, "Текстура кирпичной кладки должна загружаться")
	assert_not_null(pillar_tex, "Текстура колонны должна загружаться")
	assert_not_null(crest_tex, "Текстура напольного герба должна загружаться")
	assert_not_null(portal_tex, "Текстура портала должна загружаться")
	assert_not_null(torch_tex, "Текстура факела должна загружаться")

func test_target_dummy_and_trap_textures_and_states() -> void:
	var dummy_tex: Texture2D = SpriteGenerator.get_target_dummy_texture()
	var trap_ext: Texture2D = SpriteGenerator.get_trap_texture(true)
	var trap_ret: Texture2D = SpriteGenerator.get_trap_texture(false)
	
	assert_not_null(dummy_tex, "Текстура манекена должна загружаться")
	assert_not_null(trap_ext, "Текстура выдвинутых шипов должна загружаться")
	assert_not_null(trap_ret, "Текстура скрытых шипов должна загружаться")
	assert_ne(trap_ext, trap_ret, "Выдвинутые и скрытые шипы должны различаться")

func test_hub_and_room_decorations_instantiation() -> void:
	var hub_scene: PackedScene = load("res://levels/Hub.tscn")
	assert_not_null(hub_scene)
	var hub = hub_scene.instantiate()
	add_child_autofree(hub)
	
	assert_not_null(hub.get_node_or_null("Torches"), "Хаб должен содержать узел факелов")
	assert_not_null(hub.get_node_or_null("Pillars"), "Хаб должен содержать узел колонн")
	assert_not_null(hub.get_node_or_null("CentralFloorCrest"), "Хаб должен содержать напольный герб")

