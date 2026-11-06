extends GutTest

## Тесты Спринта 24: Гостиная Ордена в Хабе, интерактивный ТВ, диван отдыха, камин и алтарь героев

func test_hub_lounge_structure_and_nodes() -> void:
	var hub_scene: PackedScene = load("res://levels/Hub.tscn")
	assert_not_null(hub_scene, "Сцена Hub.tscn существует")
	var hub: Node2D = hub_scene.instantiate() as Node2D
	add_child_autofree(hub)
	
	# 1. Секция пьедесталов героев (просторная расстановка без наезжания надписей)
	var ped_sec: Node2D = hub.get_node_or_null("PedestalsSection") as Node2D
	assert_not_null(ped_sec, "Секция пьедесталов героев присутствует в Хабе")
	
	var ped_war: HeroPedestal = ped_sec.get_node_or_null("PedestalWarrior") as HeroPedestal
	var ped_mag: HeroPedestal = ped_sec.get_node_or_null("PedestalMage") as HeroPedestal
	var ped_ran: HeroPedestal = ped_sec.get_node_or_null("PedestalRanger") as HeroPedestal
	assert_not_null(ped_war, "Пьедестал воина найден")
	assert_not_null(ped_mag, "Пьедестал мага найден")
	assert_not_null(ped_ran, "Пьедестал лучника найден")
	
	# Дистанция между пьедесталами составляет 170px
	var dx1: float = ped_mag.position.x - ped_war.position.x
	var dx2: float = ped_ran.position.x - ped_mag.position.x
	assert_gte(dx1, 160.0, "Расстояние между воином и магом >= 160px (факт: %d)" % int(dx1))
	assert_gte(dx2, 160.0, "Расстояние между магом и лучником >= 160px (факт: %d)" % int(dx2))
	
	# 2. Секция Гостиной Ордена (LoungeSection)
	var lounge: Node2D = hub.get_node_or_null("LoungeSection") as Node2D
	assert_not_null(lounge, "Гостиная Ордена присутствует в Хабе")
	
	var tv: HubTV = lounge.get_node_or_null("HubTV") as HubTV
	var sofa: HubSofa = lounge.get_node_or_null("HubSofa") as HubSofa
	var fireplace: HubFireplace = lounge.get_node_or_null("HubFireplace") as HubFireplace
	assert_not_null(tv, "Магический телевизор установлен в гостиной")
	assert_not_null(sofa, "Бархатный диван установлен в гостиной")
	assert_not_null(fireplace, "Каменный камин установлен в гостиной")
	
	assert_not_null(lounge.get_node_or_null("HubCarpet"), "Ковер гостиной расстелен")
	assert_not_null(lounge.get_node_or_null("HubCoffeeTable"), "Кофейный столик установлен")
	assert_not_null(lounge.get_node_or_null("HubBookshelf"), "Книжный шкаф установлен")
	assert_not_null(lounge.get_node_or_null("HubArmchair"), "Кресло установлено")
	
	# 3. Сохранение обязательных архитектурных узлов Хаба
	assert_not_null(hub.get_node_or_null("Torches"), "Узел факелов сохранен")
	assert_not_null(hub.get_node_or_null("Pillars"), "Узел колонн сохранен")
	assert_not_null(hub.get_node_or_null("CentralFloorCrest"), "Напольный герб сохранен")
	assert_not_null(hub.get_node_or_null("Portal"), "Портал в подземелье сохранен")

func test_hub_tv_channel_cycling_and_broadcast() -> void:
	var tv_scene: PackedScene = load("res://levels/HubTV.tscn")
	assert_not_null(tv_scene, "Сцена HubTV.tscn загружена")
	var tv: HubTV = tv_scene.instantiate() as HubTV
	add_child_autofree(tv)
	
	assert_gt(tv.CHANNELS.size(), 3, "Телевизор имеет разнообразные каналы вещания")
	var initial_ch: int = tv.current_channel
	
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	tv._on_body_entered(player)
	assert_true(tv.is_player_inside, "Игрок подошел к телевизору")
	assert_true(tv.prompt_label.visible, "Подсказка переключения канала видна")
	
	# Переключаем канал
	tv._next_channel()
	assert_eq(tv.current_channel, (initial_ch + 1) % tv.CHANNELS.size(), "Канал успешно переключился на следующий")
	assert_true(tv.broadcast_panel.visible, "Панель вещания активна")

func test_hub_sofa_rest_and_healing() -> void:
	var sofa_scene: PackedScene = load("res://levels/HubSofa.tscn")
	assert_not_null(sofa_scene, "Сцена HubSofa.tscn загружена")
	var sofa: HubSofa = sofa_scene.instantiate() as HubSofa
	add_child_autofree(sofa)
	
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	# Уменьшаем HP игрока
	player.health_component.current_health = 40
	player.health_component.max_health = 100
	
	sofa._on_body_entered(player)
	assert_true(sofa.is_player_inside, "Игрок подошел к дивану")
	assert_true(sofa.prompt_label.visible, "Подсказка присесть видна")
	
	# Игрок садится на диван
	sofa._start_resting()
	assert_true(sofa.is_player_resting, "Игрок устроился отдыхать на диване")
	
	# Симулируем отдых на диване
	var hp_before: int = player.health_component.current_health
	sofa._heal_timer = 1.0
	sofa._process(0.1)
	assert_gte(player.health_component.current_health, hp_before, "Диван восстанавливает здоровье отдыхающего героя")
	
	# Встаем с дивана
	sofa._stop_resting()
	assert_false(sofa.is_player_resting, "Герой встает с дивана")

func test_hub_fireplace_light_and_warmth() -> void:
	var fire_scene: PackedScene = load("res://levels/HubFireplace.tscn")
	assert_not_null(fire_scene, "Сцена HubFireplace.tscn загружена")
	var fire: HubFireplace = fire_scene.instantiate() as HubFireplace
	add_child_autofree(fire)
	
	var glow: Sprite2D = fire.get_node_or_null("LightGlow") as Sprite2D
	assert_not_null(glow, "Камин имеет мягкое свечение пламени")
	assert_gt(glow.modulate.a, 0.0, "Пламя излучает теплый свет")

func test_hero_pedestal_no_text_overlap() -> void:
	var ped_scene: PackedScene = load("res://levels/HeroPedestal.tscn")
	var ped: HeroPedestal = ped_scene.instantiate() as HeroPedestal
	add_child_autofree(ped)
	
	var warrior_data: HeroData = load("res://data/heroes/warrior.tres") as HeroData
	ped.hero_data = warrior_data
	ped._update_display()
	
	var name_lbl: Label = ped.get_node("%HeroNameLabel") as Label
	var int_lbl: Label = ped.get_node("%InteractionLabel") as Label
	
	assert_lte(name_lbl.size.x, 140.0, "Ширина NameLabel не превышает 140px (факт: %.1f)" % name_lbl.size.x)
	assert_lte(int_lbl.size.x, 140.0, "Ширина InteractionLabel не превышает 140px (факт: %.1f)" % int_lbl.size.x)
	
	# Если пьедестал закрыт и игрок далеко, подсказка скрыта, не загромождая экран
	var locked_hero: HeroData = HeroData.new()
	locked_hero.id = "paladin"
	locked_hero.name = "Паладин"
	locked_hero.unlocked_by_default = false
	locked_hero.unlock_cost_souls = 100
	
	ped.hero_data = locked_hero
	ped.is_player_inside = false
	ped._update_display()
	assert_false(ped.interaction_label.visible, "У заблокированного героя подсказка скрыта пока игрок не подойдет")
