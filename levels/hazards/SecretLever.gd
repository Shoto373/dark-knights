class_name SecretLever
extends Area2D

## Рычаг в замке, открывающий секретные проходы и тайные сокровищницы

signal lever_activated

const TREASURE_CHEST_SCENE = preload("res://entities/loot/TreasureChest.tscn")
const ITEM_PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")

@onready var prompt_label: Label = %PromptLabel
@onready var lever_handle: ColorRect = %LeverHandle
@onready var base_rect: ColorRect = %BaseRect

var is_player_inside: bool = false
var is_activated: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Игрок
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_player_inside and not is_activated and Input.is_action_just_pressed("interact"):
		activate_lever()

func activate_lever() -> void:
	if is_activated:
		return
	is_activated = true
	prompt_label.text = "[ СЕКРЕТ ОТКРЫТ ]"
	prompt_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	
	# Анимация переключения рычага
	var tween: Tween = create_tween()
	tween.tween_property(lever_handle, "rotation", deg_to_rad(45.0), 0.2)
	
	EventBus.screen_shake_requested.emit(5.0, 0.25)
	lever_activated.emit()
	
	_reveal_secret_cache()

func _reveal_secret_cache() -> void:
	# Появление тайного сундука или редкого артефакта рядом с рычагом
	var chest: TreasureChest = TREASURE_CHEST_SCENE.instantiate() as TreasureChest
	chest.requires_key = false # Награда за нахождение секрета не требует ключа!
	get_parent().add_child(chest)
	chest.global_position = global_position + Vector2(60, 0)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player") and not is_activated:
		is_player_inside = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		is_player_inside = false
		if not is_activated:
			prompt_label.visible = false

