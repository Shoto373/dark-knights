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
