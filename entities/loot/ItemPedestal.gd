class_name ItemPedestal
extends Area2D

## Пьедестал с предметом (для сокровищниц, магазинов и благословений)

signal item_picked(item: ItemData)

@export var item_data: ItemData
@export var cost_gold: int = 0
@export var is_blessing_choice: bool = false

@onready var pedestal_base: ColorRect = %PedestalBase
@onready var item_icon: ColorRect = %ItemIcon
@onready var rarity_glow: ColorRect = %RarityGlow
@onready var name_label: Label = %NameLabel
@onready var cost_label: Label = %CostLabel

var is_player_inside: bool = false
var player_ref: Player = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Слушает игрока (слой 2)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if is_blessing_choice:
		add_to_group("blessing_pedestals")
	
	_update_display()

func setup(item: ItemData, price: int = 0, is_blessing: bool = false) -> void:
	item_data = item
	cost_gold = price
	is_blessing_choice = is_blessing
	if is_blessing_choice:
		add_to_group("blessing_pedestals")
	_update_display()

func _update_display() -> void:
	if not is_node_ready() or item_data == null:
		return
	
	name_label.text = item_data.name
	var r_col: Color = item_data.get_rarity_color()
	rarity_glow.color = Color(r_col.r, r_col.g, r_col.b, 0.45)
	item_icon.color = r_col
	
	if cost_gold > 0:
		cost_label.text = "[F] Купить (%d з)" % cost_gold
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		cost_label.text = "[F] Взять"
		cost_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))

func _process(_delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("interact"):
		_try_collect()

func _try_collect() -> void:
	if item_data == null or not is_instance_valid(player_ref):
		return
	
	if cost_gold > 0:
		if GameState.gold < cost_gold:
			_flash_not_enough_gold()
			return
		GameState.add_gold(-cost_gold)
	
	# Добавляем предмет игроку
	GameState.inventory_items.append({
		"id": item_data.id,
		"name": item_data.name,
		"rarity": item_data.rarity,
		"item_ref": item_data
	})
	
	player_ref.recalculate_stats()
	EventBus.item_collected.emit(item_data.id)
	item_picked.emit(item_data)
	
	# Если это выбор одного из благословений — удаляем альтернативные варианты
	if is_blessing_choice:
		for sibling in get_tree().get_nodes_in_group("blessing_pedestals"):
			if sibling != self and is_instance_valid(sibling):
				sibling.queue_free()
	
	# Анимация поднятия
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(item_icon, "position:y", -40.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)

func _flash_not_enough_gold() -> void:
	var old_text: String = cost_label.text
	cost_label.text = "Мало золота!"
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		_update_display()
	)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_inside = true
		player_ref = body as Player
		cost_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_inside = false
		player_ref = null
