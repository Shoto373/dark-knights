class_name Dummy
extends CharacterBody2D

## Тренировочный манекен для проверки боя, урона и knockback

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var visuals: Node2D = %Visuals
@onready var hp_bar: ProgressBar = %HpBar
@onready var label_hp: Label = %LabelHp

@export var max_hp: int = 150
@export var armor: int = 2

var initial_position: Vector2
var respawn_timer: float = 0.0

func _ready() -> void:
	initial_position = global_position
	collision_layer = 4 # Слой 3: enemies
	collision_mask = 1  # Слой 1: world
	
	health_component.max_health = max_hp
	health_component.reset(max_hp)
	
	hurtbox_component.health_component = health_component
	hurtbox_component.movement_component = movement_component
	hurtbox_component.armor = armor
	hurtbox_component.is_player_hurtbox = false
	
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	_update_hp_bar()

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()
		return
	
	# Применение затухания отталкивания
	movement_component.move(self, Vector2.ZERO, delta)

func _on_damaged(amount: int, current_hp: int, max_health: int) -> void:
	_update_hp_bar()
	_flash()

func _on_died() -> void:
	_update_hp_bar()
	visuals.modulate = Color(0.6, 0.2, 0.2, 0.4)
	respawn_timer = 2.0 # Автоматический респавн через 2 секунды

func _flash() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.0, 0.3, 0.3, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)

func _update_hp_bar() -> void:
	hp_bar.max_value = health_component.max_health
	hp_bar.value = health_component.current_health
	label_hp.text = "%d / %d" % [health_component.current_health, health_component.max_health]

func _respawn() -> void:
	global_position = initial_position
	health_component.reset(max_hp)
	visuals.modulate = Color.WHITE
	_update_hp_bar()
