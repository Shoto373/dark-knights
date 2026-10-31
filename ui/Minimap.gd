class_name Minimap
extends Control

## Мини-карта подземелья

@export var cell_size: Vector2 = Vector2(18, 14)
@export var cell_spacing: Vector2 = Vector2(6, 6)

var rooms_data: Dictionary = {} # Vector2i -> RoomData
var current_room_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(160, 120)
	EventBus.room_entered.connect(_on_room_entered)

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
		
		# Открываем видимость смежных комнат
		for dir in FloorGenerator.CARDINAL_DIRS:
			if cur.doors.get(dir, false) and rooms_data.has(pos + dir):
				rooms_data[pos + dir].is_discovered = true

func _draw() -> void:
	if rooms_data.is_empty():
		return
	
	# Центрируем мини-карту относительно текущей комнаты
	var center_offset: Vector2 = size / 2.0
	var step: Vector2 = cell_size + cell_spacing
	
	# Рисуем линии соединения дверей
	for pos in rooms_data.keys():
		var room: RoomData = rooms_data[pos]
		if not room.is_discovered:
			continue
		
		var room_center: Vector2 = center_offset + Vector2(pos - current_room_pos) * step
		
		for dir in [Vector2i.RIGHT, Vector2i.DOWN]:
			if room.doors.get(dir, false) and rooms_data.has(pos + dir) and rooms_data[pos + dir].is_discovered:
				var neighbor_center: Vector2 = center_offset + Vector2((pos + dir) - current_room_pos) * step
				draw_line(room_center, neighbor_center, Color(0.4, 0.45, 0.55, 0.8), 2.0)
	
	# Рисуем ячейки комнат
	for pos in rooms_data.keys():
		var room: RoomData = rooms_data[pos]
		if not room.is_discovered:
			continue
		
		var room_center: Vector2 = center_offset + Vector2(pos - current_room_pos) * step
		var rect: Rect2 = Rect2(room_center - cell_size / 2.0, cell_size)
		
		var fill_color: Color = _get_room_color(room)
		draw_rect(rect, fill_color, true)
		
		# Обводка
		var border_color: Color = Color.WHITE if pos == current_room_pos else Color(0.2, 0.25, 0.35, 1.0)
		var border_width: float = 2.0 if pos == current_room_pos else 1.0
		draw_rect(rect, border_color, false, border_width)

func _get_room_color(room: RoomData) -> Color:
	if not room.is_visited:
		return Color(0.25, 0.28, 0.35, 0.7)
	
	match room.room_type:
		RoomData.RoomType.START:
			return Color(0.2, 0.6, 0.85, 1.0)
		RoomData.RoomType.TREASURE:
			return Color(0.95, 0.8, 0.2, 1.0)
		RoomData.RoomType.SHOP:
			return Color(0.3, 0.8, 0.4, 1.0)
		RoomData.RoomType.ELITE:
			return Color(0.7, 0.3, 0.8, 1.0)
		RoomData.RoomType.BOSS:
			return Color(0.85, 0.2, 0.25, 1.0)
		_:
			return Color(0.45, 0.5, 0.58, 1.0)

