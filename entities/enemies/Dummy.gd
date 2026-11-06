class_name Dummy
extends CharacterBody2D

## Тренировочный манекен с реакцией на попадания, соломенными искрами и физикой удара

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var visuals: Node2D = %Visuals
@onready var hp_bar: ProgressBar = %HpBar
@onready var label_hp: Label = %LabelHp
@onready var dummy_sprite: Sprite2D = %DummySprite

@export var max_hp: int = 150
@export var armor: int = 2

var initial_position: Vector2
var respawn_timer: float = 0.0

func _ready() -> void:
	initial_position = global_position
	collision_layer = 4 # Слой 3: enemies
	collision_mask = 1  # Слой 1: world
	
	if health_component != null:
		health_component.max_health = max_hp
		health_component.reset(max_hp)
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
	
	if hurtbox_component != null:
		hurtbox_component.health_component = health_component
		hurtbox_component.movement_component = movement_component
		hurtbox_component.armor = armor
		hurtbox_component.is_player_hurtbox = false
	
	var tex: Texture2D = SpriteGenerator.get_target_dummy_texture()
	if tex != null and dummy_sprite != null:
		dummy_sprite.texture = tex
	
	_update_hp_bar()

func _physics_process(delta: float) -> void:
	if is_instance_valid(health_component) and health_component.is_dead:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()
		return
	
	# Применение затухания отталкивания
	if is_instance_valid(movement_component):
		movement_component.move(self, Vector2.ZERO, delta)

func _on_damaged(amount: int, current_hp: int, max_health: int) -> void:
	_update_hp_bar()
	_flash_and_wobble()
	EffectsHelper.spawn_straw_puff(get_parent(), global_position, 6)

func _on_died() -> void:
	_update_hp_bar()
	visuals.modulate = Color(0.6, 0.2, 0.2, 0.4)
	EffectsHelper.spawn_straw_puff(get_parent(), global_position, 12)
	respawn_timer = 2.0 # Автоматический респавн через 2 секунды

func _flash_and_wobble() -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.0, 0.4, 0.4, 1.0)
	visuals.scale = Vector2(1.28, 0.76)
	tween.tween_property(visuals, "scale", Vector2(0.88, 1.15), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.12)
	tween.parallel().tween_property(visuals, "modulate", Color.WHITE, 0.15)

func _update_hp_bar() -> void:
	if hp_bar != null and health_component != null:
		hp_bar.max_value = health_component.max_health
		hp_bar.value = health_component.current_health
	if label_hp != null and health_component != null:
		label_hp.text = "%d / %d" % [health_component.current_health, health_component.max_health]

func _respawn() -> void:
	global_position = initial_position
	health_component.reset(max_hp)
	visuals.modulate = Color.WHITE
	visuals.scale = Vector2.ONE
	_update_hp_bar()
