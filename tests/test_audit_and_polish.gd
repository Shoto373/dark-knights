extends GutTest

## Тесты систем полировки, аудио, снарядов, камеры и мета-прогресса

func test_audio_manager_named_sfx_playback() -> void:
	assert_not_null(AudioManager, "AudioManager is available")
	# Check that all procedural sound effects are generated in cache
	var expected_keys: Array[String] = [
		"swing", "shoot", "cast", "hit", "crit", "dash", "coin", "hurt", "heal", "room_clear", "victory"
	]
	for key in expected_keys:
		assert_true(AudioManager._sfx_cache.has(key), "Cache should have SFX: " + key)
		var stream: AudioStream = AudioManager._sfx_cache.get(key)
		assert_not_null(stream, "SFX stream should not be null for " + key)
	
	# Calling play_sfx_named does not crash
	AudioManager.play_sfx_named("swing")
	AudioManager.play_sfx_named("hit", 0.1)
	AudioManager.play_sfx_named("coin")
	assert_true(true, "SFX playback executed smoothly")

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
