extends Node2D

const PAUSE_MENU_SCENE: PackedScene = preload("res://ui/PauseMenu.tscn")

@onready var btn_back_to_menu: Button = %BtnBackToMenu

func _ready() -> void:
	if btn_back_to_menu:
		btn_back_to_menu.pressed.connect(_on_back_to_menu_pressed)
	
	var pause_menu: PauseMenu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)

func _on_back_to_menu_pressed() -> void:
	SceneRouter.change_scene("res://ui/MainMenu.tscn", 0.3)
