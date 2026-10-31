extends Control

@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_continue: Button = %BtnContinue
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var btn_close_settings: Button = %BtnCloseSettings

func _ready() -> void:
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_close_settings.pressed.connect(_on_close_settings_pressed)
	
	settings_panel.visible = false
	btn_continue.disabled = not SaveManager.has_saved_run()

func _on_new_game_pressed() -> void:
	# Сброс текущего забега и переход в Хаб
	GameState.is_run_active = false
	SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)

func _on_continue_pressed() -> void:
	if SaveManager.has_saved_run():
		if SaveManager.load_run():
			SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)

func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	settings_panel.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()

