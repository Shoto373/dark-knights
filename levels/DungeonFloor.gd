class_name DungeonFloor
extends Node2D

## Менеджер этажа в стиле Isaac / Enter the Gungeon (покомнатная камера и переходы)

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
var camera: Camera2D
var current_grid_pos: Vector2i = Vector2i.ZERO
var is_room_transitioning: bool = false

func _ready() -> void:
	if GameState.current_seed == 0:
		GameState.current_seed = randi()
	
	_build_floor()
	
	if GameState.current_world_node_id == "skeleton_castle" and not GameState.has_seen_castle_cutscene:
		GameState.has_seen_castle_cutscene = true
		var cutscene_scene: PackedScene = load("res://ui/CutsceneScreen.tscn")
		if cutscene_scene != null:
			var cutscene: CutsceneScreen = cutscene_scene.instantiate() as CutsceneScreen
			add_child(cutscene)
			cutscene.show_entry_cutscene()

func _build_floor() -> void:
	var current_biome: BiomeData = GameState.get_current_biome()
	var target_rooms: int = 10
	if current_biome != null:
		target_rooms = GameState.rng.randi_range(current_biome.min_rooms, current_biome.max_rooms)
		
	floor_data = floor_generator.generate_floor(GameState.current_seed, target_rooms)
	var rooms: Dictionary = floor_data["rooms"]
	
	for pos in rooms.keys():
		var room_node: DungeonRoom = ROOM_SCENE.instantiate() as DungeonRoom
		rooms_container.add_child(room_node)
		room_node.position = Vector2(pos.x * ROOM_WIDTH, pos.y * ROOM_HEIGHT)
		room_node.setup(rooms[pos], current_biome)
		room_node.door_entered.connect(_on_room_door_entered)
		spawned_rooms[pos] = room_node
	
	# Спавним игрока в центре стартовой комнаты
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.global_position = Vector2(640, 360)
	
	# Камера, привязанная к экрану текущей комнаты (стиль The Binding of Isaac)
	camera = Camera2D.new()
	camera.set_script(load("res://entities/player/PlayerCamera.gd"))
	add_child(camera)
	camera.global_position = Vector2(640, 360)
	
	var hud: HUD = HUD_SCENE.instantiate() as HUD
	add_child(hud)
	
	var pause_menu: PauseMenu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)
	
	if current_biome != null and (current_biome.id == "frost_world" or current_biome.id == "frost_caves"):
		var blizzard_scene: PackedScene = load("res://ui/BlizzardOverlay.tscn")
		if blizzard_scene != null:
			var blizzard = blizzard_scene.instantiate()
			add_child(blizzard)
	elif current_biome != null and (current_biome.id == "fire_world" or current_biome.id == "fire_mines"):
		var haze_scene: PackedScene = load("res://ui/HeatHazeOverlay.tscn")
		if haze_scene != null:
			var haze = haze_scene.instantiate()
			add_child(haze)
	elif current_biome != null and current_biome.id == "purgatory":
		var fog_scene: PackedScene = load("res://ui/PurgatoryFogOverlay.tscn")
		if fog_scene != null:
			var fog = fog_scene.instantiate()
			add_child(fog)
	
	minimap.setup_minimap(rooms, Vector2i.ZERO)
	
	if spawned_rooms.has(Vector2i.ZERO):
		spawned_rooms[Vector2i.ZERO].on_player_entered()

func _on_room_door_entered(direction: Vector2i) -> void:
	if is_room_transitioning:
		return
	
	var next_grid_pos: Vector2i = current_grid_pos + direction
	if not spawned_rooms.has(next_grid_pos):
		return
	
	is_room_transitioning = true
	current_grid_pos = next_grid_pos
	var target_room: DungeonRoom = spawned_rooms[next_grid_pos]
	
	# Координаты новой комнаты и центрирования камеры
	var new_room_center: Vector2 = Vector2(
		next_grid_pos.x * ROOM_WIDTH + 640.0,
		next_grid_pos.y * ROOM_HEIGHT + 360.0
	)
	
	var room_base_pos: Vector2 = Vector2(next_grid_pos.x * ROOM_WIDTH, next_grid_pos.y * ROOM_HEIGHT)
	var spawn_offset: Vector2 = Vector2(640, 360)
	
	match direction:
		Vector2i.UP:
			spawn_offset = Vector2(640, 600)
		Vector2i.DOWN:
			spawn_offset = Vector2(640, 120)
		Vector2i.LEFT:
			spawn_offset = Vector2(1160, 360)
		Vector2i.RIGHT:
			spawn_offset = Vector2(120, 360)
	
	player.global_position = room_base_pos + spawn_offset
	player.velocity = Vector2.ZERO
	
	# Плавный сдвиг камеры между комнатами (Pan в стиле Isaac / Gungeon)
	var tween: Tween = create_tween()
	tween.tween_property(camera, "global_position", new_room_center, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		is_room_transitioning = false
		target_room.on_player_entered()
	)
