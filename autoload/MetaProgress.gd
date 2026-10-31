extends Node

## Мета-прогресс между забегами

var souls: int = 0
var unlocked_heroes: Array[String] = ["warrior"]
var unlocked_items: Array[String] = []
var meta_upgrades: Dictionary = {
	"extra_health_levels": 0,
	"starting_gold_levels": 0,
	"extra_choice_unlocked": false
}

var lifetime_stats: Dictionary = {
	"total_runs": 0,
	"victories": 0,
	"total_kills": 0,
	"total_souls_collected": 0
}

func add_souls(amount: int) -> void:
	souls = max(0, souls + amount)
	lifetime_stats["total_souls_collected"] = lifetime_stats.get("total_souls_collected", 0) + amount
	EventBus.currency_changed.emit(GameState.gold if GameState else 0, souls)

func unlock_hero(hero_id: String) -> bool:
	if not unlocked_heroes.has(hero_id):
		unlocked_heroes.append(hero_id)
		return true
	return false

func is_hero_unlocked(hero_id: String) -> bool:
	return unlocked_heroes.has(hero_id)

func to_dict() -> Dictionary:
	return {
		"souls": souls,
		"unlocked_heroes": unlocked_heroes,
		"unlocked_items": unlocked_items,
		"meta_upgrades": meta_upgrades,
		"lifetime_stats": lifetime_stats
	}

func load_from_dict(data: Dictionary) -> void:
	souls = data.get("souls", 0)
	unlocked_heroes = Array(data.get("unlocked_heroes", ["warrior"]), TYPE_STRING, &"", null)
	unlocked_items = Array(data.get("unlocked_items", []), TYPE_STRING, &"", null)
	meta_upgrades = data.get("meta_upgrades", meta_upgrades)
	lifetime_stats = data.get("lifetime_stats", lifetime_stats)

