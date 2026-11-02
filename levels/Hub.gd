extends Node2D

const PAUSE_MENU_SCENE: PackedScene = preload("res://ui/PauseMenu.tscn")

@onready var btn_back_to_menu: Button = %BtnBackToMenu

func _ready() -> void:
	AudioManager.play_music_named("hub", 1.0)
	if btn_back_to_menu:
		btn_back_to_menu.pressed.connect(_on_back_to_menu_pressed)
	
	var pause_menu: PauseMenu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)
	
	# Vulkan Forward+ WorldEnvironment & Пост-обработка в Хабе
	var dungeon_env: DungeonEnvironment = DungeonEnvironment.new()
	dungeon_env.name = "DungeonEnvironment"
	add_child(dungeon_env)
	
	var pp_scene: PackedScene = load("res://ui/PostProcessLayer.tscn")
	if pp_scene != null:
		var pp = pp_scene.instantiate()
		add_child(pp)
		if pp.has_method("setup_biome"):
			pp.setup_biome("hub")

	# Атмосферные теплые пылинки в Хабе
	var atmosphere: BiomeAtmosphere = BiomeAtmosphere.new()
	atmosphere.name = "BiomeAtmosphere"
	add_child(atmosphere)
	atmosphere.setup_biome("hub")

func _on_back_to_menu_pressed() -> void:
	SceneRouter.change_scene("res://ui/MainMenu.tscn", 0.3)
