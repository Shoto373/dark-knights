class_name HeroData
extends Resource

## Ресурс описания героя (Data-Driven)

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var color: Color = Color(0.2, 0.45, 0.75, 1.0)
@export var portrait: Texture2D

@export_group("Характеристики")
@export var max_hp: int = 100
@export var speed: float = 220.0
@export var armor: int = 0

@export_group("Базовая атака")
@export_enum("melee", "ranged") var attack_type: String = "melee"
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.32
@export var attack_range: float = 40.0
@export var projectile_speed: float = 500.0

@export_group("Способности")
@export var ability_1: AbilityData
@export var ability_2: AbilityData

@export_group("Разблокировка")
@export var unlocked_by_default: bool = true
@export var unlock_cost_souls: int = 0
