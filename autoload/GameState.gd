extends Node

## Состояние текущего забега (Run State)

var is_run_active: bool = false
var current_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var selected_hero_id: String = "warrior"
var current_world_node_id: String = "hub"
var current_floor_index: int = 0

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

func start_new_run(hero_id: String = "warrior", custom_seed: int = 0) -> void:
	is_run_active = true
	selected_hero_id = hero_id
	if custom_seed != 0:
		current_seed = custom_seed
	else:
		current_seed = randi()
	
	rng.seed = current_seed
	current_world_node_id = "goblin_dungeon"
	current_floor_index = 1
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
	EventBus.run_ended.emit(is_victory, run_stats)
	if SaveManager.has_method("delete_run_save"):
		SaveManager.delete_run_save()

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	EventBus.currency_changed.emit(gold, MetaProgress.souls if MetaProgress else 0)

func add_keys(amount: int) -> void:
	keys = max(0, keys + amount)
