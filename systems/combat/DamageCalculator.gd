class_name DamageCalculator
extends RefCounted

## Калькулятор урона по формуле:
## damage = max(1, round(B * (1 + M) * C - A))
## где:
##   B — базовый урон оружия/способности
##   M — сумма процентных бонусов к урону (0.25 = +25%)
##   C — множитель крита (1 без крита, иначе crit_multiplier)
##   A — броня цели

static func calculate_damage(
	base_damage: int,
	bonus_multiplier: float = 0.0,
	crit_multiplier: float = 2.0,
	is_crit: bool = false,
	target_armor: int = 0
) -> int:
	var c: float = crit_multiplier if is_crit else 1.0
	var raw_damage: float = float(base_damage) * (1.0 + bonus_multiplier) * c - float(target_armor)
	return maxi(1, int(round(raw_damage)))

static func roll_crit(crit_chance: float, rng: RandomNumberGenerator = null) -> bool:
	if crit_chance <= 0.0:
		return false
	if crit_chance >= 1.0:
		return true
	
	if rng != null:
		return rng.randf() < crit_chance
	return randf() < crit_chance

