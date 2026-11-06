extends GutTest

## Тесты Спринта 26: Графонистый визуал, динамическое освещение и сочные эффекты (Vulkan 2D Forward+)

func before_each() -> void:
	SettingsManager.dynamic_lighting_enabled = true

func test_biome_ambient_lighting_colors() -> void:
	var biomes: Array[String] = [
		"goblin_dungeon",
		"troll_gorge",
		"skeleton_castle",
		"frost_world",
		"fire_world",
		"purgatory",
		"hub"
	]
	
	var tested_colors: Array[Color] = []
	for b_id in biomes:
		var col: Color = DungeonEnvironment.get_biome_ambient_color(b_id)
		assert_ne(col, Color.WHITE, "Атмосферный свет биома %s не должен быть плоским белым" % b_id)
		assert_gt(col.a, 0.99, "Альфа-канал освещения биома равен 1.0")
		assert_false(tested_colors.has(col), "Цвета освещения биомов уникальны (%s)" % b_id)
		tested_colors.append(col)

func test_dungeon_floor_ambient_modulate_instantiation_and_toggle() -> void:
	var floor_scene: PackedScene = load("res://levels/DungeonFloor.tscn")
	assert_not_null(floor_scene, "Сцена DungeonFloor загружается")
	var floor_inst: DungeonFloor = floor_scene.instantiate() as DungeonFloor
	add_child_autofree(floor_inst)
	
	var modulate_node: CanvasModulate = floor_inst.get_node_or_null("FloorAmbientModulate") as CanvasModulate
	assert_not_null(modulate_node, "FloorAmbientModulate (CanvasModulate) присутствует на этаже")
	
	if modulate_node != null:
		assert_ne(modulate_node.color, Color.WHITE, "При включенном освещении ambient цвет не плоский белый")
		
		# Тестируем переключение опции освещения
		SettingsManager.set_dynamic_lighting_enabled(false)
		floor_inst._on_settings_changed()
		assert_eq(modulate_node.color, Color.WHITE, "При отключенном освещении ambient цвет становится Color.WHITE")
		
		SettingsManager.set_dynamic_lighting_enabled(true)
		floor_inst._on_settings_changed()
		assert_ne(modulate_node.color, Color.WHITE, "При обратном включении цвет возвращается в атмосферный")

func test_hub_ambient_modulate_instantiation() -> void:
	var hub_scene: PackedScene = load("res://levels/Hub.tscn")
	assert_not_null(hub_scene, "Сцена Hub загружается")
	var hub_inst = hub_scene.instantiate()
	add_child_autofree(hub_inst)
	
	var modulate_node: CanvasModulate = hub_inst.get_node_or_null("HubAmbientModulate") as CanvasModulate
	assert_not_null(modulate_node, "HubAmbientModulate присутствует в Хабе")
	if modulate_node != null:
		var expected_hub_col: Color = DungeonEnvironment.get_biome_ambient_color("hub")
		assert_eq(modulate_node.color, expected_hub_col, "Хаб имеет теплый сумеречный оттенок")

func test_player_dynamic_lantern_and_hero_archetypes() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	assert_not_null(player_scene, "Сцена Player.tscn загружается")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	var lantern: PointLight2D = player.get_node_or_null("LanternLight") as PointLight2D
	assert_not_null(lantern, "LanternLight (PointLight2D) прикреплен к игроку")
	
	# Воин: теплое янтарное сияние
	var warrior_data: HeroData = load("res://data/heroes/warrior.tres")
	player.apply_hero_data(warrior_data)
	assert_true(lantern.color.r > lantern.color.b, "У воина преобладает теплый спектр (красно-золотой)")
	
	# Маг: мистический сапфирово-фиолетовый ореол
	var mage_data: HeroData = load("res://data/heroes/mage.tres")
	player.apply_hero_data(mage_data)
	assert_true(lantern.color.b > lantern.color.r * 0.9, "У мага лазурно-фиолетовый спектр")
	
	# Следопыт: изумрудный разведывательный фонарь
	var ranger_data: HeroData = load("res://data/heroes/ranger.tres")
	player.apply_hero_data(ranger_data)
	assert_true(lantern.color.g >= lantern.color.r, "У рейнджера преобладает изумрудный спектр")
	
	assert_gt(lantern.energy, 0.5, "Энергия фонаря достаточна для освещения тьмы")
	assert_gt(lantern.texture_scale, 2.0, "Радиус фонаря достаточен для обзора")

func test_projectile_dynamic_lights() -> void:
	var proj_scene: PackedScene = load("res://entities/player/Projectile.tscn")
	assert_not_null(proj_scene, "Сцена Projectile.tscn загружается")
	
	# Огненный шар
	var p_fire: Projectile = proj_scene.instantiate() as Projectile
	add_child_autofree(p_fire)
	p_fire.setup(Vector2.RIGHT, 400.0, 10, true, 500.0, 100.0, Color.WHITE, "fire", ["fire"])
	var fire_light: PointLight2D = p_fire.get_node_or_null("ProjectileLight") as PointLight2D
	assert_not_null(fire_light, "Огненный шар несет динамический источник света")
	assert_true(fire_light.color.r > fire_light.color.b, "Свет огненного шара огненный")
	
	# Морозный снаряд
	var p_frost: Projectile = proj_scene.instantiate() as Projectile
	add_child_autofree(p_frost)
	p_frost.setup(Vector2.RIGHT, 400.0, 10, true, 500.0, 100.0, Color.WHITE, "freeze", ["frost"])
	var frost_light: PointLight2D = p_frost.get_node_or_null("ProjectileLight") as PointLight2D
	assert_not_null(frost_light, "Морозный снаряд несет динамический источник света")
	assert_true(frost_light.color.b > frost_light.color.r, "Свет морозного снаряда ледяной лазурный")

func test_hub_tv_and_fireplace_dynamic_lights() -> void:
	var tv_scene: PackedScene = load("res://levels/HubTV.tscn")
	assert_not_null(tv_scene, "Сцена HubTV.tscn загружается")
	var tv: HubTV = tv_scene.instantiate() as HubTV
	add_child_autofree(tv)
	
	var tv_light: PointLight2D = tv.get_node_or_null("TVPointLight") as PointLight2D
	assert_not_null(tv_light, "Телевизор в Хабе имеет динамический источник света TVPointLight")
	
	var init_color: Color = tv_light.color
	tv._next_channel()
	assert_ne(tv_light.color, init_color, "Переключение канала TV меняет цвет динамического освещения")
	
	var fp_scene: PackedScene = load("res://levels/HubFireplace.tscn")
	assert_not_null(fp_scene, "Сцена HubFireplace.tscn загружается")
	var fp: HubFireplace = fp_scene.instantiate() as HubFireplace
	add_child_autofree(fp)
	
	var fp_light: PointLight2D = fp.get_node_or_null("FireplaceLight") as PointLight2D
	assert_not_null(fp_light, "Камин в Хабе имеет динамический источник света FireplaceLight")
	assert_true(fp_light.color.r > fp_light.color.b, "Огонь камина теплый янтарный")

func test_item_pedestal_dynamic_light_and_slash_ribbon() -> void:
	var ped_scene: PackedScene = load("res://entities/loot/ItemPedestal.tscn")
	assert_not_null(ped_scene, "Сцена ItemPedestal.tscn загружается")
	var ped: ItemPedestal = ped_scene.instantiate() as ItemPedestal
	add_child_autofree(ped)
	
	var test_item: ItemData = load("res://data/items/ember_blade.tres") as ItemData
	ped.setup(test_item, 0, false)
	
	var ped_light: PointLight2D = ped.get_node_or_null("PedestalLight") as PointLight2D
	assert_not_null(ped_light, "Пьедестал с артефактом излучает божественный свет PedestalLight")
	
	# Проверка взмаха меча: Line2D дуга
	var dummy_parent: Node2D = Node2D.new()
	add_child_autofree(dummy_parent)
	EffectsHelper.spawn_slash_arc(dummy_parent, Vector2(100, 100), 0.0, 30.0, Color.CYAN)
	
	var arc_root: Node2D = dummy_parent.get_node_or_null("SlashArc") as Node2D
	assert_not_null(arc_root, "SlashArc создается в родителе")
	if arc_root != null:
		var slash_line: Line2D = arc_root.get_node_or_null("SlashArcLine") as Line2D
		assert_not_null(slash_line, "Создан непрерывный серповидный дуговой след лезвия (Line2D)")
		assert_gt(slash_line.get_point_count(), 10, "Дуговой след содержит плавные сегменты (>10 точек)")
		assert_not_null(slash_line.width_curve, "У взмаха есть динамическая кривая ширины лезвия")
