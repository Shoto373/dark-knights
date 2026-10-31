extends Node

## Менеджер сохранений (JSON в user:// с защитой от повреждения)

const CURRENT_SAVE_VERSION: int = 1
const META_SAVE_PATH: String = "user://meta_save.json"
const RUN_SAVE_PATH: String = "user://run_save.json"

func _ready() -> void:
	load_meta()

func save_meta() -> bool:
	var data: Dictionary = {
		"version": CURRENT_SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"meta": MetaProgress.to_dict()
	}
	return _atomic_write_json(META_SAVE_PATH, data)

func load_meta() -> bool:
	if not FileAccess.file_exists(META_SAVE_PATH):
		return false
	
	var data: Variant = _read_json(META_SAVE_PATH)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		push_error("Failed to parse meta save file.")
		return false
	
	var dict_data: Dictionary = data
	var version: int = dict_data.get("version", 1)
	var migrated_data: Dictionary = _migrate_meta(dict_data, version)
	
	if migrated_data.has("meta"):
		MetaProgress.load_from_dict(migrated_data["meta"])
		return true
	return false

func save_run() -> bool:
	if not GameState.is_run_active:
		return false
	
	var data: Dictionary = {
		"version": CURRENT_SAVE_VERSION,
		"seed": GameState.current_seed,
		"hero_id": GameState.selected_hero_id,
		"node_id": GameState.current_world_node_id,
		"floor": GameState.current_floor_index,
		"hp": GameState.current_hp,
		"max_hp": GameState.max_hp,
		"gold": GameState.gold,
		"keys": GameState.keys,
		"inventory": GameState.inventory_items,
		"stats": GameState.run_stats
	}
	return _atomic_write_json(RUN_SAVE_PATH, data)

func load_run() -> bool:
	if not has_saved_run():
		return false
	var data: Variant = _read_json(RUN_SAVE_PATH)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return false
	
	var dict_data: Dictionary = data
	GameState.is_run_active = true
	GameState.current_seed = dict_data.get("seed", 0)
	GameState.rng.seed = GameState.current_seed
	GameState.selected_hero_id = dict_data.get("hero_id", "warrior")
	GameState.current_world_node_id = dict_data.get("node_id", "goblin_dungeon")
	GameState.current_floor_index = dict_data.get("floor", 1)
	GameState.current_hp = dict_data.get("hp", 100)
	GameState.max_hp = dict_data.get("max_hp", 100)
	GameState.gold = dict_data.get("gold", 0)
	GameState.keys = dict_data.get("keys", 0)
	GameState.inventory_items = Array(dict_data.get("inventory", []), TYPE_DICTIONARY, &"", null)
	GameState.run_stats = dict_data.get("stats", GameState.run_stats)
	return true

func delete_run_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)

func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)

func _atomic_write_json(path: String, data: Dictionary) -> bool:
	var temp_path: String = path + ".tmp"
	var json_str: String = JSON.stringify(data, "\t")
	
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write to temp file: %s" % temp_path)
		return false
	file.store_string(json_str)
	file.close()
	
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	
	var rename_err: Error = DirAccess.rename_absolute(temp_path, path)
	if rename_err != OK:
		push_error("Failed to rename %s to %s, error code: %d" % [temp_path, path, rename_err])
		return false
	return true

func _read_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(content)
	if parse_err != OK:
		push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
		return null
	return json.data

func _migrate_meta(data: Dictionary, version: int) -> Dictionary:
	# Место для миграций между версиями сохранений
	if version < 1:
		pass
	return data

