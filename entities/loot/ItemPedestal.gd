class_name ItemPedestal
extends Area2D

## Пьедестал с предметом в готическом стиле (для сокровищниц, магазинов и благословений)

signal item_picked(item: ItemData)

const PEDESTAL_TEX: Texture2D = preload("res://assets/sprites/item_pedestal.svg")

@export var item_data: ItemData
@export var cost_gold: int = 0
@export var is_blessing_choice: bool = false

@onready var pedestal_base: ColorRect = get_node_or_null("%PedestalBase") as ColorRect
@onready var item_icon: ColorRect = get_node_or_null("%ItemIcon") as ColorRect
@onready var rarity_glow: ColorRect = get_node_or_null("%RarityGlow") as ColorRect
@onready var name_label: Label = %NameLabel
@onready var cost_label: Label = %CostLabel

var is_player_inside: bool = false
var is_collected: bool = false
var player_ref: Player = null

var pedestal_sprite: Sprite2D = null
var item_sprite: Sprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Слушает игрока (слой 2)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if is_blessing_choice:
		add_to_group("blessing_pedestals")
	
	_init_sprites()
	_update_display()

func _init_sprites() -> void:
	if pedestal_sprite == null:
		pedestal_sprite = Sprite2D.new()
		pedestal_sprite.name = "PedestalSprite"
		pedestal_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pedestal_sprite.texture = PEDESTAL_TEX
		pedestal_sprite.position = Vector2(0, 0)
		add_child(pedestal_sprite)
		if pedestal_base != null:
			pedestal_base.visible = false
	
	if item_sprite == null:
		item_sprite = Sprite2D.new()
		item_sprite.name = "ItemVisualSprite"
		item_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		item_sprite.position = Vector2(0, -26)
		add_child(item_sprite)
		if item_icon != null:
			item_icon.visible = false

func setup(item: ItemData, price: int = 0, is_blessing: bool = false) -> void:
	item_data = item
	cost_gold = price
	is_blessing_choice = is_blessing
	is_collected = false
	if is_blessing_choice:
		add_to_group("blessing_pedestals")
	_update_display()

func _update_display() -> void:
	if not is_node_ready() or item_data == null:
		return
	
	_init_sprites()
	name_label.text = item_data.name
	var r_col: Color = item_data.get_rarity_color()
	name_label.add_theme_color_override("font_color", r_col)
	
	if rarity_glow != null:
		rarity_glow.color = Color(r_col.r, r_col.g, r_col.b, 0.35)
	
	# Получаем детальный спрайт артефакта
	var tex: Texture2D = SpriteGenerator.get_item_texture(item_data)
	if tex != null and item_sprite != null:
		item_sprite.texture = tex
		item_sprite.scale = Vector2(1.1, 1.1)
	
	if cost_gold > 0:
		cost_label.text = "[F] Купить (%d з)" % cost_gold
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		cost_label.text = "[F] Взять"
		cost_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))

func _process(_delta: float) -> void:
	if item_sprite != null and not is_collected:
		var bob: float = sin(Time.get_ticks_msec() * 0.0035) * 3.5
		item_sprite.position.y = -26.0 + bob
		if rarity_glow != null:
			rarity_glow.position.y = -34.0 + bob
	
	if is_player_inside and not is_collected and Input.is_action_just_pressed("interact"):
		_try_collect()

func _try_collect() -> void:
	if is_collected or item_data == null or not is_instance_valid(player_ref):
		return
	
	if cost_gold > 0:
		if GameState.gold < cost_gold:
			_flash_not_enough_gold()
			return
		GameState.add_gold(-cost_gold)
	
	is_collected = true
	var r_col: Color = item_data.get_rarity_color()
	
	if cost_gold > 0:
		AudioManager.play_sfx_named("coin")
	else:
		AudioManager.play_sfx_named("cast")
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position + Vector2(0, -26), r_col, 10)
	
	# Добавляем предмет игроку
	if item_data.id != "shop_key":
		GameState.inventory_items.append({
			"id": item_data.id,
			"name": item_data.name,
			"rarity": item_data.rarity,
			"item_ref": item_data
		})
	
	player_ref.recalculate_stats()
	EventBus.item_collected.emit(item_data.id)
	item_picked.emit(item_data)
	
	if is_blessing_choice:
		for sibling in get_tree().get_nodes_in_group("blessing_pedestals"):
			if sibling != self and is_instance_valid(sibling):
				sibling.queue_free()
	
	var tween: Tween = create_tween().set_parallel(true)
	if item_sprite != null:
		tween.tween_property(item_sprite, "position:y", -48.0, 0.22).set_ease(Tween.EASE_OUT)
		tween.tween_property(item_sprite, "scale", Vector2(1.5, 1.5), 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
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
