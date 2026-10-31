class_name LootTable
extends Resource

## Таблица лута с расчётом вероятностей по весам: P(i) = w_i / Σw

@export var items: Array[ItemData] = []

func roll_item(rng: RandomNumberGenerator = null, excluded_ids: Array = []) -> ItemData:
	var available_items: Array[ItemData] = []
	var total_weight: float = 0.0
	
	for item in items:
		if item != null and not excluded_ids.has(item.id):
			available_items.append(item)
			total_weight += maxf(0.01, item.weight)
	
	if available_items.is_empty():
		return null
	
	var roll: float
	if rng != null:
		roll = rng.randf_range(0.0, total_weight)
	else:
		roll = randf_range(0.0, total_weight)
	
	var accumulated: float = 0.0
	for item in available_items:
		accumulated += maxf(0.01, item.weight)
		if roll <= accumulated:
			return item
	
	return available_items.back()

func roll_multiple_unique(count: int, rng: RandomNumberGenerator = null, excluded_ids: Array = []) -> Array[ItemData]:
	var result: Array[ItemData] = []
	var current_excluded: Array = excluded_ids.duplicate()
	
	for _i in range(count):
		var rolled: ItemData = roll_item(rng, current_excluded)
		if rolled != null:
			result.append(rolled)
			current_excluded.append(rolled.id)
		else:
			break
	
	return result
