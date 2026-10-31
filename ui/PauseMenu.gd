class_name PauseMenu
extends CanvasLayer

## Меню паузы с отображением seed забега и списка артефактов (инвентарь)

@onready var menu_panel: Control = %MenuPanel
@onready var seed_label: Label = %SeedLabel
@onready var floor_label: Label = %FloorLabel
@onready var items_container: VBoxContainer = %ItemsContainer
@onready var btn_resume: Button = %BtnResume
@onready var btn_world_map: Button = %BtnWorldMap
@onready var btn_settings: Button = %BtnSettings
@onready var btn_back_hub: Button = %BtnBackHub
@onready var btn_quit: Button = %BtnQuit

const SETTINGS_DIALOG_SCENE: PackedScene = preload("res://ui/SettingsDialog.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_panel.visible = false
	btn_resume.pressed.connect(_resume)
	btn_world_map.pressed.connect(_open_world_map)
	if btn_settings:
		btn_settings.pressed.connect(_open_settings)
	btn_back_hub.pressed.connect(_back_to_hub)
	if btn_quit:
		btn_quit.pressed.connect(_quit_game)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			# Если открыто дочернее окно (Настройки или Карта мира) — закрываем сначала его
			for child in get_children():
				if child is SettingsDialog or child is WorldMap:
					child.queue_free()
					get_viewport().set_input_as_handled()
					return
				elif child.name == "WorldMap" or child.name == "SettingsDialog":
					child.queue_free()
					get_viewport().set_input_as_handled()
					return
			
			toggle_pause()
			get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if menu_panel.visible:
		_resume()
	else:
		_pause()

func _pause() -> void:
	var is_in_hub: bool = (not GameState.is_run_active or GameState.current_world_node_id == "hub")
	if is_in_hub:
		seed_label.text = "Хаб героев"
		floor_label.text = "Локация: Обитель рыцарей"
		btn_back_hub.text = "В Главное меню"
		btn_world_map.visible = false
	else:
		seed_label.text = "Seed: %d" % GameState.current_seed
		floor_label.text = "Этаж: %d | Локация: %s" % [GameState.current_floor_index, GameState.current_world_node_id]
		btn_back_hub.text = "Завершить забег (В Хаб)"
		btn_world_map.visible = true

	_update_inventory_display()
	menu_panel.visible = true
	get_tree().paused = true

func _update_inventory_display() -> void:
	for child in items_container.get_children():
		child.queue_free()
	
	if GameState.inventory_items.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Инвентарь пуст"
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_container.add_child(empty_lbl)
		return
	
	for inv in GameState.inventory_items:
		var item_ref: ItemData = inv.get("item_ref") as ItemData
		if item_ref == null and inv.has("id"):
			var p: String = "res://data/items/%s.tres" % inv["id"]
			if ResourceLoader.exists(p):
				item_ref = load(p) as ItemData
		
		var row: HBoxContainer = HBoxContainer.new()
		var name_lbl: Label = Label.new()
		name_lbl.text = item_ref.name if item_ref else inv.get("name", "Предмет")
		name_lbl.add_theme_font_size_override("font_size", 12)
		if item_ref:
			name_lbl.add_theme_color_override("font_color", item_ref.get_rarity_color())
		row.add_child(name_lbl)
		
		var desc_lbl: Label = Label.new()
		desc_lbl.text = " — " + (item_ref.description if item_ref else "")
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		row.add_child(desc_lbl)
		
		items_container.add_child(row)

func _resume() -> void:
	menu_panel.visible = false
	get_tree().paused = false

func _open_world_map() -> void:
	var map_scene: PackedScene = load("res://ui/WorldMap.tscn")
	if map_scene != null:
		var map_inst = map_scene.instantiate()
		add_child(map_inst)
		if map_inst.has_method("set_mode"):
			map_inst.set_mode(false)

func _open_settings() -> void:
	var dialog: SettingsDialog = SETTINGS_DIALOG_SCENE.instantiate() as SettingsDialog
	add_child(dialog)

func _back_to_hub() -> void:
	_resume()
	var is_in_hub: bool = (not GameState.is_run_active or GameState.current_world_node_id == "hub")
	if is_in_hub:
		SceneRouter.change_scene("res://ui/MainMenu.tscn", 0.3)
	else:
		GameState.end_run(false)
		SceneRouter.change_scene("res://levels/Hub.tscn", 0.3)

func _quit_game() -> void:
	get_tree().quit()
