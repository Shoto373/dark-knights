extends GutTest

func test_smoke_gut_running() -> void:
	assert_true(true, "GUT test framework is operational.")

func test_autoloads_initialized() -> void:
	assert_not_null(EventBus, "EventBus autoload is active.")
	assert_not_null(GameState, "GameState autoload is active.")
	assert_not_null(MetaProgress, "MetaProgress autoload is active.")
	assert_not_null(SaveManager, "SaveManager autoload is active.")
	assert_not_null(AudioManager, "AudioManager autoload is active.")
	assert_not_null(SceneRouter, "SceneRouter autoload is active.")

func test_game_state_initial_values() -> void:
	assert_eq(GameState.is_run_active, false, "Run should not be active initially.")
	assert_eq(GameState.gold, 0, "Initial gold should be 0.")
	assert_eq(GameState.keys, 0, "Initial keys should be 0.")

func test_meta_progress_initial_values() -> void:
	assert_has(MetaProgress.unlocked_heroes, "warrior", "Warrior should be unlocked by default.")

func test_main_menu_scene_instantiation() -> void:
	var scene: PackedScene = load("res://ui/MainMenu.tscn")
	assert_not_null(scene, "MainMenu scene should load successfully.")
	var instance: Node = scene.instantiate()
	assert_not_null(instance, "MainMenu instance should be created.")
	add_child_autofree(instance)
	assert_true(instance.is_inside_tree(), "MainMenu is added to tree.")

func test_hub_scene_instantiation() -> void:
	var scene: PackedScene = load("res://levels/Hub.tscn")
	assert_not_null(scene, "Hub scene should load successfully.")
	var instance: Node = scene.instantiate()
	assert_not_null(instance, "Hub instance should be created.")
	add_child_autofree(instance)
	assert_true(instance.is_inside_tree(), "Hub is added to tree.")

func test_audio_procedural_wav_creation() -> void:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(500)
	for i in range(500):
		samples[i] = 128
	wav.data = samples
	assert_not_null(wav, "WAV created successfully")
	assert_eq(wav.data.size(), 500, "WAV has expected sample count")
