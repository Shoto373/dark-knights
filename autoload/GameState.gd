extends Node

## Состояние текущего забега (Run State)

var is_run_active: bool = false
var current_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var selected_hero_id: String = "warrior"
var current_world_node_id: String = "hub"
var current_world_node: WorldNodeData = null
var visited_world_nodes: Array[String] = []
var current_floor_index: int = 0
var has_seen_castle_cutscene: bool = false

var world_graph: WorldGraph = null

var current_hp: int = 100
var max_hp: int = 100
var gold: int = 0
var keys: int = 0

var inventory_items: Array[Dictionary] = []
var run_stats: Dictionary = {
	"kills": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"rooms_cleared": 0,
	"time_elapsed": 0.0
}

func _ready() -> void:
	world_graph = WorldGraph.new()
	EventBus.room_cleared.connect(_on_room_cleared)
	EventBus.damage_dealt.connect(_on_damage_dealt)

func _process(delta: float) -> void:
	if is_run_active:
		run_stats["time_elapsed"] = run_stats.get("time_elapsed", 0.0) + delta

func _on_room_cleared() -> void:
	if is_run_active:
		run_stats["rooms_cleared"] = run_stats.get("rooms_cleared", 0) + 1

func _on_damage_dealt(_target: Node2D, amount: int, _is_crit: bool) -> void:
	if is_run_active:
		run_stats["damage_dealt"] = run_stats.get("damage_dealt", 0) + amount

func start_new_run(hero_id: String = "warrior", custom_seed: int = 0) -> void:
	if world_graph == null:
		world_graph = WorldGraph.new()
		
	is_run_active = true
	selected_hero_id = hero_id
	if custom_seed != 0:
		current_seed = custom_seed
	else:
		current_seed = randi()
	
	rng.seed = current_seed
	current_world_node_id = "goblin_dungeon"
	current_world_node = world_graph.get_node("goblin_dungeon")
	visited_world_nodes = ["goblin_dungeon"]
	current_floor_index = 1
	has_seen_castle_cutscene = false
	gold = 0
	keys = 0
	inventory_items.clear()
	run_stats = {
		"kills": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"rooms_cleared": 0,
		"time_elapsed": 0.0
	}
	EventBus.run_started.emit(current_seed)

func end_run(is_victory: bool) -> void:
	if not is_run_active:
		return
	is_run_active = false
	current_world_node_id = "hub"
	current_world_node = null
	visited_world_nodes.clear()
	if not is_victory and MetaProgress != null:
		MetaProgress.lifetime_stats["total_runs"] = MetaProgress.lifetime_stats.get("total_runs", 0) + 1
		if SaveManager != null and SaveManager.has_method("save_meta"):
			SaveManager.save_meta()
	EventBus.run_ended.emit(is_victory, run_stats)
	if SaveManager != null and SaveManager.has_method("delete_run_save"):
		SaveManager.delete_run_save()

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	EventBus.currency_changed.emit(gold, MetaProgress.souls if MetaProgress else 0)

func add_keys(amount: int) -> void:
	keys = max(0, keys + amount)

func get_current_biome() -> BiomeData:
	if current_world_node != null and current_world_node.biome != null:
		return current_world_node.biome
	
	var biome_path: String = "res://data/biomes/%s.tres" % current_world_node_id
	if ResourceLoader.exists(biome_path):
		var bio: Resource = load(biome_path)
		if bio is BiomeData:
			return bio as BiomeData
			
	return load("res://data/biomes/goblin_dungeon.tres") as BiomeData

func advance_to_world_node(node: WorldNodeData) -> void:
	if node == null:
		return
	current_world_node = node
	current_world_node_id = node.id
	if not visited_world_nodes.has(node.id):
		visited_world_nodes.append(node.id)
	current_floor_index += 1
	
	# Обновляем сид для детерминированности следующего этажа
	current_seed = rng.randi()
	SaveManager.save_run()
	SceneRouter.change_scene("res://levels/DungeonFloor.tscn", 0.4)
