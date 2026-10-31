class_name PauseMenu
extends CanvasLayer

## Меню паузы с отображением seed забега

@onready var menu_panel: Control = %MenuPanel
@onready var seed_label: Label = %SeedLabel
@onready var floor_label: Label = %FloorLabel
@onready var btn_resume: Button = %BtnResume
@onready var btn_back_hub: Button = %BtnBackHub

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_panel.visible = false
	btn_resume.pressed.connect(_resume)
	btn_back_hub.pressed.connect(_back_to_hub)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	if menu_panel.visible:
		_resume()
	else:
		_pause()

func _pause() -> void:
	seed_label.text = "Seed: %d" % GameState.current_seed
	floor_label.text = "Этаж: %d | Локация: %s" % [GameState.current_floor_index, GameState.current_world_node_id]
	menu_panel.visible = true
	get_tree().paused = true

func _resume() -> void:
	menu_panel.visible = false
	get_tree().paused = false

func _back_to_hub() -> void:
	_resume()
	GameState.end_run(false)
	SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)

