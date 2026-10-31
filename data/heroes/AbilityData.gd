class_name AbilityData
extends Resource

## Ресурс описания способности героя

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var cooldown: float = 3.0
@export_enum("projectile", "aoe", "buff", "dash", "teleport") var effect_type: String = "projectile"

# Параметры эффекта
@export var base_damage: int = 30
@export var range_or_radius: float = 120.0
@export var duration: float = 1.5
@export var speed: float = 450.0
@export var projectile_count: int = 1
@export var spread_angle_deg: float = 0.0

