class_name TrapSpikes
extends Node2D

## Ловушка с шипами для проверки получения урона игроком

@onready var hitbox: HitboxComponent = %HitboxComponent

@export var damage: int = 20
@export var tick_rate: float = 1.0

var _timer: float = 0.0

func _ready() -> void:
	hitbox.base_damage = damage
	hitbox.is_player_hitbox = false
	hitbox.source_owner = self

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= tick_rate:
		_timer = 0.0
		hitbox.reset_hits()

