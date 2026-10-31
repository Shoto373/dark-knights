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
@export_enum("melee", "ranged", "support", "heavy", "boulder_thrower", "crossbowman", "necromancer", "frost_wraith", "frost_golem", "lich_apprentice", "ice_spider", "lava_slime", "fire_elemental", "flame_cultist", "magma_worm") var enemy_type: String = "melee"
@export var attack_range: float = 38.0
@export var attack_cooldown: float = 1.0
@export var preferred_distance: float = 0.0 # Дистанция удержания для стрелков
@export var knockback_resistance: float = 0.0

@export_group("Регенерация")
@export var can_regenerate: bool = false
@export var regen_amount: int = 6
@export var regen_delay_seconds: float = 3.0

@export_group("Механики скелетов и стражей")
@export var can_reassemble: bool = false # Скелет собирается обратно, если не разбить кости
@export var reassemble_time: float = 4.0
@export var bone_pile_hp: int = 25
@export var has_front_shield: bool = false # Блок спереди, уязвим только со спины

@export_group("Иммунитеты к эффектам")
@export var immunities: Array[String] = [] # "freeze", "burn", "poison", "stun"

@export_group("Награды и сложность")
@export var gold_reward: int = 5
@export var souls_reward: int = 0
@export var difficulty_cost: int = 1

