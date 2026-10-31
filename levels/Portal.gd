class_name DungeonPortal
extends Area2D

## Портал начала забега «Начать путь»

@onready var prompt_label: Label = %PromptLabel
@onready var portal_glow: ColorRect = %PortalGlow

@export var target_scene: String = "res://levels/DungeonFloor.tscn"

var is_player_inside: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("interact"):
		_enter_portal()

func _enter_portal() -> void:
	GameState.start_new_run(GameState.selected_hero_id)
	# В Спринте 2 ведем в хаб / тестовую комнату с обновленным состоянием
	SceneRouter.change_scene(target_scene, 0.4)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_inside = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_inside = false
		prompt_label.visible = false

