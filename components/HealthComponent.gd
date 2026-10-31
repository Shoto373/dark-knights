class_name HealthComponent
extends Node

## Компонент здоровья сущности

signal damaged(amount: int, current_hp: int, max_hp: int)
signal healed(amount: int, current_hp: int, max_hp: int)
signal died

@export var max_health: int = 100:
	set(val):
		max_health = maxi(1, val)
		if current_health > max_health:
			current_health = max_health

var current_health: int = 100
var is_invulnerable: bool = false
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> int:
	if is_invulnerable or is_dead or amount <= 0:
		return 0
	
	var actual_damage: int = mini(amount, current_health)
	current_health = maxi(0, current_health - actual_damage)
	damaged.emit(actual_damage, current_health, max_health)
	
	if current_health <= 0 and not is_dead:
		is_dead = true
		died.emit()
	
	return actual_damage

func heal(amount: int) -> int:
	if is_dead or amount <= 0 or current_health >= max_health:
		return 0
	
	var actual_heal: int = mini(amount, max_health - current_health)
	current_health = mini(max_health, current_health + actual_heal)
	healed.emit(actual_heal, current_health, max_health)
	return actual_heal

func set_invulnerable(value: bool) -> void:
	is_invulnerable = value

func reset(health_value: int = -1) -> void:
	if health_value > 0:
		max_health = health_value
	current_health = max_health
	is_dead = false
	is_invulnerable = false

