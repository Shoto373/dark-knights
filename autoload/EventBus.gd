extends Node

## Глобальная шина событий игры

# Сигналы игрока
signal player_spawned(player: Node2D)
signal player_health_changed(current: int, max_hp: int)
signal player_died
signal player_healed(amount: int)

# Сигналы боя
signal damage_dealt(target: Node2D, amount: int, is_crit: bool)
signal screen_shake_requested(intensity: float, duration: float)
signal hit_stop_requested(duration_ms: float)

# Сигналы комнат и этажей
signal room_entered(room_data: Dictionary)
signal room_cleared
signal boss_spawned(boss_name: String, max_hp: int)
signal boss_health_changed(current: int, max_hp: int)
signal boss_defeated(boss_name: String)
signal floor_completed

# Сигналы забега
signal run_started(seed_val: int)
signal run_ended(is_victory: bool, stats: Dictionary)

# Сигналы интерфейса и инвентаря
signal item_collected(item_id: String)
signal currency_changed(gold: int, souls: int)

