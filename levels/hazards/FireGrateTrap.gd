class_name FireGrateTrap
extends Node2D

## Огненная решётка замка: циклическое предупреждение и выброс огня

enum TrapState { OFF, WARNING, BURST }

@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var warning_glow: ColorRect = %WarningGlow
@onready var flames_visual: ColorRect = %FlamesVisual

@export var damage: int = 18
@export var cycle_off_time: float = 2.0
@export var cycle_warning_time: float = 0.6
@export var cycle_burst_time: float = 1.0

var current_state: TrapState = TrapState.OFF
var state_timer: float = 0.0

func _ready() -> void:
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = false
	hitbox.source_owner = self
	hitbox.damage_type = "fire"
	hitbox.tags = ["fire"]
	collision_shape.disabled = true
	
	warning_glow.visible = false
	flames_visual.visible = false
	state_timer = cycle_off_time

func _physics_process(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		match current_state:
			TrapState.OFF:
				_set_state(TrapState.WARNING)
			TrapState.WARNING:
				_set_state(TrapState.BURST)
			TrapState.BURST:
				_set_state(TrapState.OFF)

func _set_state(new_state: TrapState) -> void:
	current_state = new_state
	match current_state:
		TrapState.OFF:
			state_timer = cycle_off_time
			warning_glow.visible = false
			flames_visual.visible = false
			collision_shape.disabled = true
		TrapState.WARNING:
			state_timer = cycle_warning_time
			warning_glow.visible = true
			flames_visual.visible = false
			collision_shape.disabled = true
			var tween: Tween = create_tween()
			tween.tween_property(warning_glow, "modulate:a", 1.0, cycle_warning_time * 0.8)
		TrapState.BURST:
			state_timer = cycle_burst_time
			warning_glow.visible = false
			flames_visual.visible = true
			collision_shape.disabled = false
			hitbox.reset_hits()
			EventBus.screen_shake_requested.emit(3.0, 0.15)
			var tween: Tween = create_tween().set_loops(4)
			tween.tween_property(flames_visual, "modulate", Color(1.8, 1.2, 0.3, 1.0), 0.1)
			tween.tween_property(flames_visual, "modulate", Color.WHITE, 0.1)

