class_name PickupBase
extends Area2D

## Базовый класс для поднимаемых предметов (Золото, Сердца, Ключи)

enum PickupType {
	GOLD,
	HEART,
	KEY
}

@export var pickup_type: PickupType = PickupType.GOLD
@export var amount: int = 1

@onready var visual: Node2D = %Visual

func _ready() -> void:
	collision_layer = 32 # Слой 6: pickups
	collision_mask = 2   # Слой 2: player
	body_entered.connect(_on_body_entered)
	_start_float_animation()

func _start_float_animation() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(visual, "position:y", -4.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual, "position:y", 4.0, 0.6).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if _apply_pickup(body as Player):
			_collect()

func _apply_pickup(player: Player) -> bool:
	match pickup_type:
		PickupType.GOLD:
			GameState.add_gold(amount)
			return true
		PickupType.HEART:
			if player.health_component.current_health < player.health_component.max_health:
				player.health_component.heal(amount)
				return true
			return false
		PickupType.KEY:
			GameState.add_keys(amount)
			return true
	return false

func _collect() -> void:
	set_deferred("monitoring", false)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visual, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(visual, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)

