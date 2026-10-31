class_name EnemyChaseState
extends State

## Состояние преследования игрока с удержанием дистанции для стрелков

func physics_update(delta: float) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null or not is_instance_valid(enemy.player_target):
		state_machine.change_state("idle")
		return
	
	var to_player: Vector2 = enemy.player_target.global_position - enemy.global_position
	var dist: float = to_player.length()
	var attack_range: float = enemy.enemy_data.attack_range if enemy.enemy_data else 40.0
	var preferred_dist: float = enemy.enemy_data.preferred_distance if enemy.enemy_data else 0.0
	
	# Проверка перехода в атаку
	if dist <= attack_range and enemy.attack_timer <= 0.0:
		state_machine.change_state("attack")
		return
	
	# Расчёт вектора движения
	var move_dir: Vector2 = Vector2.ZERO
	if preferred_dist > 0.0:
		# Поведение стрелка: если ближе нужного — отходим, если дальше — подходим
		if dist < preferred_dist - 30.0:
			move_dir = -to_player.normalized()
		elif dist > preferred_dist + 30.0:
			move_dir = to_player.normalized()
		else:
			# Стрейф по окружности
			move_dir = to_player.orthogonal().normalized()
	else:
		# Обычное преследование
		move_dir = to_player.normalized()
	
	enemy.movement_component.move(enemy, move_dir, delta)
