class_name WaveSpawner
extends RefCounted

## Генератор волн врагов на основе бюджета сложности комнаты

const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const BOSS_SCENE = preload("res://entities/bosses/GoblinBoss.tscn")

var slasher_data: EnemyData = preload("res://data/enemies/goblin_slasher.tres")
var archer_data: EnemyData = preload("res://data/enemies/goblin_archer.tres")
var shaman_data: EnemyData = preload("res://data/enemies/goblin_shaman.tres")
var brute_data: EnemyData = preload("res://data/enemies/goblin_brute.tres")

func spawn_room_enemies(room: DungeonRoom, room_data: RoomData) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	
	match room_data.room_type:
		RoomData.RoomType.BOSS:
			var boss: GoblinBoss = BOSS_SCENE.instantiate() as GoblinBoss
			room.enemies_container.add_child(boss)
			boss.position = Vector2(640, 360)
			spawned.append(boss)
		
		RoomData.RoomType.ELITE:
			# Спавним громилу и поддержку
			var brute: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
			room.enemies_container.add_child(brute)
			brute.position = Vector2(640, 360)
			brute.setup_from_data(brute_data)
			spawned.append(brute)
			
			var archer: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
			room.enemies_container.add_child(archer)
			archer.position = Vector2(480, 260)
			archer.setup_from_data(archer_data)
			spawned.append(archer)
			
		RoomData.RoomType.COMBAT:
			var budget: int = clampi(3 + int(room_data.distance_from_start / 2), 3, 6)
			var spawn_points: Array[Vector2] = [
				Vector2(400, 260),
				Vector2(880, 260),
				Vector2(400, 460),
				Vector2(880, 460),
				Vector2(640, 360)
			]
			var pt_idx: int = 0
			
			# Гарантируем одного шамана если бюджет >= 5
			if budget >= 5:
				var shaman: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
				room.enemies_container.add_child(shaman)
				shaman.position = spawn_points[pt_idx % spawn_points.size()]
				pt_idx += 1
				shaman.setup_from_data(shaman_data)
				spawned.append(shaman)
				budget -= shaman_data.difficulty_cost
			
			while budget > 0 and pt_idx < spawn_points.size():
				var enemy_inst: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
				room.enemies_container.add_child(enemy_inst)
				enemy_inst.position = spawn_points[pt_idx % spawn_points.size()]
				pt_idx += 1
				
				if pt_idx % 2 == 0 and budget >= archer_data.difficulty_cost:
					enemy_inst.setup_from_data(archer_data)
					budget -= archer_data.difficulty_cost
				else:
					enemy_inst.setup_from_data(slasher_data)
					budget -= slasher_data.difficulty_cost
				spawned.append(enemy_inst)
	
	return spawned
