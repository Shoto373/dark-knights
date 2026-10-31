class_name TrapSpikes
extends Node2D

## Ловушка с выдвижными стальными шипами, кровавыми зазубринами и анимацией удара

@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var spike_sprite: Sprite2D = %SpikeSprite
@onready var collision_shape: CollisionShape2D = $HitboxComponent/CollisionShape2D

@export var damage: int = 20
@export var tick_rate: float = 1.0

var _timer: float = 0.0
var _is_extended: bool = true

func _ready() -> void:
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = false
	hitbox.source_owner = self
	_set_extended(true)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= tick_rate:
		_timer = 0.0
		hitbox.reset_hits()
		_trigger_spike_thrust()

func _trigger_spike_thrust() -> void:
	var tween: Tween = create_tween()
	spike_sprite.scale = Vector2(1.22, 1.22)
	tween.tween_property(spike_sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(0.9, 0.25, 0.25), 3)

func _set_extended(ext: bool) -> void:
	_is_extended = ext
	var tex: Texture2D = SpriteGenerator.get_trap_texture(ext)
	if tex != null and spike_sprite != null:
		spike_sprite.texture = tex
	if collision_shape != null:
		collision_shape.disabled = not ext
