class_name CutsceneScreen
extends Control

## Кат-сцена-заглушка (иллюстрация + сюжетный текст) при входе в замок и после победы над боссом

signal cutscene_completed

@onready var title_label: Label = %TitleLabel
@onready var narrative_label: Label = %NarrativeLabel
@onready var illustration_rect: ColorRect = %IllustrationRect
@onready var continue_btn: Button = %ContinueBtn

var on_complete_callback: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_btn.pressed.connect(_on_continue_pressed)

func show_entry_cutscene(callback: Callable = Callable()) -> void:
	on_complete_callback = callback
	title_label.text = "ВХОД В ЗАМОК РЫЦАРЯ-СКЕЛЕТА"
	title_label.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	
	narrative_label.text = "Тяжёлые железные врата с глухим стоном захлопнулись за вашей спиной.\n\n" + \
		"Запах вековой пыли, тёмной некромантии и пролитой крови наполняет залы древнего замка. " + \
		"В тенях коридоров мерцают глазницы нежити, а далеко в тронном зале раздаётся мерный лязг металла...\n\n" + \
		"Проклятый Рыцарь ждёт своего избавителя."
	
	illustration_rect.color = Color(0.18, 0.14, 0.26, 1.0)
	visible = true

func show_victory_cutscene(callback: Callable = Callable()) -> void:
	on_complete_callback = callback
	title_label.text = "ПАДЕНИЕ ПРОКЛЯТОГО РЫЦАРЯ"
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	
	narrative_label.text = "С последним ударом Рыцарь-скелет опускается на колени и рассыпается в серый пепел. " + \
		"Его проклятый клинок раскалывается надвое, озаряя тронный зал призрачным светом.\n\n" + \
		"За троном открывается Великая Развилка двух стихий: " + \
		"один путь ведёт в ледяную мглу Мира холода, другой — в пылающее жерло Мира огня.\n\n" + \
		"Судьба вашего пути зависит от выбора."
		
	illustration_rect.color = Color(0.28, 0.2, 0.15, 1.0)
	visible = true

func _on_continue_pressed() -> void:
	cutscene_completed.emit()
	if on_complete_callback.is_valid():
		on_complete_callback.call()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("interact") or event.is_action_just_pressed("ui_accept"):
		_on_continue_pressed()
