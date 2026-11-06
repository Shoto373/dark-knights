class_name ItemPedestal
extends Area2D

## Пьедестал с предметом в готическом стиле (для сокровищниц, магазинов и благословений)

signal item_picked(item: ItemData)

const PEDESTAL_TEX: Texture2D = preload("res://assets/sprites/item_pedestal.svg")

@export var item_data: ItemData
@export var cost_gold: int = 0
@export var is_blessing_choice: bool = false
@export var floating_only: bool = false

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
var rarity_aura_sprite: Sprite2D = null
var pedestal_light: PointLight2D = null

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
		pedestal_sprite.visible = not floating_only
		add_child(pedestal_sprite)
		if pedestal_base != null:
			pedestal_base.visible = false
	
	if rarity_aura_sprite == null:
		rarity_aura_sprite = Sprite2D.new()
		rarity_aura_sprite.name = "RarityAuraSprite"
		rarity_aura_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		rarity_aura_sprite.texture = EffectsHelper.get_spark_texture()
		rarity_aura_sprite.scale = Vector2(3.5, 3.5)
		var base_y: float = -22.0 if floating_only else -36.0
		rarity_aura_sprite.position = Vector2(0, base_y)
		add_child(rarity_aura_sprite)
		move_child(rarity_aura_sprite, 0) # Располагаем за предметом
	
	if item_sprite == null:
		item_sprite = Sprite2D.new()
		item_sprite.name = "ItemVisualSprite"
		item_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var base_y: float = -22.0 if floating_only else -36.0
		item_sprite.position = Vector2(0, base_y)
		add_child(item_sprite)
		if item_icon != null:
			item_icon.visible = false
	
	var ui_node: Node2D = get_node_or_null("UI") as Node2D
	if ui_node != null:
		ui_node.z_index = 10 # Текст всегда рисуется поверх всех спрайтов и декораций
		ui_node.z_as_relative = false
	
	if rarity_glow != null:
		rarity_glow.visible = false # Старый квадратный ColorRect навсегда выключен

func set_floating_only(val: bool) -> void:
	floating_only = val
	if pedestal_sprite != null:
		pedestal_sprite.visible = not floating_only
	if pedestal_base != null:
		pedestal_base.visible = false
	var base_y: float = -22.0 if floating_only else -36.0
	if item_sprite != null:
		item_sprite.position.y = base_y
	if rarity_aura_sprite != null:
		rarity_aura_sprite.position.y = base_y
	var col_shape: Node2D = get_node_or_null("CollisionShape2D") as Node2D
	if col_shape != null:
		col_shape.position = Vector2(0, -16 if floating_only else 0)
	
	if name_label != null:
		if floating_only:
			name_label.offset_top = -68.0
			name_label.offset_bottom = -46.0
		else:
			name_label.offset_top = -78.0
			name_label.offset_bottom = -54.0
	
	if cost_label != null:
		if floating_only:
			cost_label.offset_top = 20.0
			cost_label.offset_bottom = 42.0
		else:
			cost_label.offset_top = 28.0
			cost_label.offset_bottom = 50.0

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
	
	var name_box: StyleBoxFlat = name_label.get_theme_stylebox("normal") as StyleBoxFlat
	if name_box != null:
		name_box.border_color = Color(r_col.r, r_col.g, r_col.b, 0.85)
	
	if rarity_glow != null:
		rarity_glow.visible = false
	
	if rarity_aura_sprite != null:
		rarity_aura_sprite.modulate = Color(r_col.r, r_col.g, r_col.b, 0.48)
	
	# Мягкое божественное свечение артефакта
	if SettingsManager.dynamic_lighting_enabled:
		if pedestal_light == null:
			pedestal_light = LightTextureGenerator.create_point_light(r_col.lightened(0.2), 0.75, 1.8)
			pedestal_light.name = "PedestalLight"
			var base_y: float = -22.0 if floating_only else -36.0
			pedestal_light.position = Vector2(0, base_y)
			add_child(pedestal_light)
		else:
			pedestal_light.color = r_col.lightened(0.2)
			pedestal_light.visible = not is_collected
	
	# Получаем детальный спрайт артефакта
	var tex: Texture2D = SpriteGenerator.get_item_texture(item_data)
	if tex != null and item_sprite != null:
		item_sprite.texture = tex
		item_sprite.scale = Vector2(1.25, 1.25)
	
	var cost_box: StyleBoxFlat = cost_label.get_theme_stylebox("normal") as StyleBoxFlat
	if cost_gold > 0:
		cost_label.text = "[F] Купить (%d з)" % cost_gold
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		if cost_box != null:
			cost_box.border_color = Color(1.0, 0.85, 0.2, 0.85)
	else:
		cost_label.text = "[F] Взять"
		cost_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		if cost_box != null:
			cost_box.border_color = Color(0.4, 1.0, 0.5, 0.85)

func _process(_delta: float) -> void:
	if item_sprite != null and not is_collected:
		var time: float = Time.get_ticks_msec() * 0.0032
		var bob: float = sin(time) * 3.5
		var base_y: float = -22.0 if floating_only else -36.0
		item_sprite.position.y = base_y + bob
		if rarity_aura_sprite != null:
			var pulse: float = 1.0 + sin(time * 1.5) * 0.12
			rarity_aura_sprite.scale = Vector2(3.5, 3.5) * pulse
			rarity_aura_sprite.position.y = base_y + bob
		if pedestal_light != null and pedestal_light.visible:
			pedestal_light.position.y = base_y + bob
			pedestal_light.energy = 0.75 + sin(time * 2.0) * 0.08
	
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
	
	# Добавляем предмет игроку (или ключ от магазина)
	if item_data.id == "shop_key":
		GameState.add_keys(1)
	else:
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
