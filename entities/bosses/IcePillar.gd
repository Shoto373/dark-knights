class_name IcePillar
extends StaticBody2D

## Ледяная колонна, призываемая Королем-личом.
## Периодически испускает морозные импульсы с эффектом заморозки.

const PROJECTILE_SCENE = preload("res://entities/player/Projectile.tscn")

@onready var health_component: HealthComponent = %HealthComponent
@onready var hurtbox_component: HurtboxComponent = %HurtboxComponent
@onready var visuals: Node2D = %Visuals
@onready var pulse_timer: Timer = %PulseTimer

func _ready() -> void:
	collision_layer = 1 | 4 # World + enemy
	collision_mask = 0
	
	hurtbox_component.health_component = health_component
	hurtbox_component.is_player_hurtbox = false
	
	health_component.max_health = 50
	health_component.reset(50)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	pulse_timer.timeout.connect(_emit_frost_pulse)
	pulse_timer.start(2.5)

func _on_damaged(_amount: int, _cur: int, _max_hp: int) -> void:
	var tween: Tween = create_tween()
	visuals.modulate = Color(2.5, 3.0, 3.5, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)

func _emit_frost_pulse() -> void:
	var flash: Tween = create_tween()
	visuals.modulate = Color(1.5, 2.5, 3.5, 1.0)
	flash.tween_property(visuals, "modulate", Color.WHITE, 0.25)
	
	for i in range(4):
		var angle: float = (PI / 2.0) * i
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 20.0
		proj.setup(
			dir,
			220.0,
			10,
			false,
			260.0,
			120.0,
			Color(0.4, 0.85, 1.0, 1.0),
			"freeze",
			["frost", "ice"]
		)

func _on_died() -> void:
	pulse_timer.stop()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.chain().tween_callback(queue_free)
