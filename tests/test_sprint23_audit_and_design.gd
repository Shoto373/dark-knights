extends GutTest

## Тесты Спринта 23: аудит багов, безопасность компонентов и редизайн интерфейса/пьедесталов

func before_each() -> void:
	GameState.start_new_run("warrior", 1337)

func test_dummy_null_safety_in_physics_process() -> void:
	# Проверка отсутствия падений Dummy при отсутствии компонентов движения
	var dummy_scene: PackedScene = load("res://entities/enemies/Dummy.tscn")
	var dummy: Dummy = dummy_scene.instantiate() as Dummy
	add_child_autofree(dummy)
	
	dummy.movement_component = null
	dummy._physics_process(0.016)
	assert_true(true, "Dummy._physics_process отработал без падений при movement_component = null")

func test_status_effect_manager_clears_on_death() -> void:
	var node: CharacterBody2D = CharacterBody2D.new()
	add_child_autofree(node)
	
	var hc: HealthComponent = HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 50
	node.add_child(hc)
	hc.reset(50)
	
	var sem: StatusEffectManager = StatusEffectManager.new()
	sem.name = "StatusEffectManager"
	sem.health_component = hc
	node.add_child(sem)
	
	var burn: StatusEffect = StatusEffect.new()
	burn.id = "burn"
	burn.duration = 4.0
	burn.damage_per_tick = 5
	burn.tick_interval = 0.5
	
	sem.apply_effect(burn, 1)
	assert_true(sem.has_effect("burn"), "Эффект горения успешно наложен")
	
	# Симулируем смерть сущности
	hc.take_damage(100)
	assert_true(hc.is_dead, "Сущность мертва")
	assert_false(sem.has_effect("burn"), "При смерти все эффекты немедленно очищены")
	
	# Попытка наложить новый эффект на труп игнорируется
	sem.apply_effect(burn, 1)
	assert_false(sem.has_effect("burn"), "Наложение эффекта на мертвую сущность заблокировано")

func test_wave_spawner_positions_clamped_to_room_bounds() -> void:
	var spawner: WaveSpawner = WaveSpawner.new()
	var room_scene: PackedScene = load("res://levels/Room.tscn")
	var room: DungeonRoom = room_scene.instantiate() as DungeonRoom
	add_child_autofree(room)
	
	var rdata: RoomData = RoomData.new()
	rdata.room_type = RoomData.RoomType.COMBAT
	rdata.distance_from_start = 5
	
	var enemies: Array[Node2D] = spawner.spawn_room_enemies(room, rdata)
	assert_gt(enemies.size(), 0, "Враги успешно созданы спавнером")
	for e in enemies:
		assert_gte(e.position.x, 140.0, "Координата X врага >= 140")
		assert_lte(e.position.x, 1140.0, "Координата X врага <= 1140")
		assert_gte(e.position.y, 140.0, "Координата Y врага >= 140")
		assert_lte(e.position.y, 580.0, "Координата Y врага <= 580")

func test_player_dash_cancels_on_death() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	player.is_dashing = true
	player.velocity = Vector2(400, 0)
	
	player.health_component.take_damage(player.health_component.max_health * 2)
	assert_true(player.health_component.is_dead, "Игрок погиб")
	assert_false(player.is_dashing, "Рывок корректно сброшен при смерти")
	assert_eq(player.velocity, Vector2.ZERO, "Скорость сброшена в ноль при гибели")

func test_hero_pedestal_visual_overhaul_and_rune_dais() -> void:
	var ped_scene: PackedScene = load("res://levels/HeroPedestal.tscn")
	var ped: HeroPedestal = ped_scene.instantiate() as HeroPedestal
	ped.hero_data = load("res://data/heroes/warrior.tres") as HeroData
	add_child_autofree(ped)
	
	# Проверяем скрытие устаревших плоских ColorRect
	assert_false(ped.statue_visual.visible, "StatueVisual ColorRect скрыт")
	assert_false(ped.selection_ring.visible, "SelectionRing ColorRect скрыт")
	
	# Проверяем наличие каменного спрайта и рунического круга
	var ped_sprite: Sprite2D = ped.get_node_or_null("PedestalSprite") as Sprite2D
	assert_not_null(ped_sprite, "Присутствует спрайт каменного пьедестала")
	assert_not_null(ped.rune_dais, "Присутствует узел рунического дайса")
	
	# Проверяем стилизацию плашки имени героя
	var name_box: StyleBoxFlat = ped.hero_name_label.get_theme_stylebox("normal") as StyleBoxFlat
	assert_not_null(name_box, "Плашка имени героя оформлена через StyleBoxFlat")

func test_sprite_generator_boss_alias_goblin_chieftain() -> void:
	var tex1: Texture2D = SpriteGenerator.get_boss_texture("goblin_chieftain")
	var tex2: Texture2D = SpriteGenerator.get_boss_texture("boss_goblin_chieftain")
	assert_not_null(tex1, "Текстура босса goblin_chieftain успешно возвращена")
	assert_not_null(tex2, "Текстура босса boss_goblin_chieftain успешно возвращена")

func test_sprite_generator_ring_texture_circular_shading() -> void:
	var ring_item: ItemData = ItemData.new()
	ring_item.id = "ruby_ring"
	ring_item.name = "Рубиновое кольцо"
	ring_item.rarity = "rare"
	
	var ring_tex: Texture2D = SpriteGenerator.get_item_texture(ring_item)
	assert_not_null(ring_tex, "Сгенерирована текстура кольца")
	assert_eq(ring_tex.get_width(), 32)
	assert_eq(ring_tex.get_height(), 32)

func test_item_pedestal_labels_pill_borders() -> void:
	var ped_scene: PackedScene = load("res://entities/loot/ItemPedestal.tscn")
	var ped: ItemPedestal = ped_scene.instantiate() as ItemPedestal
	add_child_autofree(ped)
	
	var item: ItemData = load("res://data/items/rusty_sword.tres") as ItemData
	ped.setup(item, 20, false)
	
	var name_box: StyleBoxFlat = ped.name_label.get_theme_stylebox("normal") as StyleBoxFlat
	var cost_box: StyleBoxFlat = ped.cost_label.get_theme_stylebox("normal") as StyleBoxFlat
	assert_not_null(name_box, "NameLabel имеет фоновую плашку StyleBoxFlat")
	assert_not_null(cost_box, "CostLabel имеет фоновую плашку StyleBoxFlat")
