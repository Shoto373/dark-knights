class_name PickupBase
extends Area2D

## Базовый класс для поднимаемых предметов (Золото, Сердца, Ключи)

enum PickupType {
	GOLD,
	HEART,
	KEY
}

const GOLD_ICON: Texture2D = preload("res://assets/sprites/hud_icon_gold.svg")
const HEART_ICON: Texture2D = preload("res://assets/sprites/hud_icon_heart.svg")
const KEY_ICON: Texture2D = preload("res://assets/sprites/hud_icon_key.svg")

@export var pickup_type: PickupType = PickupType.GOLD
@export var amount: int = 1

@onready var visual: Node2D = %Visual

var pickup_sprite: Sprite2D = null

func _ready() -> void:
	collision_layer = 32 # Слой 6: pickups
	collision_mask = 2   # Слой 2: player
	body_entered.connect(_on_body_entered)
	_setup_visuals()
	_start_float_animation()

func _setup_visuals() -> void:
	pickup_sprite = visual.get_node_or_null("PickupSprite") as Sprite2D
	if pickup_sprite == null:
		pickup_sprite = Sprite2D.new()
		pickup_sprite.name = "PickupSprite"
		pickup_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.add_child(pickup_sprite)
	
	var old_rect: ColorRect = visual.get_node_or_null("ColorRect") as ColorRect
	if old_rect != null:
		old_rect.visible = false

	match pickup_type:
		PickupType.GOLD:
			pickup_sprite.texture = GOLD_ICON
			pickup_sprite.scale = Vector2(0.9, 0.9)
		PickupType.HEART:
			pickup_sprite.texture = HEART_ICON
			pickup_sprite.scale = Vector2(0.85, 0.85)
		PickupType.KEY:
			pickup_sprite.texture = KEY_ICON
			pickup_sprite.scale = Vector2(0.9, 0.9)

func _start_float_animation() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(visual, "position:y", -5.0, 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual, "position:y", 3.0, 0.55).set_trans(Tween.TRANS_SINE)

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
	match pickup_type:
		PickupType.GOLD:
			AudioManager.play_sfx_named("coin")
			EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(1.0, 0.85, 0.2), 6)
		PickupType.HEART:
			AudioManager.play_sfx_named("heal")
			EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(1.0, 0.3, 0.4), 6)
		PickupType.KEY:
			AudioManager.play_sfx_named("coin")
			EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(0.9, 0.9, 1.0), 6)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visual, "scale", Vector2(1.6, 1.6), 0.15)
	tween.tween_property(visual, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
