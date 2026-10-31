class_name EnemyIdleState
extends State

## Состояние покоя врага

func physics_update(_delta: float) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null or not is_instance_valid(enemy.player_target):
		return
	
	var dist: float = (enemy.player_target.global_position - enemy.global_position).length()
	if dist <= 500.0:
		state_machine.change_state("chase")
