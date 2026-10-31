class_name BranchChoiceDialog
extends Control

## Экран выбора развилки после победы над Рыцарем-скелетом: Мир холода или Мир огня

signal branch_selected(node: WorldNodeData)

@onready var btn_frost: Button = %BtnFrost
@onready var btn_fire: Button = %BtnFire

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_frost.pressed.connect(_on_frost_selected)
	btn_fire.pressed.connect(_on_fire_selected)

func _on_frost_selected() -> void:
	_choose_branch("frost_world")

func _on_fire_selected() -> void:
	_choose_branch("fire_world")

func _choose_branch(node_id: String) -> void:
	var node: WorldNodeData = GameState.world_graph.get_node(node_id)
	if node != null:
		branch_selected.emit(node)
		GameState.advance_to_world_node(node)
	queue_free()
