extends Node2D

@onready var btn_back_to_menu: Button = %BtnBackToMenu

func _ready() -> void:
	if btn_back_to_menu:
		btn_back_to_menu.pressed.connect(_on_back_to_menu_pressed)

func _on_back_to_menu_pressed() -> void:
	SceneRouter.change_scene("res://ui/MainMenu.tscn", 0.3)
