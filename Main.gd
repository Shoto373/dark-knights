extends Node

func _ready() -> void:
	# Точка входа в игру - перенаправляем в главное меню
	SceneRouter.change_scene("res://ui/MainMenu.tscn", 0.1)

