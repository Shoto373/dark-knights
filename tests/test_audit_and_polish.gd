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
