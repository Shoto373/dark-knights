class_name HitboxComponent
extends Area2D

## Компонент нанесения урона (Атакующий хитбокс)

signal hit_landed(target: Node)

@export var base_damage: int = 20
@export var damage_multiplier: float = 0.0
@export var crit_chance: float = 0.1
@export var crit_multiplier: float = 2.0
@export var knockback_force: float = 250.0
@export var damage_type: String = "physical" # physical, fire, ice, etc.
@export var tags: Array[String] = []
@export var applied_effect: StatusEffect
@export var effect_stacks: int = 1
@export var is_player_hitbox: bool = true:
	set(val):
		is_player_hitbox = val
		_update_collision_layers()

var source_owner: Node2D
var hit_targets: Array[Node] = []

func _ready() -> void:
	_update_collision_layers()
	if source_owner == null:
		source_owner = get_parent() as Node2D

func _update_collision_layers() -> void:
	# Слой 4 (8) — player_hitbox, Слой 5 (16) — enemy_hitbox
	if is_player_hitbox:
		collision_layer = 8
		collision_mask = 0
	else:
		collision_layer = 16
		collision_mask = 0

func can_hit(target: Node) -> bool:
	return not hit_targets.has(target)

func register_hit(target: Node) -> void:
	if not hit_targets.has(target):
		hit_targets.append(target)
		hit_landed.emit(target)

func reset_hits() -> void:
	hit_targets.clear()

func get_knockback_direction(target_position: Vector2) -> Vector2:
	if source_owner != null:
		var dir: Vector2 = target_position - source_owner.global_position
		if dir.length_squared() > 0.001:
			return dir.normalized()
	return Vector2.RIGHT

