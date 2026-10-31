extends GutTest

func test_take_damage_decreases_hp() -> void:
	var hc: HealthComponent = HealthComponent.new()
	add_child_autofree(hc)
	hc.max_health = 100
	hc.reset()
	
	watch_signals(hc)
	var taken: int = hc.take_damage(25)
	
	assert_eq(taken, 25, "Actual damage returned should be 25")
	assert_eq(hc.current_health, 75, "Current HP should be 75")
	assert_signal_emitted_with_parameters(hc, "damaged", [25, 75, 100])

func test_invulnerability_prevents_damage() -> void:
	var hc: HealthComponent = HealthComponent.new()
	add_child_autofree(hc)
	hc.max_health = 100
	hc.reset()
	hc.set_invulnerable(true)
	
	var taken: int = hc.take_damage(50)
	assert_eq(taken, 0, "No damage should be taken while invulnerable")
	assert_eq(hc.current_health, 100, "HP should remain full")

func test_death_emitted_only_once() -> void:
	var hc: HealthComponent = HealthComponent.new()
	add_child_autofree(hc)
	hc.max_health = 50
	hc.reset()
	watch_signals(hc)
	
	hc.take_damage(60)
	assert_eq(hc.current_health, 0, "HP cannot go below 0")
	assert_true(hc.is_dead, "Component should be marked dead")
	assert_signal_emit_count(hc, "died", 1)
	
	# Further damage while dead should not re-trigger died
	hc.take_damage(20)
	assert_signal_emit_count(hc, "died", 1)

func test_healing_cannot_exceed_max_health() -> void:
	var hc: HealthComponent = HealthComponent.new()
	add_child_autofree(hc)
	hc.max_health = 100
	hc.reset()
	hc.take_damage(40) # HP is 60
	
	watch_signals(hc)
	var healed: int = hc.heal(100)
	assert_eq(healed, 40, "Should only heal missing 40 HP")
	assert_eq(hc.current_health, 100, "HP should be at max")
	assert_signal_emitted_with_parameters(hc, "healed", [40, 100, 100])

