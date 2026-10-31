extends GutTest

func test_basic_damage_calculation() -> void:
	# B = 20, M = 0.0, C = 1.0 (no crit), A = 0
	var dmg: int = DamageCalculator.calculate_damage(20, 0.0, 2.0, false, 0)
	assert_eq(dmg, 20, "Base damage without modifiers should be 20")

func test_damage_with_bonus_multiplier() -> void:
	# B = 20, M = 0.25 (+25%), C = 1.0, A = 5
	# 20 * 1.25 - 5 = 25 - 5 = 20
	var dmg: int = DamageCalculator.calculate_damage(20, 0.25, 2.0, false, 5)
	assert_eq(dmg, 20, "20 * 1.25 - 5 = 20")

func test_damage_with_crit() -> void:
	# B = 20, M = 0.25, C = 2.0 (crit), A = 5
	# 20 * 1.25 * 2.0 - 5 = 50 - 5 = 45
	var dmg: int = DamageCalculator.calculate_damage(20, 0.25, 2.0, true, 5)
	assert_eq(dmg, 45, "Crit damage should be 45")

func test_minimum_damage_is_one() -> void:
	# Armor exceeds damage: B = 10, A = 50 -> raw = -40, max(1, -40) = 1
	var dmg: int = DamageCalculator.calculate_damage(10, 0.0, 1.0, false, 50)
	assert_eq(dmg, 1, "Minimum damage must always be at least 1")

func test_roll_crit_boundaries() -> void:
	assert_false(DamageCalculator.roll_crit(0.0), "0% crit chance should never crit")
	assert_true(DamageCalculator.roll_crit(1.0), "100% crit chance should always crit")
