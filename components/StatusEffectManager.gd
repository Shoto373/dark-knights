class_name StatusEffectManager
extends Node

## Менеджер статус-эффектов: заморозка, обледенение, горение, яд, оглушение

signal effect_applied(effect_id: String, stacks: int)
signal effect_expired(effect_id: String)
signal frozen_state_changed(is_frozen: bool)
signal stun_state_changed(is_stunned: bool)

@export var health_component: HealthComponent
@export var movement_component: MovementComponent
@export var visuals: Node2D
@export var immunities: Array[String] = []

var active_effects: Dictionary = {} # effect_id -> { "effect": StatusEffect, "stacks": int, "time_left": float, "tick_timer": float }
var is_processing_dot: bool = false

func _ready() -> void:
	if health_component == null:
		health_component = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if movement_component == null:
		movement_component = get_parent().get_node_or_null("MovementComponent") as MovementComponent
	if visuals == null:
		visuals = get_parent().get_node_or_null("Visuals") as Node2D

func apply_effect(effect: StatusEffect, initial_stacks: int = 1) -> void:
	if effect == null:
		return
	if immunities.has(effect.id):
		return # Иммунитет к данному типу эффекта
	
	if active_effects.has(effect.id):
		var entry: Dictionary = active_effects[effect.id]
		entry["time_left"] = effect.duration
		entry["stacks"] = mini(entry["stacks"] + initial_stacks, effect.max_stacks)
	else:
		active_effects[effect.id] = {
			"effect": effect,
			"stacks": initial_stacks,
			"time_left": effect.duration,
			"tick_timer": 0.0
		}
	
	var current_stacks: int = active_effects[effect.id]["stacks"]
	effect_applied.emit(effect.id, current_stacks)
	
	if effect.id == "freeze" and current_stacks >= 3:
		frozen_state_changed.emit(true)
	elif effect.id == "stun":
		stun_state_changed.emit(true)
		
	_update_visual_tint()

func _physics_process(delta: float) -> void:
	process_effects(delta)

func process_effects(delta: float) -> void:
	var expired_ids: Array[String] = []
	
	for effect_id in active_effects.keys():
		var entry: Dictionary = active_effects[effect_id]
		var effect: StatusEffect = entry["effect"]
		
		entry["time_left"] -= delta
		
		# Периодический урон (горение, яд)
		if effect.damage_per_tick > 0 and effect.tick_interval > 0.0:
			entry["tick_timer"] += delta
			while entry["tick_timer"] >= effect.tick_interval:
				entry["tick_timer"] -= effect.tick_interval
				var tick_dmg: int = effect.damage_per_tick * entry["stacks"]
				if health_component != null and not health_component.is_dead:
					is_processing_dot = true
					health_component.take_damage(tick_dmg, true)
					is_processing_dot = false
		
		if entry["time_left"] <= 0.0:
			expired_ids.append(effect_id)
	
	for effect_id in expired_ids:
		_remove_effect(effect_id)

func _remove_effect(effect_id: String) -> void:
	if active_effects.has(effect_id):
		active_effects.erase(effect_id)
		effect_expired.emit(effect_id)
		
		if effect_id == "freeze":
			frozen_state_changed.emit(false)
		elif effect_id == "stun":
			stun_state_changed.emit(false)
			
		_update_visual_tint()

func _update_visual_tint() -> void:
	if visuals == null:
		return
	
	if is_frozen():
		visuals.modulate = Color(0.4, 1.2, 2.5, 1.0) # Замороженная ледяная глыба
	elif has_effect("freeze"):
		visuals.modulate = Color(0.7, 0.9, 1.4, 1.0) # Замедление льдом
	elif has_effect("burn"):
		visuals.modulate = Color(2.5, 0.8, 0.2, 1.0) # Горение
	elif has_effect("poison"):
		visuals.modulate = Color(0.4, 2.2, 0.6, 1.0) # Яд
	elif has_effect("stun"):
		visuals.modulate = Color(2.0, 2.0, 0.4, 1.0) # Оглушение
	else:
		visuals.modulate = Color.WHITE

func has_effect(effect_id: String) -> bool:
	return active_effects.has(effect_id)

func get_stacks(effect_id: String) -> int:
	if active_effects.has(effect_id):
		return active_effects[effect_id]["stacks"]
	return 0

func get_time_left(effect_id: String) -> float:
	if active_effects.has(effect_id):
		return active_effects[effect_id]["time_left"]
	return 0.0

func is_frozen() -> bool:
	return get_stacks("freeze") >= 3

func is_stunned() -> bool:
	return has_effect("stun") or is_frozen()

func get_speed_multiplier() -> float:
	if is_frozen() or is_stunned():
		return 0.0
	if has_effect("freeze"):
		var stacks: int = get_stacks("freeze")
		return clampf(1.0 - (stacks * 0.25), 0.2, 0.75)
	return 1.0

func clear_all_effects() -> void:
	var ids: Array = active_effects.keys()
	for id in ids:
		_remove_effect(id)
