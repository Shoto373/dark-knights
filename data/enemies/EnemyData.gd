class_name EnemyData
extends Resource

## Ресурс описания характеристик врага (Data-Driven)

@export var id: String = ""
@export var name: String = ""
@export var color: Color = Color(0.2, 0.7, 0.3, 1.0)

@export_group("Характеристики")
@export var max_hp: int = 40
@export var speed: float = 140.0
@export var armor: int = 0
@export var damage: int = 12

@export_group("Боевое поведение")
@export_enum("melee", "ranged", "support", "heavy") var enemy_type: String = "melee"
@export var attack_range: float = 38.0
@export var attack_cooldown: float = 1.0
@export var preferred_distance: float = 0.0 # Дистанция удержания для стрелков
@export var knockback_resistance: float = 0.0

@export_group("Награды и сложность")
@export var gold_reward: int = 5
@export var souls_reward: int = 0
@export var difficulty_cost: int = 1
