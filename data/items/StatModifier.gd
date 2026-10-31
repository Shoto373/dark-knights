class_name StatModifier
extends Resource

## Модификатор характеристик

@export var stat_name: String = "damage" # max_hp, speed, damage, armor, crit_chance, crit_multiplier
@export_enum("add", "mult") var operation: String = "add"
@export var value: float = 5.0
