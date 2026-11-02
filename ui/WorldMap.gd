class_name WorldMap
extends CanvasLayer

## Экран интерактивной карты мира: узлы, пройденный путь, текущая позиция и выбор развилок

signal path_chosen(node: WorldNodeData)

@onready var graph_canvas: Control = %GraphCanvas
@onready var nodes_container: Control = %NodesContainer
@onready var details_panel: PanelContainer = %DetailsPanel
@onready var node_title_label: Label = %NodeTitleLabel
@onready var node_desc_label: Label = %NodeDescLabel
@onready var biome_info_label: Label = %BiomeInfoLabel
@onready var select_path_button: Button = %SelectPathButton
@onready var close_button: Button = %CloseButton
@onready var mode_label: Label = %ModeLabel

var is_choice_mode: bool = false
var world_graph: WorldGraph
var selected_node: WorldNodeData = null
var current_node: WorldNodeData = null
var visited_nodes: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	world_graph = GameState.world_graph if GameState.world_graph != null else WorldGraph.new()
	current_node = GameState.current_world_node
	visited_nodes = GameState.visited_world_nodes
	
	close_button.pressed.connect(_on_close_pressed)
	select_path_button.pressed.connect(_on_select_path_pressed)
	graph_canvas.draw.connect(_on_graph_canvas_draw)
	
	_refresh_display()

func set_mode(choice_mode: bool) -> void:
	is_choice_mode = choice_mode
	if is_inside_tree():
		_refresh_display()

func _refresh_display() -> void:
	if is_choice_mode:
		mode_label.text = "ВЫБЕРИТЕ СЛЕДУЮЩИЙ ПУТЬ"
		mode_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		close_button.visible = false
	else:
		mode_label.text = "КАРТА МИРА"
		mode_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		close_button.visible = true
	
	_build_node_widgets()
	graph_canvas.queue_redraw()
	
	# По умолчанию выбираем текущую или первую доступную ноду
	if is_choice_mode and current_node != null and not current_node.next_nodes.is_empty():
		_select_node(current_node.next_nodes[0])
	elif current_node != null:
		_select_node(current_node)
	elif world_graph.get_node("goblin_dungeon") != null:
		_select_node(world_graph.get_node("goblin_dungeon"))

func _build_node_widgets() -> void:
	for child in nodes_container.get_children():
		child.queue_free()
	
	var all_nodes: Dictionary = world_graph.get_all_nodes()
	for node_id in all_nodes.keys():
		var node_data: WorldNodeData = all_nodes[node_id]
		_create_node_widget(node_data)

func _create_node_widget(data: WorldNodeData) -> void:
	var btn: Button = Button.new()
	nodes_container.add_child(btn)
	btn.custom_minimum_size = Vector2(96, 64)
	btn.position = data.map_position - Vector2(48, 32)
	btn.text = "%s\n%s" % [data.icon_symbol, data.name]
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 10)
	
	var is_current: bool = (current_node != null and current_node.id == data.id)
	var is_visited: bool = visited_nodes.has(data.id)
	var is_selectable: bool = (is_choice_mode and current_node != null and current_node.next_nodes.has(data))
	
	# Стилизация кнопки узла в dark fantasy стиле
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_right = 6
	box.corner_radius_bottom_left = 6
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	
	if is_current:
		box.bg_color = Color(0.2, 0.18, 0.08, 0.95)
		box.border_color = Color(1.0, 0.85, 0.25, 1.0) # Золото
		btn.text += "\n[ВЫ ЗДЕСЬ]"
	elif is_visited:
		box.bg_color = Color(0.08, 0.16, 0.1, 0.9)
		box.border_color = Color(0.3, 0.85, 0.4, 0.9) # Зеленая рамка
		btn.text += "\n✓"
	elif is_selectable:
		box.bg_color = Color(0.08, 0.18, 0.28, 0.95)
		box.border_color = Color(0.3, 0.8, 1.0, 1.0) # Лазурный выбор
		btn.text += "\n[ВЫБРАТЬ]"
	else:
		box.bg_color = Color(0.08, 0.09, 0.12, 0.8)
		box.border_color = Color(0.35, 0.38, 0.45, 0.6) # Приглушенный узел
		
	btn.add_theme_stylebox_override("normal", box)
	btn.pressed.connect(func(): _select_node(data))

func _select_node(data: WorldNodeData) -> void:
	selected_node = data
	node_title_label.text = "%s %s" % [data.icon_symbol, data.name]
	node_desc_label.text = data.description
	
	var biome_name: String = data.biome.name if data.biome != null else "Неизвестно"
	biome_info_label.text = "Биом: %s | Этажей: %d" % [biome_name, data.floors_count]
	if data.is_final:
		biome_info_label.text += " | [ФИНАЛЬНЫЙ РУБЕЖ]"
	
	# Кнопка перехода активна только для допустимых следующих узлов
	var can_travel: bool = false
	if is_choice_mode and current_node != null:
		can_travel = current_node.next_nodes.has(data)
	
	select_path_button.visible = is_choice_mode
	select_path_button.disabled = not can_travel

func _on_graph_canvas_draw() -> void:
	if world_graph == null:
		return
	
	var all_nodes: Dictionary = world_graph.get_all_nodes()
	for node_id in all_nodes.keys():
		var from_node: WorldNodeData = all_nodes[node_id]
		for to_node in from_node.next_nodes:
			if to_node == null:
				continue
			
			var is_path_traversed: bool = visited_nodes.has(from_node.id) and visited_nodes.has(to_node.id)
			var line_color: Color = Color(0.9, 0.8, 0.3, 0.9) if is_path_traversed else Color(0.25, 0.3, 0.4, 0.5)
			var line_width: float = 3.5 if is_path_traversed else 1.8
			
			graph_canvas.draw_line(from_node.map_position, to_node.map_position, line_color, line_width)

func _on_select_path_pressed() -> void:
	if selected_node != null:
		get_tree().paused = false
		path_chosen.emit(selected_node)
		GameState.advance_to_world_node(selected_node)
		queue_free()

func _on_close_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _input(event: InputEvent) -> void:
	if not is_inside_tree() or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			if not is_choice_mode:
				_on_close_pressed()
				get_viewport().set_input_as_handled()
