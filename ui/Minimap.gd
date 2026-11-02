class_name Minimap
extends Control

## Мини-карта подземелья с динамическим превью соседних комнат (Isaac / Gungeon style)
## Отображает архитектурные типы комнат (Boss, Treasure, Shop, Elite) для разведанных соседних локаций

@export var cell_size: Vector2 = Vector2(22, 16)
@export var cell_spacing: Vector2 = Vector2(6, 6)

var rooms_data: Dictionary = {} # Vector2i -> RoomData
var current_room_pos: Vector2i = Vector2i.ZERO
var _anim_time: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(170, 130)
	EventBus.room_entered.connect(_on_room_entered)

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func setup_minimap(rooms: Dictionary, start_pos: Vector2i) -> void:
	rooms_data = rooms
	current_room_pos = start_pos
	_update_discovery(start_pos)
	queue_redraw()

func _on_room_entered(data: Dictionary) -> void:
	var pos: Vector2i = data.get("grid_pos", Vector2i.ZERO)
	current_room_pos = pos
	_update_discovery(pos)
	queue_redraw()

func _update_discovery(pos: Vector2i) -> void:
	if rooms_data.has(pos):
		var cur: RoomData = rooms_data[pos]
		cur.is_visited = true
		cur.is_discovered = true
		
		# Открываем видимость смежных комнат (разведка соседних помещений)
		for dir in FloorGenerator.CARDINAL_DIRS:
			if cur.doors.get(dir, false) and rooms_data.has(pos + dir):
				rooms_data[pos + dir].is_discovered = true

func _draw() -> void:
	if rooms_data.is_empty():
		return
	
	# Центрируем мини-карту относительно текущей комнаты
	var center_offset: Vector2 = size / 2.0
	var step: Vector2 = cell_size + cell_spacing
	
	# 1. Рисуем коридоры / соединительные линии дверей
	for pos in rooms_data.keys():
		var room: RoomData = rooms_data[pos]
		if not room.is_discovered:
			continue
		
		var room_center: Vector2 = center_offset + Vector2(pos - current_room_pos) * step
		
		for dir in [Vector2i.RIGHT, Vector2i.DOWN]:
			if room.doors.get(dir, false) and rooms_data.has(pos + dir):
				var neighbor: RoomData = rooms_data[pos + dir]
				if neighbor.is_discovered:
					var neighbor_center: Vector2 = center_offset + Vector2((pos + dir) - current_room_pos) * step
					var line_col: Color = _get_connection_color(room, neighbor)
					draw_line(room_center, neighbor_center, line_col, 2.5)
	
	# 2. Рисуем ячейки комнат
	for pos in rooms_data.keys():
		var room: RoomData = rooms_data[pos]
		if not room.is_discovered:
			continue
		
		var room_center: Vector2 = center_offset + Vector2(pos - current_room_pos) * step
		var rect: Rect2 = Rect2(room_center - cell_size / 2.0, cell_size)
		
		var is_current: bool = (pos == current_room_pos)
		var is_visited: bool = room.is_visited
		
		# Заливка ячейки
		var fill_color: Color = _get_room_color(room)
		draw_rect(rect, fill_color, true)
		
		# Контур / рамка ячейки
		var border_color: Color = _get_room_border_color(room, is_current)
		var border_width: float = 2.5 if is_current else (2.0 if (not is_visited and _is_special_room(room)) else 1.2)
		draw_rect(rect, border_color, false, border_width)
		
		# Значок/герб типа комнаты (отображается для ВСЕХ открытых комнат, включая соседние еще не посещенные!)
		_draw_room_icon(room_center, room, is_visited)
		
		# Маркер позиции игрока в текущей комнате
		if is_current:
			var player_pulse: float = 1.0 + sin(_anim_time * 6.0) * 0.2
			draw_circle(room_center, 4.0 * player_pulse, Color(0.2, 0.9, 1.0, 0.45))
			draw_circle(room_center, 2.5, Color.WHITE)

func _is_special_room(room: RoomData) -> bool:
	return room.room_type in [RoomData.RoomType.BOSS, RoomData.RoomType.TREASURE, RoomData.RoomType.SHOP, RoomData.RoomType.ELITE]

func _get_room_color(room: RoomData) -> Color:
	if room.is_visited:
		match room.room_type:
			RoomData.RoomType.START:
				return Color(0.22, 0.65, 0.88, 1.0) # Лазурный
			RoomData.RoomType.TREASURE:
				return Color(0.95, 0.82, 0.22, 1.0) # Золотой
			RoomData.RoomType.SHOP:
				return Color(0.28, 0.85, 0.45, 1.0) # Изумрудный
			RoomData.RoomType.ELITE:
				return Color(0.72, 0.32, 0.88, 1.0) # Аметистовый
			RoomData.RoomType.BOSS:
				return Color(0.85, 0.22, 0.28, 1.0) # Багровый
			_:
				return Color(0.38, 0.44, 0.52, 1.0) # Стальной
	else:
		# Превью для соседней разведанной, но еще не посещенной комнаты!
		match room.room_type:
			RoomData.RoomType.START:
				return Color(0.1, 0.3, 0.42, 0.9)
			RoomData.RoomType.TREASURE:
				return Color(0.45, 0.36, 0.08, 0.92) # Темное золото
			RoomData.RoomType.SHOP:
				return Color(0.1, 0.38, 0.18, 0.92) # Темный изумруд
			RoomData.RoomType.ELITE:
				return Color(0.35, 0.12, 0.45, 0.92) # Темный фиолетовый
			RoomData.RoomType.BOSS:
				return Color(0.48, 0.1, 0.14, 0.92) # Темный багрянец
			_:
				return Color(0.18, 0.22, 0.28, 0.85) # Темный сланец

func _get_room_border_color(room: RoomData, is_current: bool) -> Color:
	if is_current:
		var pulse: float = 0.85 + sin(_anim_time * 5.0) * 0.15
		return Color(1.0, 1.0, 1.0, pulse)
	
	if not room.is_visited:
		# Яркий узнаваемый контур у соседних особых комнат
		match room.room_type:
			RoomData.RoomType.BOSS:
				return Color(1.0, 0.25, 0.3, 0.95)
			RoomData.RoomType.TREASURE:
				return Color(1.0, 0.88, 0.25, 0.95)
			RoomData.RoomType.SHOP:
				return Color(0.35, 1.0, 0.55, 0.95)
			RoomData.RoomType.ELITE:
				return Color(0.85, 0.45, 1.0, 0.95)
			_:
				return Color(0.35, 0.42, 0.52, 0.85)
				
	return Color(0.22, 0.26, 0.34, 0.95)

func _get_connection_color(r1: RoomData, r2: RoomData) -> Color:
	# Если проход ведет в особую не посещенную комнату, подсвечиваем коридор
	var target: RoomData = r2 if not r2.is_visited else (r1 if not r1.is_visited else null)
	if target != null:
		match target.room_type:
			RoomData.RoomType.BOSS:
				return Color(0.9, 0.2, 0.25, 0.9)
			RoomData.RoomType.TREASURE:
				return Color(0.95, 0.85, 0.25, 0.9)
			RoomData.RoomType.SHOP:
				return Color(0.3, 0.9, 0.5, 0.9)
			RoomData.RoomType.ELITE:
				return Color(0.8, 0.4, 0.95, 0.9)
	return Color(0.35, 0.4, 0.48, 0.75)

func _draw_room_icon(center: Vector2, room: RoomData, is_visited: bool) -> void:
	var pulse: float = 1.0 if is_visited else (0.75 + sin(_anim_time * 3.8) * 0.25)
	
	match room.room_type:
		RoomData.RoomType.BOSS:
			_draw_boss_icon(center, is_visited, pulse)
		RoomData.RoomType.TREASURE:
			_draw_treasure_icon(center, is_visited, pulse)
		RoomData.RoomType.SHOP:
			_draw_shop_icon(center, is_visited, pulse)
		RoomData.RoomType.ELITE:
			_draw_elite_icon(center, is_visited, pulse)
		RoomData.RoomType.START:
			_draw_start_icon(center, is_visited)
		RoomData.RoomType.COMBAT:
			_draw_combat_icon(center, is_visited)

func _draw_boss_icon(center: Vector2, is_visited: bool, pulse: float) -> void:
	var skull_col: Color = Color(1.0, 0.85, 0.85, pulse) if not is_visited else Color(0.2, 0.05, 0.05)
	var horn_col: Color = Color(1.0, 0.2, 0.25, pulse) if not is_visited else Color(0.5, 0.1, 0.1)
	
	# Череп с рогами
	draw_circle(center + Vector2(0, -1), 3.5, skull_col)
	draw_rect(Rect2(center.x - 2.0, center.y + 1, 4.0, 2.5), skull_col)
	# Глазницы
	var eye_col: Color = Color(0.9, 0.1, 0.15) if not is_visited else Color(1.0, 0.4, 0.4)
	draw_circle(center + Vector2(-1.3, -1), 0.9, eye_col)
	draw_circle(center + Vector2(1.3, -1), 0.9, eye_col)
	# Изогнутые рога босса
	draw_line(center + Vector2(-2.5, -2), center + Vector2(-4.5, -5), horn_col, 1.4)
	draw_line(center + Vector2(2.5, -2), center + Vector2(4.5, -5), horn_col, 1.4)

func _draw_treasure_icon(center: Vector2, is_visited: bool, pulse: float) -> void:
	var gold_col: Color = Color(1.0, 0.9, 0.25, pulse) if not is_visited else Color(0.3, 0.22, 0.02)
	# Сундук с золотом
	draw_rect(Rect2(center.x - 4, center.y - 1.5, 8, 4.5), gold_col)
	draw_rect(Rect2(center.x - 4.5, center.y - 3.5, 9, 2.0), gold_col.lightened(0.2))
	# Замочная скважина / самоцвет
	var gem_col: Color = Color(0.2, 0.9, 1.0) if not is_visited else Color(1.0, 0.9, 0.5)
	draw_circle(center + Vector2(0, 0.5), 1.0, gem_col)

func _draw_shop_icon(center: Vector2, is_visited: bool, pulse: float) -> void:
	var coin_col: Color = Color(1.0, 0.85, 0.2, pulse) if not is_visited else Color(0.12, 0.3, 0.15)
	draw_circle(center, 4.0, coin_col)
	draw_circle(center, 3.0, coin_col.darkened(0.3))
	var sym_col: Color = Color(0.15, 0.1, 0.02) if not is_visited else Color(0.85, 1.0, 0.85)
	draw_string(ThemeDB.fallback_font, center + Vector2(-2.2, 2.5), "$", HORIZONTAL_ALIGNMENT_CENTER, -1, 7, sym_col)

func _draw_elite_icon(center: Vector2, is_visited: bool, pulse: float) -> void:
	var sword_col: Color = Color(0.9, 0.45, 1.0, pulse) if not is_visited else Color(0.25, 0.1, 0.3)
	draw_line(center + Vector2(-3.5, -3.5), center + Vector2(3.5, 3.5), sword_col, 1.4)
	draw_line(center + Vector2(3.5, -3.5), center + Vector2(-3.5, 3.5), sword_col, 1.4)
	draw_circle(center, 1.2, Color.WHITE)

func _draw_start_icon(center: Vector2, is_visited: bool) -> void:
	var ring_col: Color = Color(0.3, 0.85, 1.0) if not is_visited else Color(0.1, 0.2, 0.35)
	draw_arc(center, 3.5, 0.0, TAU, 12, ring_col, 1.4)
	draw_circle(center, 1.5, Color.WHITE if is_visited else ring_col)

func _draw_combat_icon(center: Vector2, is_visited: bool) -> void:
	if not is_visited:
		# Тонкая точка в неисследованной боевой комнате
		draw_circle(center, 1.8, Color(0.65, 0.72, 0.82, 0.6))
	else:
		# В очищенной комнате — деликатная точка покоя
		draw_circle(center, 1.2, Color(0.25, 0.3, 0.38, 0.8))
