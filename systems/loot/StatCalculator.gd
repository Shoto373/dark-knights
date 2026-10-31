class_name StatCalculator
extends RefCounted

## Калькулятор характеристик по формуле:
## S = (S0 + ΣA) * (1 + ΣP)
## где:
##   S  — итоговое значение стата
##   S0 — базовое значение из HeroData
##   ΣA — сумма плоских бонусов (add)
##   ΣP — сумма процентных бонусов (mult)

static func calculate_stat(
	base_value: float,
	items: Array, # Array of ItemData
	stat_name: String
) -> float:
	var flat_sum: float = 0.0
	var mult_sum: float = 0.0
	
	# 1. Суммируем модификаторы из всех предметов
	for item in items:
		if item is ItemData:
			for mod in item.modifiers:
				if mod is StatModifier and mod.stat_name == stat_name:
					if mod.operation == "add":
						flat_sum += mod.value
					elif mod.operation == "mult":
						mult_sum += mod.value
	
	# 2. Учитываем синергии тегов
	var tag_counts: Dictionary = get_tag_counts(items)
	
	if tag_counts.get("fire", 0) >= 2 and stat_name == "damage":
		mult_sum += 0.15 # Синергия огня: +15% к урону
	if tag_counts.get("blade", 0) >= 2 and stat_name == "damage":
		flat_sum += 6.0  # Синергия клинков: +6 к базовому урону
	if tag_counts.get("armor", 0) >= 2 and stat_name == "armor":
		flat_sum += 2.0  # Синергия брони: +2 к броне
	if tag_counts.get("crit", 0) >= 2 and stat_name == "crit_chance":
		flat_sum += 0.08 # Синергия крита: +8% к шансу крита
	if tag_counts.get("agility", 0) >= 2 and stat_name == "speed":
		flat_sum += 20.0 # Синергия ловкости: +20 к скорости
	if tag_counts.get("blood", 0) >= 2 and stat_name == "max_hp":
		flat_sum += 25.0 # Синергия крови: +25 к здоровью
	
	var final_val: float = (base_value + flat_sum) * (1.0 + mult_sum)
	return maxf(0.0, final_val)

static func get_tag_counts(items: Array) -> Dictionary:
	var counts: Dictionary = {}
	for item in items:
		if item is ItemData:
			for tag in item.tags:
				counts[tag] = counts.get(tag, 0) + 1
	return counts
