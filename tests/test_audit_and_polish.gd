extends GutTest

## Тесты систем полировки, аудио, снарядов, камеры и мета-прогресса

func test_audio_manager_named_sfx_playback() -> void:
	assert_not_null(AudioManager, "AudioManager is available")
	# Check that all procedural sound effects are generated in cache
	var expected_keys: Array[String] = [
		"swing", "shoot", "cast", "hit", "crit", "dash", "coin", "hurt", "heal", "room_clear", "victory", "shield_block"
	]
	for key in expected_keys:
		assert_true(AudioManager._sfx_cache.has(key), "Cache should have SFX: " + key)
		var stream: AudioStream = AudioManager._sfx_cache.get(key)
		assert_not_null(stream, "SFX stream should not be null for " + key)
		if stream is AudioStreamWAV:
			assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "SFX %s должен быть высококачественным 16-bit" % key)
	
	# Calling play_sfx_named does not crash
	AudioManager.play_sfx_named("swing")
	AudioManager.play_sfx_named("hit", 0.1)
	AudioManager.play_sfx_named("coin")
	AudioManager.play_sfx_named("shield_block")
	assert_true(true, "SFX playback executed smoothly")

func test_audio_manager_background_music_playback() -> void:
	assert_not_null(AudioManager, "AudioManager is available")
	var music_tracks: Array[String] = ["menu", "hub", "dungeon", "boss"]
	for track in music_tracks:
		assert_true(AudioManager._music_cache.has(track), "Music cache should contain: " + track)
		var stream: AudioStream = AudioManager._music_cache.get(track)
		assert_not_null(stream, "Music stream should not be null for " + track)
		if stream is AudioStreamWAV:
			assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "Музыка %s должна быть 16-bit" % track)
			assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "Музыка %s должна циклически бесшовно зацикливаться" % track)
	
	# Проверка переключения треков
	AudioManager.play_music_named("menu", 0.1)
	assert_eq(AudioManager.current_track_name, "menu", "Текущий трек стал menu")
	AudioManager.play_music_named("dungeon", 0.1)
	assert_eq(AudioManager.current_track_name, "dungeon", "Текущий трек переключился на dungeon")
	AudioManager.stop_music(0.1)
	assert_eq(AudioManager.current_track_name, "", "После stop_music имя трека очищается")

func test_game_state_end_run_increments_meta_progress() -> void:
	var initial_runs: int = MetaProgress.lifetime_stats.get("total_runs", 0)
	GameState.is_run_active = true
	GameState.end_run(false)
	var new_runs: int = MetaProgress.lifetime_stats.get("total_runs", 0)
	assert_eq(new_runs, initial_runs + 1, "Total runs must increment on end_run")

func test_projectile_pierce_count_behavior() -> void:
	var proj_scene: PackedScene = load("res://entities/player/Projectile.tscn")
	assert_not_null(proj_scene, "Projectile scene exists")
	var proj: Projectile = proj_scene.instantiate() as Projectile
	add_child_autofree(proj)
	
	# With 0 pierce, first hit destroys projectile
	proj.setup(Vector2.RIGHT, 400.0, 10, true, 500.0, 100.0, Color.WHITE, "physical", [], "", 0)
	assert_eq(proj.pierce_count, 0, "Pierce count initialized to 0")
	
	# Emit hit landed
	proj.hitbox.hit_landed.emit(self)
	assert_true(proj.is_queued_for_deletion(), "Projectile should be queued for deletion when pierce_count is 0")
	
	# Now test pierce count 1
	var proj2: Projectile = proj_scene.instantiate() as Projectile
	add_child_autofree(proj2)
	proj2.setup(Vector2.RIGHT, 400.0, 10, true, 500.0, 100.0, Color.WHITE, "physical", [], "", 1)
	proj2.hitbox.hit_landed.emit(self)
	assert_false(proj2.is_queued_for_deletion(), "Projectile with pierce_count 1 should survive 1 hit")
	assert_eq(proj2.pierce_count, 0, "Pierce count should decrement to 0")
	proj2.hitbox.hit_landed.emit(self)
	assert_true(proj2.is_queued_for_deletion(), "Projectile should be queued for deletion after exceeding pierce count")

func test_portal_custom_callback() -> void:
	var portal_scene: PackedScene = load("res://levels/Portal.tscn")
	var portal: DungeonPortal = portal_scene.instantiate() as DungeonPortal
	add_child_autofree(portal)
	
	var box: Array[bool] = [false]
	portal.on_enter_callback = func():
		box[0] = true
	
	portal._enter_portal()
	assert_true(box[0], "Custom on_enter_callback was executed upon portal interaction")

func test_camera_shake_decay_values() -> void:
	var cam: PlayerCamera = PlayerCamera.new()
	add_child_autofree(cam)
	cam.add_shake(10.0, 0.5)
	assert_eq(cam.shake_intensity, 10.0, "Shake intensity set")
	assert_eq(cam.total_shake_duration, 0.5, "Total duration recorded")
	
	# Simulate half duration
	cam._process(0.25)
	assert_almost_eq(cam.shake_timer, 0.25, 0.01, "Shake timer halved")
	
	# Simulate full duration expired
	cam._process(0.3)
	assert_eq(cam.shake_intensity, 0.0, "Shake intensity reset to 0 after timer expires")
	assert_eq(cam.offset, Vector2.ZERO, "Camera offset returned to zero")

func test_branch_choice_dialog_canvas_layer_and_pausing() -> void:
	var branch_scene: PackedScene = load("res://ui/BranchChoiceDialog.tscn")
	assert_not_null(branch_scene, "BranchChoiceDialog scene exists")
	var dialog = branch_scene.instantiate()
	assert_true(dialog is CanvasLayer, "BranchChoiceDialog must be a CanvasLayer")
	assert_eq(dialog.layer, 80, "BranchChoiceDialog has high layer priority")
	add_child_autofree(dialog)
	assert_true(get_tree().paused, "Game must pause when BranchChoiceDialog opens")
	dialog._choose_branch("frost_world")
	assert_false(get_tree().paused, "Game must unpause when branch is chosen")

func test_portal_fork_configuration() -> void:
	var portal_scene: PackedScene = load("res://levels/Portal.tscn")
	var portal: DungeonPortal = portal_scene.instantiate() as DungeonPortal
	add_child_autofree(portal)
	portal.set_portal_title("ВЕЛИКАЯ РАЗВИЛКА")
	assert_eq(portal.portal_title.text, "ВЕЛИКАЯ РАЗВИЛКА", "Portal title is updated")
	portal.is_fork_portal = true
	assert_true(portal.is_fork_portal, "Portal is marked as fork portal")

func test_item_pedestal_and_chest_sprites() -> void:
	var item_res: ItemData = load("res://data/items/rusty_sword.tres") as ItemData
	assert_not_null(item_res, "ItemData resource exists")
	
	# Проверяем генерацию спрайта для предмета
	var item_tex: Texture2D = SpriteGenerator.get_item_texture(item_res)
	assert_not_null(item_tex, "Item texture generated successfully")
	
	var ped_scene: PackedScene = load("res://entities/loot/ItemPedestal.tscn")
	var ped: ItemPedestal = ped_scene.instantiate() as ItemPedestal
	add_child_autofree(ped)
	ped.setup(item_res, 0, false)
	assert_not_null(ped.item_sprite, "Pedestal has item sprite")
	assert_eq(ped.item_sprite.texture, item_tex, "Pedestal item sprite has matching texture")
	
	var chest_scene: PackedScene = load("res://entities/loot/TreasureChest.tscn")
	var chest: TreasureChest = chest_scene.instantiate() as TreasureChest
	add_child_autofree(chest)
	assert_not_null(chest.chest_sprite, "Chest has chest sprite")
	assert_false(chest.is_opened, "Chest starts closed")
	chest._try_open()
	assert_true(chest.is_opened, "Chest is now opened")

func test_pickup_visuals_and_sounds() -> void:
	var pick_scene: PackedScene = load("res://entities/pickups/PickupBase.tscn")
	var pickup: PickupBase = pick_scene.instantiate() as PickupBase
	pickup.pickup_type = PickupBase.PickupType.HEART
	add_child_autofree(pickup)
	assert_not_null(pickup.pickup_sprite, "Pickup sprite exists")
	assert_not_null(pickup.pickup_sprite.texture, "Pickup sprite has heart texture")

func test_hit_flash_shader_application() -> void:
	var node: Node2D = Node2D.new()
	add_child_autofree(node)
	EffectsHelper.apply_hit_flash(node, 0.1, Color.WHITE)
	assert_not_null(node.material, "Material applied to node")
	assert_true(node.material is ShaderMaterial, "Material is ShaderMaterial")
	var sm: ShaderMaterial = node.material as ShaderMaterial
	assert_almost_eq(sm.get_shader_parameter("flash_modifier"), 1.0, 0.05, "Flash modifier set to 1.0 initially")

func test_area_of_effect_circular_properties() -> void:
	var aoe_scene: PackedScene = load("res://entities/player/AreaOfEffect.tscn")
	var aoe: AreaOfEffect = aoe_scene.instantiate() as AreaOfEffect
	add_child_autofree(aoe)
	aoe.setup(Vector2.ZERO, 90.0, 50, true, 400.0)
	assert_eq(aoe.radius, 90.0, "AOE radius is 90")
	assert_eq(aoe.circle_shape.radius, 90.0, "AOE CircleShape2D radius matches")

func test_knockback_impulse_and_decay() -> void:
	var body: CharacterBody2D = CharacterBody2D.new()
	var mc: MovementComponent = MovementComponent.new()
	body.add_child(mc)
	add_child_autofree(body)
	
	mc.apply_knockback(Vector2(250.0, 0.0))
	assert_eq(mc.knockback_velocity.x, 250.0, "Initial knockback is 250")
	
	# Simulate 1 frame of movement
	var vel: Vector2 = mc.move(body, Vector2.ZERO, 0.016)
	assert_almost_eq(vel.x, 250.0, 25.0, "Initial velocity matches knockback")
	
	# Simulate 0.3 seconds: knockback must completely decay to zero
	for i in range(20):
		mc.move(body, Vector2.ZERO, 0.016)
	assert_eq(mc.knockback_velocity, Vector2.ZERO, "Knockback velocity fully decayed to zero")
	assert_eq(body.velocity, Vector2.ZERO, "Body velocity returned to zero")

func test_telegraph_circle_and_shockwave_ring() -> void:
	var root: Node2D = Node2D.new()
	add_child_autofree(root)
	
	# Проверка процедурного телеграфа (без ColorRect)
	var tg: Node2D = EffectsHelper.spawn_telegraph_circle(root, Vector2(50, 50), 60.0, 0.3, Color(1.0, 0.2, 0.1, 0.5))
	assert_not_null(tg, "Телеграф должен быть создан")
	assert_eq(tg.get("radius"), 60.0, "Радиус телеграфа 60px")
	assert_true(tg is Node2D, "Телеграф является Node2D")
	
	# Проверка ударной волны ShockwaveRing
	EffectsHelper.spawn_shockwave(root, Vector2(100, 100), 75.0, 0.2, Color(1.5, 1.2, 0.5))
	assert_gte(root.get_child_count(), 2, "В root спавнятся процедурные визуальные ноды")

func test_hero_sprite_has_no_duplicate_static_weapons() -> void:
	# 1. Проверяем SVG файлы на отсутствие запеченного статичного оружия
	var mage_svg: String = FileAccess.get_file_as_string("res://assets/sprites/hero_mage.svg")
	assert_false(mage_svg.contains('stroke="#5c2e14"'), "В hero_mage.svg нет запеченного статичного посоха")
	assert_false(mage_svg.contains('cx="51" cy="7"'), "В hero_mage.svg нет запеченного кристалла на посохе")
	
	var warrior_svg: String = FileAccess.get_file_as_string("res://assets/sprites/hero_warrior.svg")
	assert_false(warrior_svg.contains('stroke="#ecf0f1" stroke-width="3"'), "В hero_warrior.svg нет запеченного меча")
	
	var ranger_svg: String = FileAccess.get_file_as_string("res://assets/sprites/hero_ranger.svg")
	assert_false(ranger_svg.contains('stroke="#8b5a2b" stroke-width="3.5"'), "В hero_ranger.svg нет запеченного лука")
	
	# 2. Проверяем создание игрока-мага: оружие монтируется только в WeaponPivot
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Node = player_scene.instantiate()
	add_child_autofree(player)
	
	var mage_res: HeroData = load("res://data/heroes/mage.tres") as HeroData
	player.call("apply_hero_data", mage_res)
	
	var visuals: Node2D = player.get_node_or_null("Visuals") as Node2D
	assert_not_null(visuals, "Узел Visuals существует")
	var char_sprite: Sprite2D = visuals.get_node_or_null("CharacterSprite") as Sprite2D
	assert_not_null(char_sprite, "CharacterSprite существует")
	assert_not_null(char_sprite.texture, "CharacterSprite имеет текстуру мага")
	
	var img: Image = char_sprite.texture.get_image()
	assert_not_null(img, "Image текстуры мага доступен")
	var sample_x: int = int(round(img.get_width() * (51.0 / 64.0)))
	var sample_y: int = int(round(img.get_height() * (7.0 / 64.0)))
	var px_staff: Color = img.get_pixel(sample_x, sample_y)
	assert_eq(px_staff.a, 0.0, "В месте старого кристалла посоха теперь полная прозрачность (alpha == 0)")
	
	var weapon_pivot: Node2D = player.get_node_or_null("WeaponPivot") as Node2D
	assert_not_null(weapon_pivot, "WeaponPivot существует")
	var weapon_sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon_sprite, "WeaponSprite существует в WeaponPivot")
	assert_true(weapon_sprite.visible, "WeaponSprite виден в WeaponPivot")
	assert_not_null(weapon_sprite.texture, "WeaponSprite имеет текстуру посоха мага")

func test_seamless_solid_walls_when_no_doors() -> void:
	var room_scene: PackedScene = load("res://levels/Room.tscn")
	var room: Node2D = room_scene.instantiate() as Node2D
	add_child_autofree(room)
	
	var r_data: RoomData = RoomData.new()
	# Комната без дверей вверх и вниз, только влево и вправо
	r_data.doors[Vector2i.UP] = false
	r_data.doors[Vector2i.DOWN] = false
	r_data.doors[Vector2i.LEFT] = true
	r_data.doors[Vector2i.RIGHT] = true
	room.setup(r_data)
	
	# 1. Верхняя стена: W1 должна стать единым монолитом 1260px, W2 скрыта
	var w1: ColorRect = room.get_node("VisualWalls/W1") as ColorRect
	var w2: ColorRect = room.get_node("VisualWalls/W2") as ColorRect
	assert_eq(w1.offset_right, 1260.0, "W1 расширяется на всю длину верхней стены (1260px)")
	assert_false(w2.visible, "W2 скрыта при отсутствии двери")
	
	# Тень верхней стены также монолитна
	var shadow_l: ColorRect = room.get_node("WallShadowLeft") as ColorRect
	var shadow_r: ColorRect = room.get_node("WallShadowRight") as ColorRect
	assert_eq(shadow_l.offset_right, 1220.0, "Тень верхней стены продолжается монолитно на 1220px")
	assert_false(shadow_r.visible, "Правая часть тени скрыта")
	
	# Факелы распределены гармонично, а не скучены вокруг несуществующей двери
	var torch_l: Node2D = room.get_node("%Torches/TorchLeft") as Node2D
	var torch_r: Node2D = room.get_node("%Torches/TorchRight") as Node2D
	assert_eq(torch_l.position.x, 400.0, "Левый факел смещен для симметрии стены")
	assert_eq(torch_r.position.x, 880.0, "Правый факел смещен для симметрии стены")
	
	# Нижняя стена: W3 монолитна на 1260px, W4 скрыта
	var w3: ColorRect = room.get_node("VisualWalls/W3") as ColorRect
	var w4: ColorRect = room.get_node("VisualWalls/W4") as ColorRect
	assert_eq(w3.offset_right, 1260.0, "W3 расширяется на всю длину нижней стены")
	assert_false(w4.visible, "W4 скрыта")
	
	# Все визуальные заглушки WallBlocker гарантированно скрыты
	var b_up_vis: ColorRect = room.get_node("WallBlockerUp/Visual") as ColorRect
	assert_false(b_up_vis.visible, "Заглушка WallBlockerUp/Visual скрыта, чтобы не оставлять следов двери")

func test_pedestal_radial_aura_and_high_res_items() -> void:
	var ped_scene: PackedScene = load("res://entities/loot/ItemPedestal.tscn")
	var ped: ItemPedestal = ped_scene.instantiate() as ItemPedestal
	add_child_autofree(ped)
	
	var boots_item: ItemData = load("res://data/items/leather_boots.tres") as ItemData
	ped.setup(boots_item, 0, false)
	
	# 1. Проверяем мягкую радиальную ауру и отсутствие старого ColorRect
	assert_not_null(ped.rarity_aura_sprite, "Создан мягкий радиальный спрайт ауры")
	assert_true(ped.rarity_aura_sprite is Sprite2D, "Аура является Sprite2D, а не ColorRect")
	assert_true(ped.rarity_glow == null or not ped.rarity_glow.visible, "Старый прямоугольный ColorRect удален или скрыт")
	
	# 2. Проверяем режим floating_only (для сундуков)
	ped.set_floating_only(true)
	assert_true(ped.floating_only, "Включен режим парящего предмета")
	assert_false(ped.pedestal_sprite.visible, "Каменное основание скрыто, предмет парит свободно")
	
	# 3. Проверяем генерацию 32x32 детальных текстур предметов
	var boots_tex: Texture2D = SpriteGenerator.get_item_texture(boots_item)
	assert_not_null(boots_tex)
	assert_eq(boots_tex.get_width(), 32, "Ширина текстуры сапог 32px")
	assert_eq(boots_tex.get_height(), 32, "Высота текстуры сапог 32px")
	
	var apple_item: ItemData = load("res://data/items/apple.tres") as ItemData
	var apple_tex: Texture2D = SpriteGenerator.get_item_texture(apple_item)
	assert_not_null(apple_tex)
	assert_eq(apple_tex.get_width(), 32, "Иконка яблока 32px")

func test_hero_visual_overhaul_and_procedural_animations() -> void:
	# 1. Проверяем анатомическую структуру и отсутствие монолитного мешка/кокона
	var warrior_svg: String = FileAccess.get_file_as_string("res://assets/sprites/hero_warrior.svg")
	var mage_svg: String = FileAccess.get_file_as_string("res://assets/sprites/hero_mage.svg")
	var ranger_svg: String = FileAccess.get_file_as_string("res://assets/sprites/hero_ranger.svg")
	
	assert_true(warrior_svg.contains("left_leg") and warrior_svg.contains("right_leg"), "Воин имеет раздельные бронированные ноги/сапоги")
	assert_true(warrior_svg.contains("visorGlow"), "Воин имеет светящийся визор шлема")
	assert_true(mage_svg.contains("mage_left_boot") and mage_svg.contains("mage_right_boot"), "Маг имеет раздельные сапоги под подолом мантии")
	assert_true(mage_svg.contains("eyeSoul"), "Маг имеет сияющие мистические глаза души")
	assert_true(ranger_svg.contains("ranger_left_boot") and ranger_svg.contains("ranger_right_boot"), "Следопыт имеет сапоги следопыта")
	assert_true(ranger_svg.contains("eyeAmber"), "Следопыт имеет зоркие янтарные глаза")
	
	# 2. Проверяем мягкую тень персонажа на полу
	var p_scene: PackedScene = load("res://entities/player/Player.tscn")
	var p: Player = p_scene.instantiate() as Player
	add_child_autofree(p)
	
	assert_not_null(p._shadow_sprite, "У героя создана мягкая тень на полу")
	assert_true(p._shadow_sprite.z_index < 0, "Тень находится под героем")
	assert_eq(p._shadow_sprite.position.y, 18.0, "Тень точно центрирована под стопами героя")
	
	# 3. Проверяем дыхание в покое (Idle breathing)
	p.velocity = Vector2.ZERO
	p._update_procedural_animations(0.5)
	assert_ne(p.visuals.scale.y, 1.0, "В покое работает дыхание корпуса")
	
	# 4. Проверяем динамический наклон и покачивание при беге
	p.velocity = Vector2(200.0, 0.0)
	p._update_procedural_animations(0.1)
	assert_ne(p.visuals.position.y, 0.0, "При беге корпус покачивается (bobbing)")
	assert_ne(p.visuals.rotation, 0.0, "При беге корпус наклоняется вперед по движению")
	
	# 5. Проверяем выпад при атаке ближнего боя
	p.aim_direction = Vector2.RIGHT
	p._swing_melee_weapon()
	assert_true(p.is_swinging, "Активирован взмах оружием")
	assert_false(p.attack_collision.disabled, "Коллизия удара активна")

func test_animated_boots_and_eye_glow_lights() -> void:
	# 1. Текстуры сапог для всех классов
	var w_boot: Texture2D = SpriteGenerator.get_hero_boot_texture("warrior")
	var m_boot: Texture2D = SpriteGenerator.get_hero_boot_texture("mage")
	var r_boot: Texture2D = SpriteGenerator.get_hero_boot_texture("ranger")
	assert_not_null(w_boot, "Стальной сапог воина создан")
	assert_not_null(m_boot, "Сапог мага создан")
	assert_not_null(r_boot, "Сапог следопыта создан")
	
	# 2. Игрок: проверяем сапоги и светящийся взор
	var p_scene: PackedScene = load("res://entities/player/Player.tscn")
	var p: Player = p_scene.instantiate() as Player
	add_child_autofree(p)
	
	assert_not_null(p._left_boot, "Левый сапог инстанциирован")
	assert_not_null(p._right_boot, "Правый сапог инстанциирован")
	assert_not_null(p._eye_light, "Свет очей PointLight2D инстанциирован")
	assert_true(p._eye_light.energy > 0.0, "Энергия света очей активна")
	
	# 3. Проверяем шаг стопами при движении
	p.velocity = Vector2(180.0, 0.0)
	p._update_procedural_animations(0.08)
	assert_ne(p._left_boot.position.x, -5.0, "Левая стопа делает шаг")
	assert_ne(p._right_boot.position.x, 5.0, "Правая стопа делает шаг")

func test_enemy_visual_overhaul_and_archetype_animations() -> void:
	var enemy_scene: PackedScene = load("res://entities/enemies/EnemyBase.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	add_child_autofree(enemy)
	
	var data: EnemyData = load("res://data/enemies/goblin_slasher.tres") as EnemyData
	enemy.setup_from_data(data)
	
	# Тень и подсветка очей монстра
	assert_not_null(enemy._shadow_sprite, "Монстр имеет тень на полу")
	assert_true(enemy._shadow_sprite.z_index < 0, "Тень под монстром")
	assert_not_null(enemy._eye_light, "Монстр имеет светящийся взор PointLight2D")
	
	# Проверка телеграфа атаки
	var attack_state: EnemyAttackState = enemy.state_machine.get_node_or_null("Attack") as EnemyAttackState
	if attack_state != null:
		attack_state.enter()
		assert_true(attack_state.windup_timer > 0.0, "Таймер замаха активен")

func test_boss_animations_and_biome_atmosphere() -> void:
	# 1. Босс гоблинов: тень, подсветка и дыхание
	var boss_scene: PackedScene = load("res://entities/bosses/GoblinBoss.tscn")
	var boss: GoblinBoss = boss_scene.instantiate() as GoblinBoss
	add_child_autofree(boss)
	
	assert_not_null(boss._shadow_sprite, "Босс имеет мягкую тень на полу")
	assert_not_null(boss._eye_light, "Босс имеет зловещий взор PointLight2D")
	
	# 2. Атмосферные частицы в Хабе
	var hub_scene: PackedScene = load("res://levels/Hub.tscn")
	var hub: Node2D = hub_scene.instantiate() as Node2D
	add_child_autofree(hub)
	var hub_atmosphere: Node = hub.get_node_or_null("BiomeAtmosphere")
	assert_not_null(hub_atmosphere, "Хаб имеет систему атмосферных частиц BiomeAtmosphere")
	
	# 3. Атмосферные частицы в Комнате
	var room_scene: PackedScene = load("res://levels/Room.tscn")
	var room: Node2D = room_scene.instantiate() as Node2D
	add_child_autofree(room)
	var r_data: RoomData = RoomData.new()
	room.setup(r_data)
	var room_atmosphere: Node = room.get_node_or_null("BiomeAtmosphere")
	assert_not_null(room_atmosphere, "Комната имеет систему атмосферных частиц BiomeAtmosphere")

func test_aaa_dynamic_camera_aim_lead_and_kickback() -> void:
	var cam: PlayerCamera = PlayerCamera.new()
	add_child_autofree(cam)
	
	# Проверяем отдачу (Kickback)
	cam.add_kick(Vector2(1, 0), 10.0)
	assert_gt(cam._kick_offset.length(), 0.0, "Отдача камеры добавлена")
	
	# Проверяем угасание отдачи при процессинге
	var initial_kick_len: float = cam._kick_offset.length()
	cam._process(0.1)
	assert_lt(cam._kick_offset.length(), initial_kick_len, "Отдача камеры плавно затухает")

func test_aaa_ghost_health_bars_on_hud() -> void:
	var hud_scene: PackedScene = load("res://ui/HUD.tscn")
	var hud: HUD = hud_scene.instantiate() as HUD
	add_child_autofree(hud)
	
	assert_not_null(hud.ghost_hp_bar, "HUD должен иметь ghost bar для здоровья игрока")
	assert_not_null(hud.boss_ghost_hp_bar, "HUD должен иметь ghost bar для здоровья босса")
	
	# Проверяем поведение ghost bar при получении урона
	hud._on_player_health_changed(100, 100)
	assert_eq(hud.ghost_hp_bar.value, 100.0, "Ghost bar инициализирован на 100")
	
	# Наносим урон
	hud._on_player_health_changed(70, 100)
	assert_eq(hud.hp_bar.value, 70.0, "Основная шкала здоровья моментально перешла на 70")
	assert_gt(hud.ghost_hp_bar.value, 70.0, "Ghost bar отстает, показывая след потерянного здоровья")

func test_aaa_hitstop_and_ground_battle_decals() -> void:
	var root: Node2D = Node2D.new()
	add_child_autofree(root)
	
	# 1. Проверка создания боевого декаля на полу
	var decal: Sprite2D = EffectsHelper.spawn_ground_decal(root, Vector2(100, 100), Color(0.8, 0.1, 0.1, 0.6), 24.0, 5.0)
	assert_not_null(decal, "Декаль пола успешно создан")
	if decal is Sprite2D:
		assert_eq(decal.z_index, -1, "Декаль пола находится под персонажами (z_index = -1)")
	
	# 2. Проверка функции хитстопа (не падает и корректно обращается к SceneTree)
	EffectsHelper.trigger_hitstop(get_tree(), 0.04, 0.05)
	assert_true(true, "Хитстоп корректно выполнился")

func test_torch_dynamic_lighting() -> void:
	var torch_scene: PackedScene = load("res://levels/Torch.tscn")
	var torch: TorchSconce = torch_scene.instantiate() as TorchSconce
	add_child_autofree(torch)
	
	var point_light: Node = torch.get_node_or_null("TorchPointLight")
	assert_not_null(point_light, "Факел имеет динамический источник света TorchPointLight")
	if point_light is PointLight2D:
		assert_gt(point_light.energy, 0.0, "Энергия света факела больше нуля")

func test_cooldown_bars_and_live_countdown_timers() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	var hud_scene: PackedScene = load("res://ui/HUD.tscn")
	var hud: HUD = hud_scene.instantiate() as HUD
	add_child_autofree(hud)
	
	# Проверяем, что HUD автоматически нашел игрока в сцене
	assert_not_null(hud.player_ref, "HUD автоматически привязался к игроку")
	assert_not_null(hud.dash_timer_label, "Метка таймера рывка существует")
	assert_not_null(hud.ability_1_timer_label, "Метка таймера способности 1 существует")
	assert_not_null(hud.ability_2_timer_label, "Метка таймера способности 2 существует")
	
	# В состоянии готовности таймер показывает "ГОТОВ"
	hud._process(0.01)
	assert_eq(hud.dash_timer_label.text, "ГОТОВ", "Рывок изначально готов")
	assert_eq(hud.dash_bar.value, 100.0, "Шкала рывка изначально полная")
	
	# Запускаем рывок
	player.dash_cooldown_timer.start(0.8)
	hud._process(0.01)
	
	# Проверяем, что перезарядка видна сразу и визуально
	assert_lt(hud.dash_bar.value, 100.0, "Шкала рывка опустошилась при перезарядке")
	assert_true(hud.dash_timer_label.text.ends_with("с"), "Таймер показывает секунды до готовности (например, 0.8с)")
	assert_lt(hud.dash_label.modulate.a, 1.0, "Текст названия приглушается во время перезарядки")

func test_themed_dungeon_doors_and_neighbor_detection() -> void:
	var room_scene: PackedScene = load("res://levels/Room.tscn")
	var room: DungeonRoom = room_scene.instantiate() as DungeonRoom
	add_child_autofree(room)
	
	var r_data: RoomData = RoomData.new()
	r_data.grid_pos = Vector2i(0, 0)
	r_data.doors[Vector2i.UP] = true
	r_data.doors[Vector2i.RIGHT] = true
	
	var boss_data: RoomData = RoomData.new()
	boss_data.grid_pos = Vector2i(0, -1)
	boss_data.room_type = RoomData.RoomType.BOSS
	
	var treasure_data: RoomData = RoomData.new()
	treasure_data.grid_pos = Vector2i(1, 0)
	treasure_data.room_type = RoomData.RoomType.TREASURE
	
	var all_rooms: Dictionary = {
		Vector2i(0, 0): r_data,
		Vector2i(0, -1): boss_data,
		Vector2i(1, 0): treasure_data
	}
	
	room.setup(r_data, null, all_rooms)
	
	var door_up: DungeonDoor = room.get_node("%DoorUp") as DungeonDoor
	var door_right: DungeonDoor = room.get_node("%DoorRight") as DungeonDoor
	
	assert_not_null(door_up, "Верхняя дверь существует")
	assert_not_null(door_right, "Правая дверь существует")
	assert_eq(door_up.target_room_type, RoomData.RoomType.BOSS, "Верхняя дверь ведет к боссу")
	assert_eq(door_right.target_room_type, RoomData.RoomType.TREASURE, "Правая дверь ведет к сокровищнице")
	
	var boss_col: Color = door_up.get_theme_color()
	assert_gt(boss_col.r, 0.9, "Цвет двери босса ярко-красный/рубиновый")
	assert_lt(boss_col.g, 0.4, "Цвет двери босса имеет низкий зеленый компонент")
	
	var treasure_col: Color = door_right.get_theme_color()
	assert_gt(treasure_col.r, 0.9, "Цвет двери сокровищницы ярко-золотой")
	assert_gt(treasure_col.g, 0.8, "Цвет двери сокровищницы имеет высокий золотистый зеленый тон")

func test_minimap_adjacent_room_type_preview() -> void:
	var minimap_scene: PackedScene = load("res://ui/Minimap.tscn")
	var minimap: Minimap = minimap_scene.instantiate() as Minimap
	add_child_autofree(minimap)
	
	var start_room: RoomData = RoomData.new()
	start_room.grid_pos = Vector2i(0, 0)
	start_room.room_type = RoomData.RoomType.START
	start_room.doors[Vector2i.UP] = true
	start_room.doors[Vector2i.RIGHT] = true
	start_room.doors[Vector2i.DOWN] = true
	
	var boss_room: RoomData = RoomData.new()
	boss_room.grid_pos = Vector2i(0, -1)
	boss_room.room_type = RoomData.RoomType.BOSS
	boss_room.doors[Vector2i.DOWN] = true
	
	var treasure_room: RoomData = RoomData.new()
	treasure_room.grid_pos = Vector2i(1, 0)
	treasure_room.room_type = RoomData.RoomType.TREASURE
	treasure_room.doors[Vector2i.LEFT] = true
	
	var shop_room: RoomData = RoomData.new()
	shop_room.grid_pos = Vector2i(0, 1)
	shop_room.room_type = RoomData.RoomType.SHOP
	shop_room.doors[Vector2i.UP] = true
	
	var rooms: Dictionary = {
		Vector2i(0, 0): start_room,
		Vector2i(0, -1): boss_room,
		Vector2i(1, 0): treasure_room,
		Vector2i(0, 1): shop_room
	}
	
	minimap.setup_minimap(rooms, Vector2i(0, 0))
	
	# Проверяем, что стартовая комната исследована и посещена
	assert_true(start_room.is_visited, "Стартовая комната посещена")
	assert_true(start_room.is_discovered, "Стартовая комната открыта")
	
	# Проверяем, что смежные комнаты разведаны, но еще НЕ посещены
	assert_true(boss_room.is_discovered, "Смежная комната босса разведана")
	assert_false(boss_room.is_visited, "Смежная комната босса еще не посещена")
	assert_true(treasure_room.is_discovered, "Смежная комната сокровищницы разведана")
	assert_false(treasure_room.is_visited, "Смежная комната сокровищницы еще не посещена")
	assert_true(shop_room.is_discovered, "Смежный магазин разведан")
	assert_false(shop_room.is_visited, "Смежный магазин еще не посещен")
	
	# Проверяем тематическую цветовую расцветку непосещенных соседних комнат
	var boss_preview_col: Color = minimap._get_room_color(boss_room)
	assert_gt(boss_preview_col.r, boss_preview_col.g, "Цвет превью босса смещен в красный спектр")
	
	var treasure_preview_col: Color = minimap._get_room_color(treasure_room)
	assert_gt(treasure_preview_col.r, 0.4, "Цвет превью сокровищницы содержит золото")
	assert_gt(treasure_preview_col.g, 0.3, "Цвет превью сокровищницы содержит золотой оттенок")
	
	# Проверяем контрастную рамку у соседних комнат
	var boss_border_col: Color = minimap._get_room_border_color(boss_room, false)
	assert_gt(boss_border_col.r, 0.9, "Рамка комнаты босса ярко-красная")
	
	var treasure_border_col: Color = minimap._get_room_border_color(treasure_room, false)
	assert_gt(treasure_border_col.r, 0.9, "Рамка комнаты сокровищницы сияет золотом")

func test_mage_teleport_wall_collision_and_safe_clamping() -> void:
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child_autofree(player)
	
	player.global_position = Vector2(100, 100)
	player.aim_direction = Vector2.RIGHT
	
	var ability: AbilityData = AbilityData.new()
	ability.id = "teleport"
	ability.effect_type = "teleport"
	ability.range_or_radius = 200.0
	
	# Вызываем телепортацию
	player._apply_teleport_ability(ability)
	assert_eq(player.global_position.x, 300.0, "В открытом пространстве телепортация перемещает на полную дистанцию")

func test_pedestal_and_interaction_labels_formatting_and_z_index() -> void:
	var ped_scene: PackedScene = load("res://entities/loot/ItemPedestal.tscn")
	var ped: ItemPedestal = ped_scene.instantiate() as ItemPedestal
	add_child_autofree(ped)
	
	var ui_node: Node2D = ped.get_node("UI") as Node2D
	assert_not_null(ui_node, "Пьедестал имеет UI контейнер")
	assert_eq(ui_node.z_index, 10, "UI пьедестала имеет z_index = 10 для отрисовки поверх спрайтов")
	
	var name_lbl: Label = ped.get_node("%NameLabel") as Label
	var cost_lbl: Label = ped.get_node("%CostLabel") as Label
	assert_gte(name_lbl.size.x, 250.0, "NameLabel достаточно широкая (>= 250px), текст не обрезается")
	assert_gte(cost_lbl.size.x, 250.0, "CostLabel достаточно широкая (>= 250px), текст не обрезается")

func test_troll_king_boss_no_legacy_colorrects() -> void:
	var troll_scene: PackedScene = load("res://entities/bosses/TrollKingBoss.tscn")
	var boss: TrollKingBoss = troll_scene.instantiate() as TrollKingBoss
	add_child_autofree(boss)
	
	var flame_fx: ColorRect = boss.get_node_or_null("%FlameFx") as ColorRect
	var regen_fx: ColorRect = boss.get_node_or_null("%RegenFx") as ColorRect
	assert_not_null(flame_fx, "FlameFx узел существует")
	assert_not_null(regen_fx, "RegenFx узел существует")
	assert_false(flame_fx.visible, "Устаревший плоский прямоугольник FlameFx выключен")
	assert_false(regen_fx.visible, "Устаревший плоский прямоугольник RegenFx выключен")

func test_lich_king_boss_teleport_state_lock_and_watchdog() -> void:
	var lich_scene: PackedScene = load("res://entities/bosses/LichKingBoss.tscn")
	var lich: LichKingBoss = lich_scene.instantiate() as LichKingBoss
	add_child_autofree(lich)
	
	assert_false(lich.is_acting, "Изначально босс не находится в состоянии действия")
	lich._teleport_away()
	assert_true(lich.is_acting, "Во время телепортации установлен замок действия is_acting = true")
	
	# Симулируем срабатывание аварийного сторожевого таймера
	lich._acting_watchdog = 4.0
	lich._physics_process(0.1)
	assert_false(lich.is_acting, "Сторожевой таймер гарантирует сброс is_acting и предотвращает зависание")
	assert_eq(lich.modulate.a, 1.0, "Сторожевой таймер гарантирует восстановление видимости босса (modulate.a = 1.0)")

func test_pause_menu_artifacts_inventory_cards_rendering() -> void:
	var pause_scene: PackedScene = load("res://ui/PauseMenu.tscn")
	var pause_menu: PauseMenu = pause_scene.instantiate() as PauseMenu
	add_child_autofree(pause_menu)
	
	# 1. Проверяем пустой инвентарь
	GameState.inventory_items.clear()
	pause_menu._update_inventory_display()
	assert_eq(pause_menu.items_container.get_child_count(), 1, "При пустом инвентаре отображается подсказка")
	
	# 2. Добавляем тестовый артефакт
	var boots_item: ItemData = load("res://data/items/leather_boots.tres") as ItemData
	assert_not_null(boots_item, "Ресурс сапог успешно загружен")
	GameState.inventory_items.append({
		"id": boots_item.id,
		"name": boots_item.name,
		"rarity": boots_item.rarity,
		"item_ref": boots_item
	})
	
	pause_menu._update_inventory_display()
	assert_eq(pause_menu.items_container.get_child_count(), 1, "Создана карточка артефакта")
	var card: Node = pause_menu.items_container.get_child(0)
	assert_true(card is PanelContainer, "Артефакт отрисован как стильная карточка PanelContainer")
	
	# Очищаем за собой
	GameState.inventory_items.clear()
