class_name HeroPedestal
extends Area2D

## Пьедестал выбора героя в Хабе

@export var hero_data: HeroData

@onready var statue_visual: ColorRect = %StatueVisual
@onready var hero_name_label: Label = %HeroNameLabel
@onready var interaction_label: Label = %InteractionLabel
@onready var selection_ring: ColorRect = %SelectionRing

var is_player_inside: bool = false
var player_ref: Player = null

func _ready() -> void:
	# Коллизия для взаимодействия с игроком (слой 2)
	collision_layer = 0
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_update_display()

func _update_display() -> void:
	if hero_data == null:
		return
	
	hero_name_label.text = hero_data.name
	statue_visual.color = hero_data.color
	
	var is_unlocked: bool = hero_data.unlocked_by_default or MetaProgress.is_hero_unlocked(hero_data.id)
	var is_active: bool = (GameState.selected_hero_id == hero_data.id)
	
	selection_ring.visible = is_active
	
	if not is_unlocked:
		statue_visual.color = Color(0.3, 0.3, 0.3, 0.7)
		if is_player_inside:
			interaction_label.text = "[F] Разблокировать (%d душ)" % hero_data.unlock_cost_souls
			interaction_label.visible = true
		else:
			interaction_label.text = "Закрыто (%d душ)" % hero_data.unlock_cost_souls
			interaction_label.visible = true
	else:
		if is_active:
			interaction_label.text = "Выбран"
			interaction_label.visible = true
		elif is_player_inside:
			interaction_label.text = "[F] Выбрать"
			interaction_label.visible = true
		else:
			interaction_label.visible = false

func _process(_delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("interact"):
		_interact()

func _interact() -> void:
	if hero_data == null:
		return
	
	var is_unlocked: bool = hero_data.unlocked_by_default or MetaProgress.is_hero_unlocked(hero_data.id)
	if not is_unlocked:
		if MetaProgress.souls >= hero_data.unlock_cost_souls:
			MetaProgress.souls -= hero_data.unlock_cost_souls
			MetaProgress.unlock_hero(hero_data.id)
			_select_hero()
		else:
			# Недостаточно душ
			var tween: Tween = create_tween()
			interaction_label.text = "Недостаточно душ!"
			tween.tween_interval(1.0)
			tween.tween_callback(_update_display)
		return
	
	_select_hero()

func _select_hero() -> void:
	GameState.selected_hero_id = hero_data.id
	if is_instance_valid(player_ref):
		player_ref.apply_hero_data(hero_data)
	
	# Обновляем все пьедесталы в Хабе
	for pedestal in get_tree().get_nodes_in_group("hero_pedestals"):
		if pedestal.has_method("_update_display"):
			pedestal._update_display()

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

