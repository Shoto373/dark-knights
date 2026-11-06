class_name HubSofa
extends Area2D

## Интерактивный бархатный диван в Хабе
## Позволяет игроку присесть отдохнуть, восстанавливает здоровье и показывает частицы уюта

@onready var prompt_label: Label = %PromptLabel
@onready var sofa_sprite: Sprite2D = %SofaSprite

var is_player_inside: bool = false
var is_player_resting: bool = false
var player_ref: Player = null
var _heal_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Слушает игрока (слой 2)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	prompt_label.visible = false

func _process(delta: float) -> void:
	if is_player_inside and not is_player_resting and Input.is_action_just_pressed("interact"):
		_start_resting()
	elif is_player_resting:
		var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input != Vector2.ZERO or Input.is_action_just_pressed("interact"):
			_stop_resting()
		else:
			_heal_timer += delta
			if _heal_timer >= 1.0:
				_heal_timer = 0.0
				if is_instance_valid(player_ref) and player_ref.health_component:
					player_ref.health_component.heal(15)
					EffectsHelper.spawn_hit_sparks(get_parent(), global_position + Vector2(0, -10), Color(0.4, 1.0, 0.5), 4)

func _start_resting() -> void:
	if not is_instance_valid(player_ref):
		return
	is_player_resting = true
	prompt_label.text = "Отдыхаем... [WASD] чтобы встать"
	AudioManager.play_sfx_named("pickup")
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position, Color(1.0, 0.85, 0.4), 8)
	
	# Плавная анимация усаживания
	var tween: Tween = create_tween()
	player_ref.global_position = global_position + Vector2(0, -6)
	player_ref.velocity = Vector2.ZERO
	if sofa_sprite != null:
		sofa_sprite.scale = Vector2(1.22, 1.1)
		tween.tween_property(sofa_sprite, "scale", Vector2(1.2, 1.2), 0.15)

func _stop_resting() -> void:
	is_player_resting = false
	prompt_label.text = "[F] Присесть отдохнуть"

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_inside = true
		player_ref = body as Player
		prompt_label.text = "[F] Присесть отдохнуть"
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_inside = false
		is_player_resting = false
		player_ref = null
		prompt_label.visible = false

