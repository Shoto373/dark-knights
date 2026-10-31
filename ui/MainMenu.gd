extends Control

const SETTINGS_DIALOG_SCENE: PackedScene = preload("res://ui/SettingsDialog.tscn")

@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_continue: Button = %BtnContinue
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit

func _ready() -> void:
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	if has_node("%SettingsPanel"):
		get_node("%SettingsPanel").visible = false
	btn_continue.disabled = not SaveManager.has_saved_run()

func _on_new_game_pressed() -> void:
	# Сброс текущего забега и переход в Хаб
	GameState.is_run_active = false
	SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)

func _on_continue_pressed() -> void:
	if SaveManager.has_saved_run():
		if SaveManager.load_run():
			if GameState.current_world_node_id == "hub" or not GameState.is_run_active:
				SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)
			else:
				SceneRouter.change_scene("res://levels/DungeonFloor.tscn", 0.3)

func _on_settings_pressed() -> void:
	var dialog: SettingsDialog = SETTINGS_DIALOG_SCENE.instantiate() as SettingsDialog
	add_child(dialog)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			for child in get_children():
				if child is SettingsDialog:
					child.queue_free()
					get_viewport().set_input_as_handled()
					return
			get_tree().quit()
