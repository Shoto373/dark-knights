class_name EnemyAttackState
extends State

## Состояние атаки врага

var windup_timer: float = 0.0

func enter() -> void:
	windup_timer = 0.22 # Телеграфирование замаха перед выпадом
	var enemy: EnemyBase = actor as EnemyBase
	if enemy != null:
		enemy.visuals.modulate = Color(2.4, 1.6, 0.4, 1.0)
		var sq_tween: Tween = enemy.visuals.create_tween()
		sq_tween.tween_property(enemy.visuals, "scale:y", 0.78, 0.16).set_trans(Tween.TRANS_QUAD)

func physics_update(delta: float) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null:
		return
	
	windup_timer -= delta
	if windup_timer <= 0.0:
		enemy.visuals.modulate = Color.WHITE
		enemy.visuals.scale.y = 1.0
		enemy.perform_attack()
		state_machine.change_state("chase")

func exit() -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy != null:
		enemy.visuals.modulate = Color.WHITE
		enemy.visuals.scale.y = 1.0

