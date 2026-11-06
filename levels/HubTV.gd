class_name HubTV
extends Area2D

## Интерактивный магический ретро-телевизор в Хабе
## Переключает каналы при нажатии [F], показывает статистику, новости и шутки из подземелий

@onready var tv_sprite: Sprite2D = %TVSprite
@onready var screen_glow: Sprite2D = %ScreenGlow
@onready var prompt_label: Label = %PromptLabel
@onready var broadcast_label: Label = %BroadcastLabel
@onready var broadcast_panel: Control = %BroadcastPanel

var tv_light: PointLight2D = null
var is_player_inside: bool = false
var current_channel: int = 0
var _flicker_phase: float = 0.0

const CHANNELS: Array[Dictionary] = [
	{
		"name": "📺 ХРОНИКИ ПОДЗЕМЕЛЬЯ",
		"desc": "Вождь гоблинов объявил скидки на шипованные дубины в 1-м биоме!",
		"color": Color(0.2, 0.8, 1.0)
	},
	{
		"name": "📊 СТАТИСТИКА ЗАБЕГА",
		"desc": "Зал славы Ордена Рыцарей: Души на счету, победы над тьмой!",
		"color": Color(0.3, 1.0, 0.5)
	},
	{
		"name": "❄️ ПРОГНОЗ ПОГОДЫ",
		"desc": "Мир Холода: -48°C, пурга и ледяные штормы. Мир Огня: +1200°C, лавовый дождь.",
		"color": Color(1.0, 0.55, 0.15)
	},
	{
		"name": "🔮 ВЕЩАНИЕ ЧИСТИЛИЩА",
		"desc": "Ш-ш-ш... Таинственный Владыка сквозь помехи наблюдает за вашим прогрессом...",
		"color": Color(0.85, 0.35, 1.0)
	},
	{
		"name": "⚔️ СОВЕТЫ ВЫЖИВАНИЯ",
		"desc": "Следопыт рекомендует: используйте перекат (Shift), чтобы избегать урона боссов!",
		"color": Color(1.0, 0.9, 0.25)
	}
]

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Слушает игрока (слой 2)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	prompt_label.visible = false
	broadcast_panel.visible = false
	
	if tv_light == null and SettingsManager.dynamic_lighting_enabled:
		tv_light = LightTextureGenerator.create_point_light(Color(0.2, 0.8, 1.0), 0.85, 2.2)
		tv_light.name = "TVPointLight"
		tv_light.position = Vector2(0, 16.0)
		add_child(tv_light)
	
	_apply_channel(current_channel, false)

func _process(delta: float) -> void:
	_flicker_phase += delta * 14.0
	if screen_glow != null:
		var flicker: float = 0.82 + sin(_flicker_phase) * 0.12 + randf() * 0.06
		screen_glow.modulate.a = clampf(flicker * 0.45, 0.2, 0.6)
	if tv_light != null and tv_light.visible:
		var flicker_light: float = 0.80 + sin(_flicker_phase * 1.5) * 0.12 + randf() * 0.08
		tv_light.energy = flicker_light * 0.85

	if is_player_inside and Input.is_action_just_pressed("interact"):
		_next_channel()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_inside = true
		prompt_label.visible = true
		broadcast_panel.visible = true
		_update_broadcast_text()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_inside = false
		prompt_label.visible = false
		broadcast_panel.visible = false

func _next_channel() -> void:
	current_channel = (current_channel + 1) % CHANNELS.size()
	_apply_channel(current_channel, true)

func _apply_channel(idx: int, play_fx: bool) -> void:
	var ch: Dictionary = CHANNELS[idx]
	var ch_col: Color = ch["color"]
	
	if screen_glow != null:
		screen_glow.modulate = Color(ch_col.r, ch_col.g, ch_col.b, 0.45)
	if tv_light != null:
		tv_light.color = ch_col.lightened(0.2)
	
	_update_broadcast_text()
	
	if play_fx:
		AudioManager.play_sfx_named("click")
		# Вспышка экрана при переключении
		var tween: Tween = create_tween()
		if tv_sprite != null:
			tv_sprite.modulate = Color(1.8, 1.8, 2.0)
			tween.tween_property(tv_sprite, "modulate", Color.WHITE, 0.15)
		EffectsHelper.spawn_hit_sparks(get_parent(), global_position + Vector2(0, -6), ch_col, 6)

func _update_broadcast_text() -> void:
	var ch: Dictionary = CHANNELS[current_channel]
	var title_text: String = ch["name"]
	var body_text: String = ch["desc"]
	
	# Динамические данные для канала статистики
	if current_channel == 1:
		body_text = "Душ Ордена: %d  |  Золото забега: %d  |  Ключей: %d" % [MetaProgress.souls, GameState.gold, GameState.keys]
	
	broadcast_label.text = "%s\n%s" % [title_text, body_text]
	broadcast_label.add_theme_color_override("font_color", ch["color"])

