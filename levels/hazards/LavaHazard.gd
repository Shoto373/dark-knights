class_name LavaHazard
extends Area2D

## Опасная зона лавы: наносит периодический урон и поджигает находящихся в ней

@export var tick_damage: int = 6
@export var tick_interval: float = 0.5
@export var lifetime: float = -1.0 # < 0 для постоянных зон, > 0 для временных луж

@onready var visual_lava: ColorRect = get_node_or_null("VisualLava") as ColorRect

var overlapping_bodies: Array[Node2D] = []
var damage_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4 # Player (2) и Enemies (4)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if lifetime > 0.0:
		var tween: Tween = create_tween()
		tween.tween_interval(lifetime)
		tween.tween_property(self, "modulate:a", 0.0, 0.4)
		tween.chain().tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_tick_damage()

func _on_body_entered(body: Node2D) -> void:
	if not overlapping_bodies.has(body):
		overlapping_bodies.append(body)
		_apply_lava_effects(body)

func _on_body_exited(body: Node2D) -> void:
	overlapping_bodies.erase(body)

func _tick_damage() -> void:
	# Очищаем невалидные ссылки
	overlapping_bodies = overlapping_bodies.filter(func(b): return is_instance_valid(b))
	for body in overlapping_bodies:
		_apply_lava_effects(body)

func _apply_lava_effects(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	
	# Проверка иммунитета к огню и лаве (например сапоги магмы или статус иммунитета)
	if is_body_immune(body):
		return
	
	var hc: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
	if hc != null and not hc.is_dead:
		hc.take_damage(tick_damage, true) # Игнорируем обычные iframes
		EventBus.damage_dealt.emit(body, tick_damage, false)
	
	var sem: StatusEffectManager = body.get_node_or_null("StatusEffectManager") as StatusEffectManager
	if sem != null:
		var burn_res: StatusEffect = load("res://data/status_effects/burn.tres") as StatusEffect
		if burn_res != null:
			sem.apply_effect(burn_res, 1)

func is_body_immune(body: Node2D) -> bool:
	if body is Player:
		var p: Player = body as Player
		if p.has_node("StatusEffectManager"):
			var p_sem: StatusEffectManager = p.get_node("StatusEffectManager") as StatusEffectManager
			if p_sem != null and (p_sem.immunities.has("burn") or p_sem.immunities.has("fire")):
				return true
	
	var sem: StatusEffectManager = body.get_node_or_null("StatusEffectManager") as StatusEffectManager
	if sem != null and (sem.immunities.has("burn") or sem.immunities.has("fire")):
		return true
		
	return false

