class_name FloorGenerator
extends RefCounted

## Детерминированный процедурный генератор сетки комнат этажа на основе seed

const CARDINAL_DIRS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

func generate_floor(seed_val: int, target_rooms: int = 10) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	target_rooms = clampi(target_rooms, 8, 14)
	var rooms: Dictionary = {} # Vector2i -> RoomData
	
	# 1. Спавним начальную комнату
	var start_pos: Vector2i = Vector2i.ZERO
	var start_room: RoomData = RoomData.new()
	start_room.grid_pos = start_pos
	start_room.room_type = RoomData.RoomType.START
	start_room.is_cleared = true
	start_room.is_visited = true
	start_room.is_discovered = true
	rooms[start_pos] = start_room
	
	# 2. Выращивание связного графа комнат (Growing Tree / Random Walk)
	var active_positions: Array[Vector2i] = [start_pos]
	
	while rooms.size() < target_rooms:
		var current_pos: Vector2i = active_positions[rng.randi_range(0, active_positions.size() - 1)]
		
		# Ищем свободные смежные клетки
		var available_dirs: Array[Vector2i] = []
		for dir in CARDINAL_DIRS:
			var next_pos: Vector2i = current_pos + dir
			if not rooms.has(next_pos):
				available_dirs.append(dir)
		
		if available_dirs.is_empty():
			active_positions.erase(current_pos)
			if active_positions.is_empty():
				active_positions.append(start_pos)
			continue
		
		var chosen_dir: Vector2i = available_dirs[rng.randi_range(0, available_dirs.size() - 1)]
		var new_room_pos: Vector2i = current_pos + chosen_dir
		
		var new_room: RoomData = RoomData.new()
		new_room.grid_pos = new_room_pos
		new_room.room_type = RoomData.RoomType.COMBAT
		rooms[new_room_pos] = new_room
		active_positions.append(new_room_pos)
	
	# 3. Расчёт связности дверей между смежными комнатами
	for pos in rooms.keys():
		var room: RoomData = rooms[pos]
		for dir in CARDINAL_DIRS:
			if rooms.has(pos + dir):
				room.doors[dir] = true
			else:
				room.doors[dir] = false
	
	# 4. BFS для определения расстояний от старта и нахождения самой дальней комнаты (Босс)
	_calculate_bfs_distances(start_pos, rooms)
	
	# 5. Находим самую дальнюю комнату по BFS для Босса
	var max_dist: int = -1
	var boss_pos: Vector2i = start_pos
	for pos in rooms.keys():
		var room: RoomData = rooms[pos]
		if room.distance_from_start > max_dist:
			max_dist = room.distance_from_start
			boss_pos = pos
	
	var boss_room: RoomData = rooms[boss_pos]
	boss_room.room_type = RoomData.RoomType.BOSS
	
	# 6. Распределяем остальные специальные комнаты: Магазин, Сокровищница, Элита
	var candidate_positions: Array[Vector2i] = []
	for pos in rooms.keys():
		if pos != start_pos and pos != boss_pos:
			candidate_positions.append(pos)
	
	# Сортируем кандидатов по детерминированному порядку
	candidate_positions.sort_custom(func(a: Vector2i, b: Vector2i):
		if a.x != b.x:
			return a.x < b.x
		return a.y < b.y
	)
	
	# Перемешиваем через rng
	for i in range(candidate_positions.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = candidate_positions[i]
		candidate_positions[i] = candidate_positions[j]
		candidate_positions[j] = tmp
	
	if candidate_positions.size() > 0:
		rooms[candidate_positions.pop_back()].room_type = RoomData.RoomType.SHOP
	if candidate_positions.size() > 0:
		rooms[candidate_positions.pop_back()].room_type = RoomData.RoomType.TREASURE
	if candidate_positions.size() > 0 and target_rooms >= 10:
		rooms[candidate_positions.pop_back()].room_type = RoomData.RoomType.ELITE
	
	return {
		"rooms": rooms,
		"start_room": start_room,
		"boss_room": boss_room,
		"seed": seed_val
	}

func _calculate_bfs_distances(start_pos: Vector2i, rooms: Dictionary) -> void:
	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = { start_pos: 0 }
	rooms[start_pos].distance_from_start = 0
	
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var cur_dist: int = visited[current]
		
		for dir in CARDINAL_DIRS:
			var neighbor_pos: Vector2i = current + dir
			if rooms.has(neighbor_pos) and not visited.has(neighbor_pos):
				visited[neighbor_pos] = cur_dist + 1
				rooms[neighbor_pos].distance_from_start = cur_dist + 1
				queue.append(neighbor_pos)

func verify_all_rooms_reachable(floor_data: Dictionary) -> bool:
	var rooms: Dictionary = floor_data.get("rooms", {})
	if rooms.is_empty():
		return false
	
	var start_room: RoomData = floor_data.get("start_room")
	if start_room == null:
		return false
	
	var queue: Array[Vector2i] = [start_room.grid_pos]
	var visited: Dictionary = { start_room.grid_pos: true }
	
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		var room: RoomData = rooms[cur]
		for dir in CARDINAL_DIRS:
			if room.doors.get(dir, false):
				var next_pos: Vector2i = cur + dir
				if rooms.has(next_pos) and not visited.has(next_pos):
					visited[next_pos] = true
					queue.append(next_pos)
	
	return visited.size() == rooms.size()
