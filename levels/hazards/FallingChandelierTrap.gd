class_name FallingChandelierTrap
extends Node2D

## Падающая люстра замка: предупреждающий круг на полу, сокрушительное падение при приближении

signal chandelier_fallen

@onready var trigger_area: Area2D = %TriggerArea
@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var impact_shape: CollisionShape2D = %ImpactShape
@onready var telegraph_shadow: ColorRect = %TelegraphShadow
@onready var chandelier_visual: Node2D = %ChandelierVisual

@export var damage: int = 30
@export var trigger_radius: float = 110.0

var is_triggered: bool = false
var has_fallen: bool = false

func _ready() -> void:
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = false
	hitbox.source_owner = self
	hitbox.knockback_force = 350.0
	impact_shape.disabled = true
	
	trigger_area.body_entered.connect(_on_trigger_body_entered)
	chandelier_visual.position = Vector2(0, -180.0)

func _on_trigger_body_entered(body: Node2D) -> void:
	if has_fallen or is_triggered:
		return
	if (body is CharacterBody2D and body.is_in_group("player")) or (body is Player):
		_trigger_fall()

func _trigger_fall() -> void:
	is_triggered = true
	
	# Предупреждающее мигание тени на полу (телеграф)
	var tween: Tween = create_tween()
	telegraph_shadow.color = Color(1.0, 0.2, 0.1, 0.8)
	tween.tween_property(telegraph_shadow, "scale", Vector2(1.3, 1.3), 0.35)
	tween.tween_callback(_drop_chandelier)

func _drop_chandelier() -> void:
	var drop_tween: Tween = create_tween()
	drop_tween.tween_property(chandelier_visual, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop_tween.tween_callback(_on_impact)

func _on_impact() -> void:
	has_fallen = true
	impact_shape.disabled = false
	hitbox.reset_hits()
	
	EventBus.screen_shake_requested.emit(10.0, 0.3)
	chandelier_fallen.emit()
	
	# Разлёт осколков и остаточная груда металла
	telegraph_shadow.visible = false
	var shatter_tween: Tween = create_tween()
	chandelier_visual.scale = Vector2(1.5, 0.6)
	shatter_tween.tween_interval(0.1)
	shatter_tween.tween_callback(func(): impact_shape.disabled = true)
