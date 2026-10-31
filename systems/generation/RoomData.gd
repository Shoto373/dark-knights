class_name RoomData
extends RefCounted

## Данные сгенерированной комнаты

enum RoomType {
	START,
	COMBAT,
	TREASURE,
	SHOP,
	ELITE,
	BOSS,
	SECRET
}

var grid_pos: Vector2i = Vector2i.ZERO
var room_type: RoomType = RoomType.COMBAT
var doors: Dictionary = {} # Vector2i (UP, DOWN, LEFT, RIGHT) -> bool
var distance_from_start: int = 0

var is_cleared: bool = false
var is_visited: bool = false
var is_discovered: bool = false

func get_type_name() -> String:
	match room_type:
		RoomType.START: return "start"
		RoomType.COMBAT: return "combat"
		RoomType.TREASURE: return "treasure"
		RoomType.SHOP: return "shop"
		RoomType.ELITE: return "elite"
		RoomType.BOSS: return "boss"
		RoomType.SECRET: return "secret"
		_: return "unknown"

