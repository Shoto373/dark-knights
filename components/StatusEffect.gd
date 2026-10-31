class_name StatusEffect
extends Resource

## Ресурс описания статус-эффекта (заморозка, горение, яд, оглушение)

enum EffectType { FREEZE, BURN, POISON, STUN }

@export var id: String = "freeze"
@export var name: String = "Заморозка"
@export var effect_type: EffectType = EffectType.FREEZE
@export var duration: float = 3.0
@export var tick_interval: float = 0.5
@export var damage_per_tick: int = 5
@export var speed_multiplier: float = 0.65
@export var max_stacks: int = 3
@export var color: Color = Color(0.4, 0.8, 1.0, 1.0)

