class_name HurtboxComponent
extends Area2D

## Компонент получения урона (Принимает атаки от HitboxComponent)

signal hit_received(damage: int, is_crit: bool, hitbox: HitboxComponent)

@export var health_component: HealthComponent
@export var movement_component: MovementComponent
@export var armor: int = 0
@export var is_player_hurtbox: bool = false:
	set(val):
		is_player_hurtbox = val
		_update_collision_masks()

func _ready() -> void:
	_update_collision_masks()
	area_entered.connect(_on_area_entered)
	if health_component == null:
		health_component = get_node_or_null("HealthComponent") as HealthComponent
	if movement_component == null:
		movement_component = get_node_or_null("MovementComponent") as MovementComponent

func _update_collision_masks() -> void:
	collision_layer = 0
	# Слой 4 (8) — player_hitbox, Слой 5 (16) — enemy_hitbox
	if is_player_hurtbox:
		collision_mask = 16 # Слушает только атаки врагов
	else:
		collision_mask = 8  # Слушает только атаки игрока

func _on_area_entered(area: Area2D) -> void:
	if not (area is HitboxComponent):
		return
	
	var hitbox: HitboxComponent = area as HitboxComponent
	var parent_node: Node = owner if owner != null else get_parent()
	
	if not hitbox.can_hit(parent_node):
		return
	
	if health_component != null and (health_component.is_invulnerable or health_component.is_dead):
		return
	
	var is_crit: bool = DamageCalculator.roll_crit(hitbox.crit_chance)
	var final_damage: int = DamageCalculator.calculate_damage(
		hitbox.base_damage,
		hitbox.damage_multiplier,
		hitbox.crit_multiplier,
		is_crit,
		armor
	)
	
	hitbox.register_hit(parent_node)
	
	if health_component != null:
		health_component.take_damage(final_damage)
	
	if movement_component != null and hitbox.knockback_force > 0:
		var knock_dir: Vector2 = hitbox.get_knockback_direction(global_position)
		var resistance: float = 0.0
		if "enemy_data" in parent_node and parent_node.enemy_data != null:
			resistance = clampf(parent_node.enemy_data.knockback_resistance, 0.0, 1.0)
		elif parent_node.is_in_group("bosses") or parent_node.name.ends_with("Boss"):
			resistance = 0.85
		
		var effective_force: float = hitbox.knockback_force * (1.0 - resistance)
		if effective_force > 1.0:
			movement_component.apply_knockback(knock_dir * effective_force)
	
	# Наложение статус-эффектов
	var effect_mgr: StatusEffectManager = parent_node.get_node_or_null("StatusEffectManager") as StatusEffectManager
	if effect_mgr != null:
		if hitbox.applied_effect != null:
			effect_mgr.apply_effect(hitbox.applied_effect, hitbox.effect_stacks)
		elif hitbox.damage_type == "fire" or hitbox.tags.has("fire"):
			var burn_res: StatusEffect = load("res://data/status_effects/burn.tres") as StatusEffect
			if burn_res != null:
				effect_mgr.apply_effect(burn_res, 1)
		elif hitbox.damage_type == "freeze" or hitbox.tags.has("freeze") or hitbox.tags.has("ice") or hitbox.tags.has("frost"):
			var freeze_res: StatusEffect = load("res://data/status_effects/freeze.tres") as StatusEffect
			if freeze_res != null:
				effect_mgr.apply_effect(freeze_res, 1)
	
	# Эффекты попадания через EventBus
	EventBus.damage_dealt.emit(parent_node as Node2D, final_damage, is_crit)
	EventBus.hit_stop_requested.emit(50.0)
	
	var shake_power: float = 6.0 if is_crit else 3.5
	EventBus.screen_shake_requested.emit(shake_power, 0.15)
	
	hit_received.emit(final_damage, is_crit, hitbox)

