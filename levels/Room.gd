class_name DungeonRoom
extends Node2D

## Комната подземелья в стиле The Binding of Isaac / Enter the Gungeon

signal room_cleared
signal door_entered(direction: Vector2i)

const ITEM_PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")
const TREASURE_CHEST_SCENE = preload("res://entities/loot/TreasureChest.tscn")
const PICKUP_SCENE = preload("res://entities/pickups/PickupBase.tscn")
const CHASM_HAZARD_SCENE = preload("res://levels/hazards/ChasmHazard.tscn")
const BRIDGE_AREA_SCENE = preload("res://levels/hazards/BridgeArea.tscn")
const FIRE_GRATE_SCENE = preload("res://levels/hazards/FireGrateTrap.tscn")
const CHANDELIER_SCENE = preload("res://levels/hazards/FallingChandelierTrap.tscn")
const SECRET_LEVER_SCENE = preload("res://levels/hazards/SecretLever.tscn")
const ICE_PATCH_SCENE = preload("res://levels/hazards/IcePatch.tscn")

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
var current_biome: BiomeData = null
var active_enemies: Array[Node2D] = []
var wave_spawner: WaveSpawner = WaveSpawner.new()

func _ready() -> void:
	door_up.door_entered.connect(_on_door_entered)
	door_down.door_entered.connect(_on_door_entered)
	door_left.door_entered.connect(_on_door_entered)
	door_right.door_entered.connect(_on_door_entered)

func setup(data: RoomData, biome: BiomeData = null) -> void:
	room_data = data
	current_biome = biome if biome != null else GameState.get_current_biome()
	room_type_label.text = "[ %s ]" % room_data.get_type_name().to_upper()
	_apply_biome_theme()
	_configure_doors()
	
	if room_data.room_type == RoomData.RoomType.TREASURE:
		_setup_treasure_room()
	elif room_data.room_type == RoomData.RoomType.SHOP:
		_setup_shop_room()
	elif room_data.room_type == RoomData.RoomType.COMBAT:
		_setup_biome_hazards()

func _apply_biome_theme() -> void:
	if current_biome == null:
		return
	var floor_node: ColorRect = get_node_or_null("Floor") as ColorRect
	if floor_node != null:
		floor_node.color = current_biome.floor_theme_color
	var arena_floor: ColorRect = get_node_or_null("ArenaFloor") as ColorRect
	if arena_floor != null:
		arena_floor.color = current_biome.floor_theme_color.lightened(0.06)
	var walls_node: Node2D = get_node_or_null("VisualWalls") as Node2D
	if walls_node != null:
		for wall in walls_node.get_children():
			if wall is ColorRect:
				wall.color = current_biome.wall_theme_color

func _setup_biome_hazards() -> void:
	if current_biome == null:
		return
	if current_biome.id == "troll_gorge":
		if abs(room_data.grid_pos.x + room_data.grid_pos.y) % 2 == 1:
			_create_gorge_chasm_and_bridge()
	elif current_biome.id == "skeleton_castle":
		_create_castle_traps()
	elif current_biome.id == "frost_world" or current_biome.id == "frost_caves":
		_create_frost_ice_patches()

func _create_frost_ice_patches() -> void:
	var patch1: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
	objects_container.add_child(patch1)
	patch1.position = Vector2(480, 360)
	
	var patch2: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
	objects_container.add_child(patch2)
	patch2.position = Vector2(800, 360)
	
	if abs(room_data.grid_pos.x + room_data.grid_pos.y) % 2 == 1:
		var patch3: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
		objects_container.add_child(patch3)
		patch3.position = Vector2(640, 260)

func _create_castle_traps() -> void:
	var grate1: FireGrateTrap = FIRE_GRATE_SCENE.instantiate() as FireGrateTrap
	objects_container.add_child(grate1)
	grate1.position = Vector2(480, 360)
	
	var grate2: FireGrateTrap = FIRE_GRATE_SCENE.instantiate() as FireGrateTrap
	objects_container.add_child(grate2)
	grate2.position = Vector2(800, 360)
	
	var chandelier: FallingChandelierTrap = CHANDELIER_SCENE.instantiate() as FallingChandelierTrap
	objects_container.add_child(chandelier)
	chandelier.position = Vector2(640, 300)
	
	if abs(room_data.grid_pos.x + room_data.grid_pos.y) % 2 == 0:
		var lever: SecretLever = SECRET_LEVER_SCENE.instantiate() as SecretLever
		objects_container.add_child(lever)
		lever.position = Vector2(200, 180)

func _create_gorge_chasm_and_bridge() -> void:
	var top_chasm: ChasmHazard = CHASM_HAZARD_SCENE.instantiate() as ChasmHazard
	objects_container.add_child(top_chasm)
	top_chasm.position = Vector2(640, 180)
	top_chasm.pit_size = Vector2(160, 200)
	if current_biome != null:
		top_chasm.visual_pit.color = current_biome.chasm_color
	
	var bottom_chasm: ChasmHazard = CHASM_HAZARD_SCENE.instantiate() as ChasmHazard
	objects_container.add_child(bottom_chasm)
	bottom_chasm.position = Vector2(640, 540)
	bottom_chasm.pit_size = Vector2(160, 200)
	if current_biome != null:
		bottom_chasm.visual_pit.color = current_biome.chasm_color
		
	var bridge: BridgeArea = BRIDGE_AREA_SCENE.instantiate() as BridgeArea
	objects_container.add_child(bridge)
	bridge.position = Vector2(640, 360)
	bridge.bridge_size = Vector2(160, 140)
	if current_biome != null:
		bridge.visual_rect.color = current_biome.bridge_color

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
	active_enemies = wave_spawner.spawn_room_enemies(self, room_data, current_biome)
	
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
	_spawn_room_clear_reward()
	EventBus.room_cleared.emit()
	room_cleared.emit()

func _spawn_room_clear_reward() -> void:
	var rng: RandomNumberGenerator = GameState.rng
	var roll: float = rng.randf()
	
	if roll < 0.25:
		var coin: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		coin.pickup_type = PickupBase.PickupType.GOLD
		coin.amount = rng.randi_range(3, 8)
		objects_container.add_child(coin)
		coin.position = Vector2(640, 360)
	elif roll < 0.45:
		var heart: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		heart.pickup_type = PickupBase.PickupType.HEART
		heart.amount = 25
		objects_container.add_child(heart)
		heart.position = Vector2(640, 360)
	elif roll < 0.60:
		var key: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		key.pickup_type = PickupBase.PickupType.KEY
		key.amount = 1
		objects_container.add_child(key)
		key.position = Vector2(640, 360)
	elif roll < 0.75:
		var chest: TreasureChest = TREASURE_CHEST_SCENE.instantiate() as TreasureChest
		chest.requires_key = (rng.randf() > 0.5)
		objects_container.add_child(chest)
		chest.position = Vector2(640, 360)

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
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	var item: ItemData = null
	if loot_table != null:
		item = loot_table.roll_item(GameState.rng)
	
	if item != null:
		var pedestal: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		objects_container.add_child(pedestal)
		pedestal.position = Vector2(640, 360)
		pedestal.setup(item, 0, false)
	else:
		var chest: TreasureChest = TREASURE_CHEST_SCENE.instantiate() as TreasureChest
		objects_container.add_child(chest)
		chest.position = Vector2(640, 360)

func _setup_shop_room() -> void:
	var merchant: ColorRect = ColorRect.new()
	merchant.size = Vector2(32, 40)
	merchant.position = Vector2(624, 210)
	merchant.color = Color(0.65, 0.45, 0.25, 1.0)
	objects_container.add_child(merchant)
	
	var label: Label = Label.new()
	label.text = "ТОРГОВЕЦ"
	label.position = Vector2(600, 185)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	objects_container.add_child(label)
	
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	var rolled_items: Array[ItemData] = []
	if loot_table != null:
		rolled_items = loot_table.roll_multiple_unique(2, GameState.rng)
	
	if rolled_items.size() > 0:
		var it1: ItemData = rolled_items[0]
		var ped1: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		objects_container.add_child(ped1)
		ped1.position = Vector2(480, 360)
		ped1.setup(it1, it1.cost_gold, false)
	
	if rolled_items.size() > 1:
		var it2: ItemData = rolled_items[1]
		var ped2: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		objects_container.add_child(ped2)
		ped2.position = Vector2(640, 360)
		ped2.setup(it2, it2.cost_gold, false)
	
	var key_ped: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
	objects_container.add_child(key_ped)
	key_ped.position = Vector2(800, 360)
	var key_item: ItemData = ItemData.new()
	key_item.id = "shop_key"
	key_item.name = "Ключ"
	key_item.rarity = "common"
	key_ped.setup(key_item, 10, false)
	key_ped.item_picked.connect(func(_it): GameState.add_keys(1))

func _on_door_entered(direction: Vector2i) -> void:
	door_entered.emit(direction)
