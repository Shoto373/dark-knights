class_name EnemyAttackState
extends State

## Состояние атаки врага

var windup_timer: float = 0.0

func enter() -> void:
	windup_timer = 0.2 # Телеграфирование удара перед выпадом
	var enemy: EnemyBase = actor as EnemyBase
	if enemy != null:
		enemy.visuals.modulate = Color(2.0, 1.8, 0.4, 1.0)

func physics_update(delta: float) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null:
		return
	
	windup_timer -= delta
	if windup_timer <= 0.0:
		enemy.visuals.modulate = Color.WHITE
		enemy.perform_attack()
		state_machine.change_state("chase")

func exit() -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy != null:
		enemy.visuals.modulate = Color.WHITE
