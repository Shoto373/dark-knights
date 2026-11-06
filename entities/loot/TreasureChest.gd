class_name TreasureChest
extends Area2D

## Сундук с сокровищами в стиле Dark Fantasy

const PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")
const PICKUP_SCENE = preload("res://entities/pickups/PickupBase.tscn")
const CHEST_CLOSED_TEX: Texture2D = preload("res://assets/sprites/chest_closed.svg")
const CHEST_OPEN_TEX: Texture2D = preload("res://assets/sprites/chest_open.svg")

@export var requires_key: bool = false:
	set(val):
		requires_key = val
		if is_inside_tree():
			_update_display()
@export var is_opened: bool = false

@onready var chest_lid: ColorRect = get_node_or_null("%ChestLid") as ColorRect
@onready var interaction_label: Label = %InteractionLabel

var is_player_inside: bool = false
var player_ref: Player = null
var chest_sprite: Sprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_init_sprite()
	_update_display()

func _init_sprite() -> void:
	if chest_sprite == null:
		chest_sprite = Sprite2D.new()
		chest_sprite.name = "ChestSprite"
		chest_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		chest_sprite.position = Vector2(0, 0)
		add_child(chest_sprite)
		
		var b: Node = get_node_or_null("ChestBody")
		if b is CanvasItem: b.visible = false
		if chest_lid != null: chest_lid.visible = false
		var l: Node = get_node_or_null("GoldLock")
		if l is CanvasItem: l.visible = false

func _update_display() -> void:
	_init_sprite()
	if is_opened:
		interaction_label.visible = false
		if chest_lid != null:
			chest_lid.position.y = -22.0
		chest_sprite.texture = CHEST_OPEN_TEX
		return
	
	chest_sprite.texture = CHEST_CLOSED_TEX
	if is_player_inside:
		interaction_label.visible = true
		if requires_key:
			interaction_label.text = "[F] Открыть (1 ключ)"
		else:
			interaction_label.text = "[F] Открыть"
	else:
		interaction_label.visible = false

func _process(_delta: float) -> void:
	if is_player_inside and not is_opened and Input.is_action_just_pressed("interact"):
		_try_open()

func _try_open() -> void:
	if requires_key:
		if GameState.keys <= 0:
			_flash_no_keys()
			return
		GameState.add_keys(-1)
	
	is_opened = true
	_update_display()
	
	AudioManager.play_sfx_named("coin")
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(1.0, 0.85, 0.2), 10)
	
	if SettingsManager.dynamic_lighting_enabled and get_parent() != null:
		var chest_light: PointLight2D = LightTextureGenerator.create_point_light(Color(1.0, 0.88, 0.3), 1.1, 2.5)
		chest_light.global_position = global_position + Vector2(0, -10)
		get_parent().add_child(chest_light)
		var cl_tween: Tween = chest_light.create_tween()
		cl_tween.tween_property(chest_light, "energy", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		cl_tween.tween_callback(chest_light.queue_free)
	
	var tween: Tween = create_tween()
	tween.tween_property(chest_sprite, "scale", Vector2(1.2, 0.85), 0.08)
	tween.tween_property(chest_sprite, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_spawn_reward)

func _spawn_reward() -> void:
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	var item: ItemData = null
	if loot_table != null:
		var owned_ids: Array = []
		for inv_item in GameState.inventory_items:
			owned_ids.append(inv_item.get("id", ""))
		item = loot_table.roll_item(GameState.rng, owned_ids)
	
	if item != null:
		var pedestal: ItemPedestal = PEDESTAL_SCENE.instantiate() as ItemPedestal
		get_parent().add_child(pedestal)
		pedestal.global_position = global_position + Vector2(0, -26)
		pedestal.setup(item, 0, false)
		pedestal.set_floating_only(true)
	else:
		var coin: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		coin.pickup_type = PickupBase.PickupType.GOLD
		coin.amount = 15
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(20, -25)

func _flash_no_keys() -> void:
	interaction_label.text = "Требуется ключ!"
	interaction_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		interaction_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		_update_display()
	)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_inside = true
		player_ref = body as Player
		_update_display()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_inside = false
		player_ref = null
		_update_display()
