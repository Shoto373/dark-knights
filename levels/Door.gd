class_name DungeonDoor
extends Area2D

## Темные готические ворота между комнатами подземелья
## Поддерживают уникальное архитектурное оформление под тип соседней комнаты (Boss, Treasure, Shop, Elite, Combat)

signal door_entered(direction: Vector2i)

@export var direction: Vector2i = Vector2i.UP
@export var is_open: bool = true:
	set(val):
		is_open = val
		_update_door_state()

@export var target_room_type: RoomData.RoomType = RoomData.RoomType.COMBAT:
	set(val):
		target_room_type = val
		_update_thematic_visuals()

@onready var barrier_collider: StaticBody2D = %BarrierCollider
@onready var door_visual: ColorRect = %DoorVisual
@onready var status_light: ColorRect = %StatusLight

var _pulse_time: float = 0.0
var _threshold_light: PointLight2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Слушает игрока (слой 2)
	body_entered.connect(_on_body_entered)
	
	if door_visual != null:
		door_visual.visible = false
	if status_light != null:
		status_light.visible = false
		
	_setup_door_dimensions()
	_update_thematic_visuals()
	_update_door_state()

func _process(delta: float) -> void:
	_pulse_time += delta
	if _threshold_light != null:
		var base_e: float = 0.85 if is_open else 0.35
		_threshold_light.energy = base_e + sin(_pulse_time * 2.8) * 0.08
	queue_redraw()

func _setup_door_dimensions() -> void:
	var trig_shape: CollisionShape2D = get_node_or_null("TriggerCollision") as CollisionShape2D
	var bar_shape: CollisionShape2D = get_node_or_null("BarrierCollider/BarrierShape") as CollisionShape2D
	
	var is_horizontal: bool = (direction.y != 0)
	var door_size: Vector2 = Vector2(96, 40) if is_horizontal else Vector2(40, 96)
	
	if trig_shape != null:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = door_size
		trig_shape.shape = rect
		
	if bar_shape != null:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = door_size
		bar_shape.shape = rect
	
	if door_visual != null:
		door_visual.size = door_size
		door_visual.position = -door_size / 2.0

func _update_thematic_visuals() -> void:
	if not is_node_ready():
		return
		
	var theme_col: Color = get_theme_color()
	if _threshold_light == null:
		_threshold_light = LightTextureGenerator.create_point_light(theme_col, 0.85, 2.4)
		_threshold_light.name = "DoorThresholdLight"
		add_child(_threshold_light)
	else:
		_threshold_light.color = theme_col
		
	queue_redraw()

func _update_door_state() -> void:
	if not is_node_ready():
		return
	
	if is_open:
		barrier_collider.set_collision_layer_value(1, false)
		barrier_collider.set_collision_mask_value(2, false)
	else:
		barrier_collider.set_collision_layer_value(1, true)
		barrier_collider.set_collision_mask_value(2, true)
		
	if _threshold_light != null:
		_threshold_light.energy = 0.85 if is_open else 0.35
		
	queue_redraw()

func get_theme_color() -> Color:
	match target_room_type:
		RoomData.RoomType.BOSS:
			return Color(1.0, 0.22, 0.28) # Зловещий рубиново-кровавый
		RoomData.RoomType.TREASURE:
			return Color(1.0, 0.88, 0.28) # Сияющее золото
		RoomData.RoomType.SHOP:
			return Color(0.35, 1.0, 0.6) # Изумрудное золото торговца
		RoomData.RoomType.ELITE:
			return Color(0.85, 0.35, 1.0) # Аметистовая бездна
		RoomData.RoomType.START:
			return Color(0.28, 0.78, 1.0) # Лазурный эфирный свет
		_:
			return Color(0.4, 0.85, 0.5) # Стандартный изумрудный путь

func _draw() -> void:
	var is_horizontal: bool = (direction.y != 0)
	var sz: Vector2 = Vector2(96, 40) if is_horizontal else Vector2(40, 96)
	var theme_col: Color = get_theme_color()
	
	# 1. Архитектурная каменная арка портала
	_draw_door_arch(sz, is_horizontal, theme_col)
	
	# 2. Внутреннее пространство проема (открыто / заперто)
	if is_open:
		_draw_open_passage(sz, is_horizontal, theme_col)
	else:
		_draw_locked_portcullis(sz, is_horizontal, theme_col)
	
	# 3. Геральдический рельефный герб целевой комнаты над/на арке
	_draw_thematic_crest(sz, is_horizontal, theme_col)

func _draw_door_arch(sz: Vector2, is_horizontal: bool, theme_col: Color) -> void:
	var arch_bg: Color = Color(0.11, 0.12, 0.16)
	var arch_rim: Color = Color(0.22, 0.24, 0.3)
	
	if Engine.has_singleton("GameState") or is_instance_valid(GameState):
		var bio: BiomeData = GameState.get_current_biome()
		if bio != null:
			match bio.id:
				"goblin_dungeon":
					arch_bg = Color(0.08, 0.14, 0.11)
					arch_rim = Color(0.16, 0.32, 0.24)
				"troll_gorge":
					arch_bg = Color(0.22, 0.14, 0.08)
					arch_rim = Color(0.38, 0.26, 0.16)
				"skeleton_castle":
					arch_bg = Color(0.10, 0.12, 0.18)
					arch_rim = Color(0.28, 0.34, 0.46)
				"frost_world", "frost_caves":
					arch_bg = Color(0.05, 0.22, 0.35)
					arch_rim = Color(0.22, 0.65, 0.88)
				"fire_world", "fire_mines":
					arch_bg = Color(0.22, 0.08, 0.06)
					arch_rim = Color(0.65, 0.25, 0.12)
				"purgatory":
					arch_bg = Color(0.14, 0.05, 0.25)
					arch_rim = Color(0.55, 0.22, 0.85)

	if target_room_type == RoomData.RoomType.BOSS:
		arch_bg = arch_bg.blend(Color(0.2, 0.04, 0.06, 0.5))
		arch_rim = Color(0.85, 0.2, 0.25)
	elif target_room_type == RoomData.RoomType.TREASURE:
		arch_bg = arch_bg.blend(Color(0.2, 0.16, 0.04, 0.5))
		arch_rim = Color(0.95, 0.78, 0.2)
	elif target_room_type == RoomData.RoomType.SHOP:
		arch_bg = arch_bg.blend(Color(0.18, 0.12, 0.04, 0.5))
		arch_rim = Color(0.4, 0.95, 0.55)
	elif target_room_type == RoomData.RoomType.ELITE:
		arch_bg = arch_bg.blend(Color(0.15, 0.04, 0.2, 0.5))
		arch_rim = Color(0.75, 0.25, 0.95)

	var full_r: Rect2 = Rect2(-sz / 2.0, sz)
	draw_rect(full_r, arch_bg)
	draw_rect(full_r, arch_rim, false, 2.0)
	
	# Резные боковые колонны / устои арки
	if is_horizontal:
		# Левая и правая пилястры
		draw_rect(Rect2(-sz.x/2.0, -sz.y/2.0, 16, sz.y), arch_bg.lightened(0.08))
		draw_rect(Rect2(-sz.x/2.0, -sz.y/2.0, 16, sz.y), arch_rim, false, 1.2)
		draw_rect(Rect2(sz.x/2.0 - 16, -sz.y/2.0, 16, sz.y), arch_bg.lightened(0.08))
		draw_rect(Rect2(sz.x/2.0 - 16, -sz.y/2.0, 16, sz.y), arch_rim, false, 1.2)
		
		# Декоративные скобы на пилястрах
		draw_line(Vector2(-sz.x/2.0 + 3, 0), Vector2(-sz.x/2.0 + 13, 0), theme_col * 0.7, 2.0)
		draw_line(Vector2(sz.x/2.0 - 13, 0), Vector2(sz.x/2.0 - 3, 0), theme_col * 0.7, 2.0)
		
		# Если босс — выступающие шипы на углах
		if target_room_type == RoomData.RoomType.BOSS:
			draw_line(Vector2(-sz.x/2.0, -sz.y/2.0), Vector2(-sz.x/2.0 - 6, -sz.y/2.0 - 5), theme_col, 2.5)
			draw_line(Vector2(sz.x/2.0, -sz.y/2.0), Vector2(sz.x/2.0 + 6, -sz.y/2.0 - 5), theme_col, 2.5)
	else:
		# Верхняя и нижняя пилястры
		draw_rect(Rect2(-sz.x/2.0, -sz.y/2.0, sz.x, 16), arch_bg.lightened(0.08))
		draw_rect(Rect2(-sz.x/2.0, -sz.y/2.0, sz.x, 16), arch_rim, false, 1.2)
		draw_rect(Rect2(-sz.x/2.0, sz.y/2.0 - 16, sz.x, 16), arch_bg.lightened(0.08))
		draw_rect(Rect2(-sz.x/2.0, sz.y/2.0 - 16, sz.x, 16), arch_rim, false, 1.2)
		
		draw_line(Vector2(0, -sz.y/2.0 + 3), Vector2(0, -sz.y/2.0 + 13), theme_col * 0.7, 2.0)
		draw_line(Vector2(0, sz.y/2.0 - 13), Vector2(0, sz.y/2.0 - 3), theme_col * 0.7, 2.0)
		
		if target_room_type == RoomData.RoomType.BOSS:
			draw_line(Vector2(-sz.x/2.0, -sz.y/2.0), Vector2(-sz.x/2.0 - 5, -sz.y/2.0 - 6), theme_col, 2.5)
			draw_line(Vector2(-sz.x/2.0, sz.y/2.0), Vector2(-sz.x/2.0 - 5, sz.y/2.0 + 6), theme_col, 2.5)

func _draw_open_passage(sz: Vector2, is_horizontal: bool, theme_col: Color) -> void:
	var inner_r: Rect2
	if is_horizontal:
		inner_r = Rect2(-sz.x/2.0 + 16, -sz.y/2.0 + 4, sz.x - 32, sz.y - 8)
	else:
		inner_r = Rect2(-sz.x/2.0 + 4, -sz.y/2.0 + 16, sz.x - 8, sz.y - 32)
	
	# Темная бездна проема с подсветкой порога
	draw_rect(inner_r, Color(0.03, 0.04, 0.06, 0.95))
	
	var pulse: float = 0.55 + sin(_pulse_time * 3.5) * 0.2
	var fill_tint: Color = Color(theme_col.r, theme_col.g, theme_col.b, pulse * 0.45)
	draw_rect(inner_r, fill_tint)
	
	# Светящийся порог в цвете целевой комнаты
	var rim_tint: Color = Color(theme_col.r, theme_col.g, theme_col.b, 0.85)
	if is_horizontal:
		draw_line(Vector2(inner_r.position.x, 0), Vector2(inner_r.end.x, 0), rim_tint, 2.5)
		# Светящиеся ритуальные маркеры на пороге
		draw_circle(Vector2(0, 0), 3.5, Color.WHITE)
		draw_circle(Vector2(0, 0), 5.5, rim_tint)
	else:
		draw_line(Vector2(0, inner_r.position.y), Vector2(0, inner_r.end.y), rim_tint, 2.5)
		draw_circle(Vector2(0, 0), 3.5, Color.WHITE)
		draw_circle(Vector2(0, 0), 5.5, rim_tint)

func _draw_locked_portcullis(sz: Vector2, is_horizontal: bool, theme_col: Color) -> void:
	var inner_r: Rect2
	if is_horizontal:
		inner_r = Rect2(-sz.x/2.0 + 16, -sz.y/2.0 + 2, sz.x - 32, sz.y - 4)
	else:
		inner_r = Rect2(-sz.x/2.0 + 2, -sz.y/2.0 + 16, sz.x - 4, sz.y - 32)
		
	draw_rect(inner_r, Color(0.05, 0.06, 0.09, 0.95))
	
	# Багровая пульсация блокировки
	var lock_pulse: float = 0.7 + sin(_pulse_time * 4.5) * 0.25
	draw_rect(inner_r, Color(0.9, 0.15, 0.18, lock_pulse * 0.4), false, 2.0)
	
	# Кованая железная решетка ворот (Portcullis)
	var iron_bar_col: Color = Color(0.38, 0.42, 0.5, 0.95)
	var spike_col: Color = Color(0.55, 0.6, 0.7, 1.0)
	
	if is_horizontal:
		var step_x: float = 12.0
		var cur_x: float = inner_r.position.x + 8.0
		while cur_x < inner_r.end.x - 4.0:
			draw_line(Vector2(cur_x, inner_r.position.y), Vector2(cur_x, inner_r.end.y), iron_bar_col, 2.5)
			# Кованые наконечники прутьев
			draw_line(Vector2(cur_x, inner_r.position.y), Vector2(cur_x, inner_r.position.y + 4), spike_col, 3.5)
			cur_x += step_x
		draw_line(Vector2(inner_r.position.x, 0), Vector2(inner_r.end.x, 0), iron_bar_col, 3.5)
	else:
		var step_y: float = 12.0
		var cur_y: float = inner_r.position.y + 8.0
		while cur_y < inner_r.end.y - 4.0:
			draw_line(Vector2(inner_r.position.x, cur_y), Vector2(inner_r.end.x, cur_y), iron_bar_col, 2.5)
			draw_line(Vector2(inner_r.position.x, cur_y), Vector2(inner_r.position.x + 4, cur_y), spike_col, 3.5)
			cur_y += step_y
		draw_line(Vector2(0, inner_r.position.y), Vector2(0, inner_r.end.y), iron_bar_col, 3.5)
		
	# Центральная руническая печать запирания
	draw_circle(Vector2.ZERO, 10.0, Color(0.9, 0.1, 0.15, 0.95))
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.8, 0.8, 1.0))
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)

func _draw_thematic_crest(sz: Vector2, is_horizontal: bool, theme_col: Color) -> void:
	# Вычисляем позицию замкового камня герба
	var crest_pos: Vector2 = Vector2.ZERO
	if is_horizontal:
		# Сверху в центре арки
		crest_pos = Vector2(0, -sz.y/2.0 + 6) if direction.y < 0 else Vector2(0, sz.y/2.0 - 6)
	else:
		crest_pos = Vector2(-sz.x/2.0 + 6, 0) if direction.x < 0 else Vector2(sz.x/2.0 - 6, 0)
	
	match target_room_type:
		RoomData.RoomType.BOSS:
			_draw_boss_crest(crest_pos, theme_col)
		RoomData.RoomType.TREASURE:
			_draw_treasure_crest(crest_pos, theme_col)
		RoomData.RoomType.SHOP:
			_draw_shop_crest(crest_pos, theme_col)
		RoomData.RoomType.ELITE:
			_draw_elite_crest(crest_pos, theme_col)
		_:
			_draw_standard_keystone(crest_pos, theme_col)

func _draw_boss_crest(pos: Vector2, col: Color) -> void:
	# Демонический череп с рогами и горящими рубиновыми глазами
	draw_circle(pos, 8.0, Color(0.18, 0.05, 0.06, 0.95))
	draw_circle(pos, 8.0, col, false, 1.5)
	
	# Череп
	draw_circle(pos + Vector2(0, -1), 4.5, Color(0.92, 0.85, 0.85))
	draw_rect(Rect2(pos.x - 2.5, pos.y + 1, 5, 3), Color(0.85, 0.78, 0.78))
	# Глазницы
	draw_circle(pos + Vector2(-1.8, -1), 1.3, Color(0.9, 0.1, 0.1))
	draw_circle(pos + Vector2(1.8, -1), 1.3, Color(0.9, 0.1, 0.1))
	# Изогнутые рога
	draw_line(pos + Vector2(-3, -2), pos + Vector2(-7, -7), col, 2.0)
	draw_line(pos + Vector2(3, -2), pos + Vector2(7, -7), col, 2.0)

func _draw_treasure_crest(pos: Vector2, col: Color) -> void:
	# Золотая корона с сияющим лазурным драгоценным камнем
	draw_circle(pos, 8.0, Color(0.2, 0.16, 0.06, 0.95))
	draw_circle(pos, 8.0, col, false, 1.5)
	
	# Корона
	var p1 = pos + Vector2(-5, 3)
	var p2 = pos + Vector2(5, 3)
	var p3 = pos + Vector2(6, -2)
	var p4 = pos + Vector2(2, 0)
	var p5 = pos + Vector2(0, -4)
	var p6 = pos + Vector2(-2, 0)
	var p7 = pos + Vector2(-6, -2)
	var crown_pts = PackedVector2Array([p1, p2, p3, p4, p5, p6, p7])
	draw_colored_polygon(crown_pts, col)
	# Сапфир в центре короны
	draw_circle(pos + Vector2(0, 1), 1.8, Color(0.25, 0.9, 1.0))
	draw_circle(pos + Vector2(0, 1), 0.8, Color.WHITE)

func _draw_shop_crest(pos: Vector2, col: Color) -> void:
	# Золотая монета торговца со знаком богатства
	draw_circle(pos, 8.0, Color(0.18, 0.14, 0.05, 0.95))
	draw_circle(pos, 8.0, col, false, 1.5)
	draw_circle(pos, 6.0, col)
	draw_circle(pos, 4.5, Color(0.85, 0.65, 0.15))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-2.5, 3.5), "$", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.15, 0.1, 0.02))

func _draw_elite_crest(pos: Vector2, col: Color) -> void:
	# Скрещенные клинки в аметистовом медальоне
	draw_circle(pos, 8.0, Color(0.15, 0.08, 0.2, 0.95))
	draw_circle(pos, 8.0, col, false, 1.5)
	draw_line(pos + Vector2(-4, -4), pos + Vector2(4, 4), Color(0.95, 0.95, 1.0), 1.8)
	draw_line(pos + Vector2(4, -4), pos + Vector2(-4, 4), Color(0.95, 0.95, 1.0), 1.8)
	draw_circle(pos, 2.0, col)

func _draw_standard_keystone(pos: Vector2, col: Color) -> void:
	# Готический замковый камень с железным кольцом
	draw_circle(pos, 6.0, Color(0.15, 0.18, 0.22, 0.95))
	draw_circle(pos, 6.0, Color(0.35, 0.4, 0.48), false, 1.2)
	draw_circle(pos, 3.0, col * 0.7, false, 1.5)

func _on_body_entered(body: Node2D) -> void:
	if is_open and body is Player:
		door_entered.emit(direction)
