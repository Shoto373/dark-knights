class_name HeroPedestal
extends Area2D

## Пьедестал выбора героя в Хабе с готическим каменным основанием и сияющим руническим кругом

@export var hero_data: HeroData

@onready var statue_visual: ColorRect = %StatueVisual
@onready var hero_name_label: Label = %HeroNameLabel
@onready var interaction_label: Label = %InteractionLabel
@onready var selection_ring: ColorRect = %SelectionRing
@onready var rune_dais: Node2D = %RuneDais

var is_player_inside: bool = false
var player_ref: Player = null
var hero_sprite: Sprite2D = null
var _is_selected: bool = false
var _anim_phase: float = 0.0

func _ready() -> void:
	# Коллизия для взаимодействия с игроком (слой 2)
	collision_layer = 0
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if rune_dais != null and not rune_dais.draw.is_connected(_on_rune_dais_draw):
		rune_dais.draw.connect(_on_rune_dais_draw)
	
	_update_display()

func _update_display() -> void:
	if hero_data == null:
		return
	
	hero_name_label.text = hero_data.name
	var h_col: Color = hero_data.color
	
	# Установка детального спрайта статуи героя
	var hero_tex: Texture2D = SpriteGenerator.get_hero_texture(hero_data.id)
	if hero_tex != null:
		if hero_sprite == null:
			hero_sprite = get_node_or_null("HeroSprite") as Sprite2D
		if hero_sprite == null:
			hero_sprite = Sprite2D.new()
			hero_sprite.name = "HeroSprite"
			hero_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			hero_sprite.scale = Vector2(1.25, 1.25)
			hero_sprite.position = Vector2(0, -22)
			add_child(hero_sprite)
		hero_sprite.texture = hero_tex
		if statue_visual != null:
			statue_visual.visible = false
	
	var is_unlocked: bool = hero_data.unlocked_by_default or MetaProgress.is_hero_unlocked(hero_data.id)
	var is_active: bool = (GameState.selected_hero_id == hero_data.id)
	_is_selected = is_active
	
	if selection_ring != null:
		selection_ring.visible = false
	
	if rune_dais != null:
		rune_dais.queue_redraw()
	
	if not is_unlocked:
		if statue_visual != null:
			statue_visual.color = Color(0.3, 0.3, 0.3, 0.7)
		if hero_sprite != null:
			hero_sprite.modulate = Color(0.3, 0.3, 0.35, 0.8)
		if is_player_inside:
			interaction_label.text = "[F] Разблокировать (%d душ)" % hero_data.unlock_cost_souls
			interaction_label.visible = true
		else:
			interaction_label.text = "Закрыто (%d душ)" % hero_data.unlock_cost_souls
			interaction_label.visible = true
	else:
		if hero_sprite != null:
			hero_sprite.modulate = Color.WHITE
		if is_active:
			interaction_label.text = "Выбран"
			interaction_label.visible = true
		elif is_player_inside:
			interaction_label.text = "[F] Выбрать"
			interaction_label.visible = true
		else:
			interaction_label.visible = false
	
	# Стилизация рамки плашки под цвет героя
	var name_box: StyleBoxFlat = hero_name_label.get_theme_stylebox("normal") as StyleBoxFlat
	if name_box != null:
		name_box.border_color = Color(h_col.r, h_col.g, h_col.b, 0.9)

func _process(delta: float) -> void:
	_anim_phase += delta * 2.5
	if hero_sprite != null:
		var float_offset: float = sin(_anim_phase) * (2.0 if _is_selected else 1.0)
		hero_sprite.position.y = -22.0 + float_offset
	
	if _is_selected and rune_dais != null:
		rune_dais.queue_redraw()
	
	if is_player_inside and Input.is_action_just_pressed("interact"):
		_interact()

func _on_rune_dais_draw() -> void:
	if not _is_selected:
		return
	
	# Отрисовка магического круга на полу под пьедесталом
	var h_col: Color = hero_data.color if hero_data else Color(0.3, 0.85, 1.0)
	var pulse: float = 0.85 + sin(_anim_phase * 1.5) * 0.15
	var center: Vector2 = Vector2(0, 10)
	var ring_color: Color = Color(h_col.r, h_col.g, h_col.b, 0.75 * pulse)
	var core_color: Color = Color(1.0, 1.0, 1.0, 0.9 * pulse)
	
	# Внешнее и внутреннее кольцо
	rune_dais.draw_arc(center, 26.0 * pulse, 0.0, TAU, 36, ring_color, 2.0, true)
	rune_dais.draw_arc(center, 21.0, 0.0, TAU, 32, Color(ring_color.r, ring_color.g, ring_color.b, 0.4), 1.0, true)
	
	# Кардинальные рунические маркеры
	var angles: Array[float] = [0.0, PI * 0.5, PI, PI * 1.5]
	for a in angles:
		var pt: Vector2 = center + Vector2(cos(a), sin(a)) * 26.0 * pulse
		rune_dais.draw_circle(pt, 2.2, core_color)

func _interact() -> void:
	if hero_data == null:
		return
	
	var is_unlocked: bool = hero_data.unlocked_by_default or MetaProgress.is_hero_unlocked(hero_data.id)
	if not is_unlocked:
		if MetaProgress.souls >= hero_data.unlock_cost_souls:
			MetaProgress.add_souls(-hero_data.unlock_cost_souls)
			MetaProgress.unlock_hero(hero_data.id)
			SaveManager.save_meta()
			_select_hero()
		else:
			# Недостаточно душ
			var tween: Tween = create_tween()
			interaction_label.text = "Недостаточно душ!"
			tween.tween_interval(1.0)
			tween.tween_callback(_update_display)
		return
	
	_select_hero()

func _select_hero() -> void:
	GameState.selected_hero_id = hero_data.id
	if is_instance_valid(player_ref):
		player_ref.apply_hero_data(hero_data)
	EventBus.hero_changed.emit(hero_data)
	
	# Звук и вспышка выбора
	AudioManager.play_sfx_named("cast")
	EffectsHelper.spawn_hit_sparks(get_parent(), global_position + Vector2(0, -10), hero_data.color, 12)
	
	# Обновляем все пьедесталы в Хабе
	for pedestal in get_tree().get_nodes_in_group("hero_pedestals"):
		if pedestal.has_method("_update_display"):
			pedestal._update_display()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_inside = true
		player_ref = body as Player
		_update_display()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_inside = false
		player_ref = null
		_update_display()
