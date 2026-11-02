class_name BranchChoiceDialog
extends CanvasLayer

## Экран выбора развилки после победы над Рыцарем-скелетом: Мир холода или Мир огня

signal branch_selected(node: WorldNodeData)

@onready var btn_frost: Button = %BtnFrost
@onready var btn_fire: Button = %BtnFire
@onready var frost_card: PanelContainer = %FrostCard
@onready var fire_card: PanelContainer = %FireCard

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	btn_frost.pressed.connect(_on_frost_selected)
	btn_fire.pressed.connect(_on_fire_selected)
	
	btn_frost.mouse_entered.connect(func(): _animate_card_hover(frost_card, true))
	btn_frost.mouse_exited.connect(func(): _animate_card_hover(frost_card, false))
	btn_fire.mouse_entered.connect(func(): _animate_card_hover(fire_card, true))
	btn_fire.mouse_exited.connect(func(): _animate_card_hover(fire_card, false))

func _animate_card_hover(card: Control, is_hovered: bool) -> void:
	if not is_instance_valid(card):
		return
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_scale: Vector2 = Vector2(1.03, 1.03) if is_hovered else Vector2(1.0, 1.0)
	tween.tween_property(card, "scale", target_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_frost_selected() -> void:
	_choose_branch("frost_world")

func _on_fire_selected() -> void:
	_choose_branch("fire_world")

func _choose_branch(node_id: String) -> void:
	if is_instance_valid(AudioManager):
		AudioManager.play_sfx_named("cast")
	get_tree().paused = false
	var node: WorldNodeData = GameState.world_graph.get_node(node_id)
	if node != null:
		branch_selected.emit(node)
		GameState.advance_to_world_node(node)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
