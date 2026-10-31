class_name DungeonRoom
extends Node2D

## Комната подземелья с системой волн врагов и босса

signal room_cleared
signal door_entered(direction: Vector2i)

@onready var door_up: DungeonDoor = %DoorUp
@onready var door_down: DungeonDoor = %DoorDown
@onready var door_left: DungeonDoor = %DoorLeft
@onready var door_right: DungeonDoor = %DoorRight

@onready var wall_blocker_up: StaticBody2D = %WallBlockerUp
@onready var wall_blocker_down: StaticBody2D = %WallBlockerDown
@onready var wall_blocker_left: StaticBody2D = %WallBlockerLeft
@onready var wall_blocker_right: StaticBody2D = %WallBlockerRight

@onready var room_type_label: Label = %RoomTypeLabel
@onready var enemies_container: Node2D = %EnemiesContainer
@onready var objects_container: Node2D = %ObjectsContainer

var room_data: RoomData
var active_enemies: Array[Node2D] = []
var wave_spawner: WaveSpawner = WaveSpawner.new()

func _ready() -> void:
	door_up.door_entered.connect(_on_door_entered)
	door_down.door_entered.connect(_on_door_entered)
	door_left.door_entered.connect(_on_door_entered)
	door_right.door_entered.connect(_on_door_entered)

func setup(data: RoomData) -> void:
	room_data = data
	room_type_label.text = "[ %s ]" % room_data.get_type_name().to_upper()
	_configure_doors()
	
	if room_data.room_type == RoomData.RoomType.TREASURE:
		_setup_treasure_room()

func _configure_doors() -> void:
	_setup_door(door_up, wall_blocker_up, Vector2i.UP)
	_setup_door(door_down, wall_blocker_down, Vector2i.DOWN)
	_setup_door(door_left, wall_blocker_left, Vector2i.LEFT)
	_setup_door(door_right, wall_blocker_right, Vector2i.RIGHT)

func _setup_door(door: DungeonDoor, blocker: StaticBody2D, dir: Vector2i) -> void:
	var has_door: bool = room_data.doors.get(dir, false)
	door.visible = has_door
	door.monitoring = has_door
	blocker.set_collision_layer_value(1, not has_door)
	blocker.visible = not has_door

func on_player_entered() -> void:
	room_data.is_visited = true
	room_data.is_discovered = true
	
	EventBus.room_entered.emit({
		"grid_pos": room_data.grid_pos,
		"type": room_data.get_type_name()
	})
	
	var is_hostile: bool = (room_data.room_type == RoomData.RoomType.COMBAT or \
							room_data.room_type == RoomData.RoomType.ELITE or \
							room_data.room_type == RoomData.RoomType.BOSS)
	
	if is_hostile and not room_data.is_cleared:
		_start_combat()
	else:
		_unlock_all_doors()

func _start_combat() -> void:
	_lock_all_doors()
	active_enemies = wave_spawner.spawn_room_enemies(self, room_data)
	
	for enemy in active_enemies:
		var hc: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null:
			hc.died.connect(func(): _on_enemy_died(enemy))

func _on_enemy_died(enemy: Node2D) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		_finish_combat()

func _finish_combat() -> void:
	room_data.is_cleared = true
	_unlock_all_doors()
	EventBus.room_cleared.emit()
	room_cleared.emit()

func _lock_all_doors() -> void:
	door_up.is_open = false
	door_down.is_open = false
	door_left.is_open = false
	door_right.is_open = false

func _unlock_all_doors() -> void:
	door_up.is_open = true
	door_down.is_open = true
	door_left.is_open = true
	door_right.is_open = true

func _setup_treasure_room() -> void:
	var pedestal = ColorRect.new()
	pedestal.size = Vector2(40, 40)
	pedestal.position = Vector2(620, 340)
	pedestal.color = Color(0.95, 0.8, 0.2, 1.0)
	objects_container.add_child(pedestal)

func _on_door_entered(direction: Vector2i) -> void:
	door_entered.emit(direction)
