extends GutTest

func test_100_consecutive_generations_without_unreachable_rooms() -> void:
	var generator: FloorGenerator = FloorGenerator.new()
	
	for i in range(100):
		var test_seed: int = 1000 + i * 37
		var floor_data: Dictionary = generator.generate_floor(test_seed, 10)
		
		var rooms: Dictionary = floor_data["rooms"]
		var room_count: int = rooms.size()
		
		# Проверка размера этажа
		assert_gte(room_count, 8, "Floor %d: room count should be >= 8 (got %d)" % [i, room_count])
		assert_lte(room_count, 14, "Floor %d: room count should be <= 14 (got %d)" % [i, room_count])
		
		# Проверка связности: все комнаты достижимы из старта
		var all_reachable: bool = generator.verify_all_rooms_reachable(floor_data)
		assert_true(all_reachable, "Floor %d (seed: %d): all rooms must be reachable from start" % [i, test_seed])
		
		# Проверка босса
		var boss_room: RoomData = floor_data["boss_room"]
		assert_not_null(boss_room, "Boss room must exist")
		assert_eq(boss_room.room_type, RoomData.RoomType.BOSS, "Boss room must have BOSS type")
		
		# Босс должен быть самой дальней (или одной из самых дальних) комнат
		for pos in rooms.keys():
			var room: RoomData = rooms[pos]
			assert_lte(room.distance_from_start, boss_room.distance_from_start,
				"No room should be strictly further than the boss room")

func test_seed_determinism() -> void:
	var generator: FloorGenerator = FloorGenerator.new()
	var test_seed: int = 987654321
	
	var gen1: Dictionary = generator.generate_floor(test_seed, 11)
	var gen2: Dictionary = generator.generate_floor(test_seed, 11)
	
	var rooms1: Dictionary = gen1["rooms"]
	var rooms2: Dictionary = gen2["rooms"]
	
	assert_eq(rooms1.size(), rooms2.size(), "Deterministic generation: same room count")
	assert_eq(gen1["boss_room"].grid_pos, gen2["boss_room"].grid_pos, "Same boss room position")
	
	# Проверка идентичности всех комнат и дверей
	for pos in rooms1.keys():
		assert_true(rooms2.has(pos), "Deterministic generation: position %s exists in both" % str(pos))
		var r1: RoomData = rooms1[pos]
		var r2: RoomData = rooms2[pos]
		assert_eq(r1.room_type, r2.room_type, "Room type matches for %s" % str(pos))
		assert_eq(r1.doors, r2.doors, "Doors match for %s" % str(pos))

func test_required_room_types_present() -> void:
	var generator: FloorGenerator = FloorGenerator.new()
	var floor_data: Dictionary = generator.generate_floor(42, 10)
	var rooms: Dictionary = floor_data["rooms"]
	
	var has_start: bool = false
	var has_boss: bool = false
	var has_shop: bool = false
	var has_treasure: bool = false
	
	for pos in rooms.keys():
		var room: RoomData = rooms[pos]
		match room.room_type:
			RoomData.RoomType.START: has_start = true
			RoomData.RoomType.BOSS: has_boss = true
			RoomData.RoomType.SHOP: has_shop = true
			RoomData.RoomType.TREASURE: has_treasure = true
	
	assert_true(has_start, "Floor must have START room")
	assert_true(has_boss, "Floor must have BOSS room")
	assert_true(has_shop, "Floor must have SHOP room")
	assert_true(has_treasure, "Floor must have TREASURE room")

func test_dungeon_floor_scene_instantiation() -> void:
	var floor_scene: PackedScene = load("res://levels/DungeonFloor.tscn")
	assert_not_null(floor_scene, "DungeonFloor scene should load")
	var instance: Node = floor_scene.instantiate()
	assert_not_null(instance, "DungeonFloor instance should be created")
	add_child_autofree(instance)
	assert_true(instance.is_inside_tree(), "DungeonFloor is inside tree")

