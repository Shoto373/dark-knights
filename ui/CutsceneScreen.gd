class_name CutsceneScreen
extends CanvasLayer

## Кат-сцена (сюжетный текст + темная фэнтезийная иллюстрация) при входе в замок и после победы над боссом

signal cutscene_completed

@onready var title_label: Label = %TitleLabel
@onready var narrative_label: Label = %NarrativeLabel
@onready var illustration_icon: TextureRect = %IllustrationIcon
@onready var continue_btn: Button = %ContinueBtn

var on_complete_callback: Callable
var _can_skip: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	continue_btn.pressed.connect(_on_continue_pressed)
	
	# Дебаунс ввода: 0.25 сек блокируем скип, чтобы нажатие [F] на портале не закрыло кат-сцену моментально
	get_tree().create_timer(0.25, true, false, true).timeout.connect(func():
		_can_skip = true
	)

func show_entry_cutscene(callback: Callable = Callable()) -> void:
	on_complete_callback = callback
	title_label.text = "ВХОД В ЗАМОК РЫЦАРЯ-СКЕЛЕТА"
	title_label.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	
	narrative_label.text = "Тяжёлые кованые врата с глухим стоном захлопнулись за вашей спиной.\n\n" + \
		"Запах вековой пыли, тёмной некромантии и пролитой крови наполняет залы древнего замка. " + \
		"В тенях коридоров мерцают глазницы нежити, а далеко в тронном зале раздаётся мерный лязг проклятой стали...\n\n" + \
		"Проклятый Рыцарь ждёт своего избавителя."

func show_victory_cutscene(callback: Callable = Callable()) -> void:
	on_complete_callback = callback
	title_label.text = "ПАДЕНИЕ ПРОКЛЯТОГО РЫЦАРЯ"
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	
	narrative_label.text = "С последним ударом Рыцарь-скелет опускается на колени и рассыпается в серый пепел. " + \
		"Его проклятый клинок раскалывается надвое, озаряя тронный зал призрачным пламенем.\n\n" + \
		"За троном открывается Великая Развилка двух стихий: " + \
		"один путь ведёт в ледяную мглу Мира холода, другой — в пылающее жерло Мира огня.\n\n" + \
		"Судьба вашего пути зависит от вашего выбора."

func _on_continue_pressed() -> void:
	if not _can_skip:
		return
	if is_instance_valid(AudioManager):
		AudioManager.play_sfx_named("swing")
	get_tree().paused = false
	cutscene_completed.emit()
	if on_complete_callback.is_valid():
		on_complete_callback.call()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not _can_skip:
		return
	if event.is_action_just_pressed("interact") or event.is_action_just_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE)):
		get_viewport().set_input_as_handled()
		_on_continue_pressed()
