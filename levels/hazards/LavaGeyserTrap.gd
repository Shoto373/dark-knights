class_name LavaGeyserTrap
extends Node2D

## Лавовый гейзер: периодически извергающийся столб магмы
## Цикл: Спячка -> Бурление (предупреждение) -> Извержение (урон и горение)

enum GeyserState { DORMANT, BUBBLING, ERUPTING }

@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var crater_visual: ColorRect = %CraterVisual
@onready var bubble_visual: ColorRect = %BubbleVisual
@onready var eruption_visual: ColorRect = %EruptionVisual

@export var damage: int = 22
@export var cycle_dormant_time: float = 2.2
@export var cycle_bubbling_time: float = 0.8
@export var cycle_erupt_time: float = 1.0

var current_state: GeyserState = GeyserState.DORMANT
var state_timer: float = 0.0

func _ready() -> void:
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = false
	hitbox.source_owner = self
	hitbox.damage_type = "fire"
	hitbox.tags = ["fire"]
	collision_shape.disabled = true
	
	bubble_visual.visible = false
	eruption_visual.visible = false
	state_timer = cycle_dormant_time

func _physics_process(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		match current_state:
			GeyserState.DORMANT:
				_set_state(GeyserState.BUBBLING)
			GeyserState.BUBBLING:
				_set_state(GeyserState.ERUPTING)
			GeyserState.ERUPTING:
				_set_state(GeyserState.DORMANT)

func _set_state(new_state: GeyserState) -> void:
	current_state = new_state
	match current_state:
		GeyserState.DORMANT:
			state_timer = cycle_dormant_time
			bubble_visual.visible = false
			eruption_visual.visible = false
			collision_shape.disabled = true
		GeyserState.BUBBLING:
			state_timer = cycle_bubbling_time
			bubble_visual.visible = true
			eruption_visual.visible = false
			collision_shape.disabled = true
			var tween: Tween = create_tween().set_loops(3)
			tween.tween_property(bubble_visual, "scale", Vector2(1.2, 1.2), cycle_bubbling_time / 6.0)
			tween.tween_property(bubble_visual, "scale", Vector2(0.9, 0.9), cycle_bubbling_time / 6.0)
		GeyserState.ERUPTING:
			state_timer = cycle_erupt_time
			bubble_visual.visible = false
			eruption_visual.visible = true
			collision_shape.disabled = false
			hitbox.reset_hits()
			EventBus.screen_shake_requested.emit(6.0, 0.25)
			EffectsHelper.spawn_shockwave(get_parent(), global_position, 130.0, 0.32, 0.045)
			EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(1.0, 0.65, 0.15), 10)
			
			eruption_visual.scale = Vector2(0.6, 0.2)
			var erupt_tween: Tween = create_tween()
			erupt_tween.tween_property(eruption_visual, "scale", Vector2(1.1, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			erupt_tween.tween_property(eruption_visual, "scale", Vector2(1.0, 1.0), 0.15)

