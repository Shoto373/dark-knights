class_name TreasureChest
extends Area2D

## Сундук с сокровищами

const PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")
const PICKUP_SCENE = preload("res://entities/pickups/PickupBase.tscn")

@export var requires_key: bool = false
@export var is_opened: bool = false

@onready var chest_lid: ColorRect = %ChestLid
@onready var interaction_label: Label = %InteractionLabel

var is_player_inside: bool = false
var player_ref: Player = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_display()

func _update_display() -> void:
	if is_opened:
		interaction_label.visible = false
		chest_lid.position.y = -22.0
		return
	
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
	
	# Анимация открытия
	var tween: Tween = create_tween()
	tween.tween_property(chest_lid, "position:y", -24.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_spawn_reward)

func _spawn_reward() -> void:
	# Достаем случайный предмет из таблицы лута
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
		pedestal.global_position = global_position + Vector2(0, -35)
		pedestal.setup(item, 0, false)
	else:
		# Резервная награда: монеты и сердце
		var coin: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		coin.pickup_type = PickupBase.PickupType.GOLD
		coin.amount = 15
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(20, -25)

func _flash_no_keys() -> void:
	interaction_label.text = "Нужен ключ!"
	interaction_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		interaction_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
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
