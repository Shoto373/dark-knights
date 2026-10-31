class_name WaveSpawner
extends RefCounted

## Генератор волн врагов на основе биома и бюджета сложности комнаты (Data-Driven)

const ENEMY_BASE_SCENE = preload("res://entities/enemies/EnemyBase.tscn")
const GOBLIN_BOSS_SCENE = preload("res://entities/bosses/GoblinBoss.tscn")
const TROLL_BOSS_SCENE = preload("res://entities/bosses/TrollKingBoss.tscn")

var default_slasher: EnemyData = preload("res://data/enemies/goblin_slasher.tres")
var default_archer: EnemyData = preload("res://data/enemies/goblin_archer.tres")
var default_shaman: EnemyData = preload("res://data/enemies/goblin_shaman.tres")
var default_brute: EnemyData = preload("res://data/enemies/goblin_brute.tres")

func spawn_room_enemies(room: DungeonRoom, room_data: RoomData, biome: BiomeData = null) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	if biome == null:
		biome = GameState.get_current_biome()
	
	match room_data.room_type:
		RoomData.RoomType.BOSS:
			var boss_node: Node2D = null
			if biome != null:
				if biome.boss_scene != null:
					boss_node = biome.boss_scene.instantiate() as Node2D
				elif not biome.boss_scene_path.is_empty() and ResourceLoader.exists(biome.boss_scene_path):
					var loaded_scene: PackedScene = load(biome.boss_scene_path) as PackedScene
					if loaded_scene != null:
						boss_node = loaded_scene.instantiate() as Node2D
			
			if boss_node == null:
				if biome != null and biome.id == "troll_gorge":
					boss_node = TROLL_BOSS_SCENE.instantiate() as Node2D
				else:
					boss_node = GOBLIN_BOSS_SCENE.instantiate() as Node2D
					
			room.enemies_container.add_child(boss_node)
			boss_node.position = Vector2(640, 360)
			spawned.append(boss_node)
		
		RoomData.RoomType.ELITE:
			var elite_data: EnemyData = default_brute
			if biome != null and biome.elite_enemy != null:
				elite_data = biome.elite_enemy
			
			var elite: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
			room.enemies_container.add_child(elite)
			elite.position = Vector2(640, 360)
			elite.setup_from_data(elite_data)
			spawned.append(elite)
			
			# Поддержка элиты
			var support_data: EnemyData = default_archer
			if biome != null and not biome.enemy_pool.is_empty():
				support_data = biome.enemy_pool[GameState.rng.randi_range(0, biome.enemy_pool.size() - 1)]
				
			var support: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
			room.enemies_container.add_child(support)
			support.position = Vector2(480, 260)
			support.setup_from_data(support_data)
			spawned.append(support)
			
		RoomData.RoomType.COMBAT:
			var budget: int = clampi(3 + int(room_data.distance_from_start / 2), 3, 7)
			var spawn_points: Array[Vector2] = [
				Vector2(400, 260),
				Vector2(880, 260),
				Vector2(400, 460),
				Vector2(880, 460),
				Vector2(640, 360),
				Vector2(320, 360),
				Vector2(960, 360)
			]
			var pt_idx: int = 0
			var pool: Array[EnemyData] = biome.enemy_pool if (biome != null and not biome.enemy_pool.is_empty()) else [default_slasher, default_archer, default_shaman, default_brute]
			
			while budget > 0 and pt_idx < spawn_points.size():
				var candidate: EnemyData = pool[GameState.rng.randi_range(0, pool.size() - 1)]
				if candidate.difficulty_cost > budget and budget < 2:
					# Если не хватает на дорогого врага, берем самого легкого
					candidate = pool[0]
				
				var enemy_inst: EnemyBase = ENEMY_BASE_SCENE.instantiate() as EnemyBase
				room.enemies_container.add_child(enemy_inst)
				enemy_inst.position = spawn_points[pt_idx % spawn_points.size()]
				pt_idx += 1
				
				enemy_inst.setup_from_data(candidate)
				budget -= max(1, candidate.difficulty_cost)
				spawned.append(enemy_inst)
	
	return spawned
