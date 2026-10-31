extends Node2D

@onready var btn_back_to_menu: Button = %BtnBackToMenu
@onready var hub_info_label: Label = %HubInfoLabel

func _ready() -> void:
	btn_back_to_menu.pressed.connect(_on_back_to_menu_pressed)
	hub_info_label.text = "ХАБ: НАЧАЛО ПУТИ\nГерой: %s | Души: %d\n(Выбор героев и порталы будут добавлены в Спринте 2)" % [
		GameState.selected_hero_id,
		MetaProgress.souls
	]

func _on_back_to_menu_pressed() -> void:
	SceneRouter.change_scene("res://ui/MainMenu.tscn", 0.3)
