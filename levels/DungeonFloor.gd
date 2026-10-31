class_name DungeonFloor
extends Node2D

## Менеджер процедурного этажа подземелья

const ROOM_SCENE = preload("res://levels/Room.tscn")
const PLAYER_SCENE = preload("res://entities/player/Player.tscn")
const HUD_SCENE = preload("res://ui/HUD.tscn")
const PAUSE_MENU_SCENE = preload("res://ui/PauseMenu.tscn")

const ROOM_WIDTH: float = 1280.0
const ROOM_HEIGHT: float = 720.0

@onready var rooms_container: Node2D = %RoomsContainer
@onready var minimap: Minimap = %Minimap

var floor_generator: FloorGenerator = FloorGenerator.new()
var floor_data: Dictionary = {}
var spawned_rooms: Dictionary = {} # Vector2i -> DungeonRoom

var player: Player
var current_grid_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	if GameState.current_seed == 0:
		GameState.current_seed = randi()
	
	_build_floor()

func _build_floor() -> void:
	# 1. Генерируем структуру комнат через FloorGenerator
	floor_data = floor_generator.generate_floor(GameState.current_seed, 10)
	var rooms: Dictionary = floor_data["rooms"]
	
	# 2. Инстанциируем комнаты
	for pos in rooms.keys():
		var room_node: DungeonRoom = ROOM_SCENE.instantiate() as DungeonRoom
		rooms_container.add_child(room_node)
		room_node.position = Vector2(pos.x * ROOM_WIDTH, pos.y * ROOM_HEIGHT)
		room_node.setup(rooms[pos])
		room_node.door_entered.connect(_on_room_door_entered)
		spawned_rooms[pos] = room_node
	
	# 3. Спавним игрока в стартовой комнате
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.global_position = Vector2(640, 360)
	
	# Камера игрока
	var camera: Camera2D = Camera2D.new()
	camera.set_script(load("res://entities/player/PlayerCamera.gd"))
	player.add_child(camera)
	
	# 4. Настраиваем HUD и мини-карту
	var hud: HUD = HUD_SCENE.instantiate() as HUD
	add_child(hud)
	
	var pause_menu: PauseMenu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)
	
	minimap.setup_minimap(rooms, Vector2i.ZERO)
	
	# Активируем стартовую комнату
	if spawned_rooms.has(Vector2i.ZERO):
		spawned_rooms[Vector2i.ZERO].on_player_entered()

func _on_room_door_entered(direction: Vector2i) -> void:
	var next_grid_pos: Vector2i = current_grid_pos + direction
	if not spawned_rooms.has(next_grid_pos):
		return
	
	current_grid_pos = next_grid_pos
	var target_room: DungeonRoom = spawned_rooms[next_grid_pos]
	
	# Рассчитываем точку появления игрока у противоположной двери новой комнаты
	var room_base_pos: Vector2 = Vector2(next_grid_pos.x * ROOM_WIDTH, next_grid_pos.y * ROOM_HEIGHT)
	var spawn_offset: Vector2 = Vector2(640, 360)
	
	match direction:
		Vector2i.UP: # Вошли в северную дверь -> появляемся у южной двери
			spawn_offset = Vector2(640, 600)
		Vector2i.DOWN: # Вошли в южную дверь -> появляемся у северной двери
			spawn_offset = Vector2(640, 120)
		Vector2i.LEFT: # Вошли в западную дверь -> появляемся у восточной двери
			spawn_offset = Vector2(1160, 360)
		Vector2i.RIGHT: # Вошли в восточную дверь -> появляемся у западной двери
			spawn_offset = Vector2(120, 360)
	
	player.global_position = room_base_pos + spawn_offset
	player.velocity = Vector2.ZERO
	target_room.on_player_entered()
