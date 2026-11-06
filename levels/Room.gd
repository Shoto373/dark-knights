class_name DungeonRoom
extends Node2D

## Комната подземелья в стиле The Binding of Isaac / Enter the Gungeon

signal room_cleared
signal door_entered(direction: Vector2i)

const ITEM_PEDESTAL_SCENE = preload("res://entities/loot/ItemPedestal.tscn")
const TREASURE_CHEST_SCENE = preload("res://entities/loot/TreasureChest.tscn")
const PICKUP_SCENE = preload("res://entities/pickups/PickupBase.tscn")
const CHASM_HAZARD_SCENE = preload("res://levels/hazards/ChasmHazard.tscn")
const BRIDGE_AREA_SCENE = preload("res://levels/hazards/BridgeArea.tscn")
const FIRE_GRATE_SCENE = preload("res://levels/hazards/FireGrateTrap.tscn")
const CHANDELIER_SCENE = preload("res://levels/hazards/FallingChandelierTrap.tscn")
const SECRET_LEVER_SCENE = preload("res://levels/hazards/SecretLever.tscn")
const ICE_PATCH_SCENE = preload("res://levels/hazards/IcePatch.tscn")
const LAVA_HAZARD_SCENE = preload("res://levels/hazards/LavaHazard.tscn")
const LAVA_GEYSER_SCENE = preload("res://levels/hazards/LavaGeyserTrap.tscn")
const VOID_RIFT_SCENE = preload("res://levels/hazards/VoidRiftTrap.tscn")

@onready var door_up: DungeonDoor = %DoorUp
@onready var door_down: DungeonDoor = %DoorDown
@onready var door_left: DungeonDoor = %DoorLeft
@onready var door_right: DungeonDoor = %DoorRight

@onready var wall_blocker_up: StaticBody2D = %WallBlockerUp
@onready var wall_blocker_down: StaticBody2D = %WallBlockerDown
@onready var wall_blocker_left: StaticBody2D = %WallBlockerLeft
@onready var wall_blocker_right: StaticBody2D = %WallBlockerRight

@onready var room_type_label: Label = %RoomTypeLabel
@onready var enemies_container: Node2D = %EnemiesContainer
@onready var objects_container: Node2D = %ObjectsContainer

var room_data: RoomData
var current_biome: BiomeData = null
var active_enemies: Array[Node2D] = []
var wave_spawner: WaveSpawner = WaveSpawner.new()

var _all_floor_rooms: Dictionary = {}

func _ready() -> void:
	door_up.door_entered.connect(_on_door_entered)
	door_down.door_entered.connect(_on_door_entered)
	door_left.door_entered.connect(_on_door_entered)
	door_right.door_entered.connect(_on_door_entered)

func setup(data: RoomData, biome: BiomeData = null, all_rooms: Dictionary = {}) -> void:
	room_data = data
	current_biome = biome if biome != null else GameState.get_current_biome()
	_all_floor_rooms = all_rooms
	room_type_label.visible = false
	_apply_biome_theme()
	_configure_doors()
	
	if room_data.room_type == RoomData.RoomType.TREASURE:
		_setup_treasure_room()
	elif room_data.room_type == RoomData.RoomType.SHOP:
		_setup_shop_room()
	elif room_data.room_type == RoomData.RoomType.COMBAT:
		_setup_biome_hazards()

func _apply_biome_theme() -> void:
	if current_biome == null:
		return
	
	# 1. Цветовая палитра подложки пола под биом
	var floor_node: ColorRect = get_node_or_null("Floor") as ColorRect
	if floor_node != null:
		floor_node.color = current_biome.floor_theme_color
	var arena_floor: ColorRect = get_node_or_null("ArenaFloor") as ColorRect
	if arena_floor != null:
		arena_floor.color = current_biome.floor_theme_color.lightened(0.06)
	
	# 2. Уникальный детальный тайл пола для КАЖДОГО биома
	var floor_tiles: TextureRect = get_node_or_null("%FloorTiles") as TextureRect
	if floor_tiles != null:
		var b_tile: Texture2D = SpriteGenerator.get_biome_tile_texture(current_biome.id)
		if b_tile != null:
			floor_tiles.texture = b_tile
		floor_tiles.modulate = Color(1.0, 1.0, 1.0, 0.92)
	
	# 3. Уникальная каменная кладка стен биома
	var walls_node: Node2D = get_node_or_null("VisualWalls") as Node2D
	if walls_node != null:
		var b_wall: Texture2D = SpriteGenerator.get_biome_wall_texture(current_biome.id)
		for wall in walls_node.get_children():
			if wall is ColorRect:
				wall.color = current_biome.wall_theme_color
				var tex_rect: TextureRect = wall.get_node_or_null("BrickOverlay") as TextureRect
				if tex_rect == null:
					tex_rect = TextureRect.new()
					tex_rect.name = "BrickOverlay"
					tex_rect.stretch_mode = TextureRect.STRETCH_TILE
					tex_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
					tex_rect.anchor_right = 1.0
					tex_rect.anchor_bottom = 1.0
					tex_rect.offset_left = 0
					tex_rect.offset_top = 0
					tex_rect.offset_right = 0
					tex_rect.offset_bottom = 0
					wall.add_child(tex_rect)
				if b_wall != null:
					tex_rect.texture = b_wall
				tex_rect.modulate = Color(1.0, 1.0, 1.0, 0.95)
	
	# 4. Уникальные угловые колонны биома
	var pillars_node: Node2D = get_node_or_null("%Pillars") as Node2D
	var b_pillar: Texture2D = SpriteGenerator.get_biome_pillar_texture(current_biome.id)
	if pillars_node != null and b_pillar != null:
		for p in pillars_node.get_children():
			var spr: Sprite2D = p.get_node_or_null("Sprite2D") as Sprite2D
			if spr != null:
				spr.texture = b_pillar

	# 5. Уникальный напольный герб биома (для всех комнат босса, сокровищниц и стартовых залов)
	_setup_biome_floor_crest()

	# 6. Уникальные архитектурные акценты биома (ковры, ручьи лавы, кристаллические осколки)
	_setup_biome_environmental_decor()
	
	# 7. Биомный оттенок настенных факелов
	var torches_node: Node2D = get_node_or_null("%Torches") as Node2D
	if torches_node != null:
		var flame_tint: Color = Color(1.0, 0.72, 0.3, 0.35)
		match current_biome.id:
			"frost_world", "frost_caves":
				flame_tint = Color(0.3, 0.85, 1.0, 0.45)
			"fire_world", "fire_mines":
				flame_tint = Color(1.0, 0.38, 0.1, 0.45)
			"skeleton_castle":
				flame_tint = Color(0.4, 0.95, 0.6, 0.4)
			"purgatory":
				flame_tint = Color(0.85, 0.35, 1.0, 0.45)
			_:
				flame_tint = Color(1.0, 0.72, 0.3, 0.35)
		for t in torches_node.get_children():
			if "torch_color" in t:
				t.set("torch_color", flame_tint)
				var glow = t.get_node_or_null("LightGlow")
				if glow is Sprite2D:
					glow.modulate = flame_tint
			if not t.has_node("TorchLight"):
				var t_light: PointLight2D = LightTextureGenerator.create_point_light(flame_tint.lightened(0.3), 0.75, 1.8)
				t_light.name = "TorchLight"
				t.add_child(t_light)
				
				# Анимированное мерцание живого факельного пламени
				var tw: Tween = t_light.create_tween().set_loops()
				var base_e: float = 0.75
				var min_e: float = base_e * randf_range(0.82, 0.90)
				var max_e: float = base_e * randf_range(1.10, 1.25)
				var dur1: float = randf_range(0.12, 0.22)
				var dur2: float = randf_range(0.12, 0.22)
				tw.tween_property(t_light, "energy", max_e, dur1).set_trans(Tween.TRANS_SINE)
				tw.tween_property(t_light, "energy", min_e, dur2).set_trans(Tween.TRANS_SINE)

	# 8. Атмосферные частицы биома
	var atmosphere: BiomeAtmosphere = get_node_or_null("BiomeAtmosphere") as BiomeAtmosphere
	if atmosphere == null:
		atmosphere = BiomeAtmosphere.new()
		atmosphere.name = "BiomeAtmosphere"
		add_child(atmosphere)
	atmosphere.setup_biome(current_biome.id)

func _setup_biome_floor_crest() -> void:
	if current_biome == null or has_node("BiomeFloorCrest"):
		return
	var b_crest: Texture2D = SpriteGenerator.get_biome_crest_texture(current_biome.id)
	if b_crest == null:
		return
	var crest_spr: Sprite2D = Sprite2D.new()
	crest_spr.name = "BiomeFloorCrest"
	crest_spr.texture = b_crest
	crest_spr.position = Vector2(640, 360)
	var is_boss: bool = (room_data != null and room_data.room_type == RoomData.RoomType.BOSS)
	var scale_factor: float = 2.4 if is_boss else 1.8
	crest_spr.scale = Vector2(scale_factor, scale_factor)
	crest_spr.modulate = Color(1.0, 1.0, 1.0, 0.85 if is_boss else 0.5)
	crest_spr.z_index = -1
	add_child(crest_spr)

func _setup_biome_environmental_decor() -> void:
	if current_biome == null:
		return
	var decor_container: Node2D = get_node_or_null("BiomeDecorContainer") as Node2D
	if decor_container == null:
		decor_container = Node2D.new()
		decor_container.name = "BiomeDecorContainer"
		decor_container.z_index = -1
		add_child(decor_container)
	else:
		return
	
	match current_biome.id:
		"skeleton_castle":
			# В замке скелетов расстилаем королевскую багровую ковровую дорожку с золотой каймой
			var carpet_tex: Texture2D = SpriteGenerator.get_castle_carpet_texture()
			if carpet_tex != null:
				var carpet: TextureRect = TextureRect.new()
				carpet.texture = carpet_tex
				carpet.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				carpet.stretch_mode = TextureRect.STRETCH_TILE
				carpet.position = Vector2(590, 60)
				carpet.size = Vector2(100, 600)
				carpet.modulate = Color(1.0, 1.0, 1.0, 0.88)
				decor_container.add_child(carpet)
		"fire_world", "fire_mines":
			# В мире огня добавляем светящиеся прожилки раскаленной лавы
			for pos in [Vector2(280, 220), Vector2(1000, 220), Vector2(280, 500), Vector2(1000, 500)]:
				var lava_glow: Sprite2D = Sprite2D.new()
				lava_glow.texture = EffectsHelper.get_spark_texture()
				lava_glow.position = pos
				lava_glow.scale = Vector2(4.5, 3.0)
				lava_glow.modulate = Color(1.0, 0.4, 0.1, 0.35)
				decor_container.add_child(lava_glow)
		"frost_world", "frost_caves":
			# В мире холода добавляем морозные пятна синего льда в углах
			for pos in [Vector2(240, 180), Vector2(1040, 180), Vector2(240, 540), Vector2(1040, 540)]:
				var ice_sheen: Sprite2D = Sprite2D.new()
				ice_sheen.texture = EffectsHelper.get_spark_texture()
				ice_sheen.position = pos
				ice_sheen.scale = Vector2(5.0, 3.5)
				ice_sheen.modulate = Color(0.2, 0.7, 1.0, 0.32)
				decor_container.add_child(ice_sheen)
		"goblin_dungeon":
			# В темнице гоблинов добавляем пятна сырости и ядовитой плесени
			for pos in [Vector2(320, 240), Vector2(960, 480)]:
				var slime_spot: Sprite2D = Sprite2D.new()
				slime_spot.texture = EffectsHelper.get_spark_texture()
				slime_spot.position = pos
				slime_spot.scale = Vector2(4.0, 2.5)
				slime_spot.modulate = Color(0.1, 0.8, 0.3, 0.28)
				decor_container.add_child(slime_spot)
		"purgatory":
			# В Чистилище добавляем сияющие эфирные пустотные пятна
			for pos in [Vector2(340, 200), Vector2(940, 200), Vector2(340, 520), Vector2(940, 520)]:
				var void_glow: Sprite2D = Sprite2D.new()
				void_glow.texture = EffectsHelper.get_spark_texture()
				void_glow.position = pos
				void_glow.scale = Vector2(4.2, 3.2)
				void_glow.modulate = Color(0.8, 0.3, 1.0, 0.35)
				decor_container.add_child(void_glow)

func _setup_biome_hazards() -> void:
	if current_biome == null:
		return
	if current_biome.id == "troll_gorge":
		if abs(room_data.grid_pos.x + room_data.grid_pos.y) % 2 == 1:
			_create_gorge_chasm_and_bridge()
	elif current_biome.id == "skeleton_castle":
		_create_castle_traps()
	elif current_biome.id == "frost_world" or current_biome.id == "frost_caves":
		_create_frost_ice_patches()
	elif current_biome.id == "fire_world" or current_biome.id == "fire_mines":
		_create_fire_hazards()
	elif current_biome.id == "purgatory":
		_create_purgatory_hazards()

func _create_purgatory_hazards() -> void:
	var rift1: VoidRiftTrap = VOID_RIFT_SCENE.instantiate() as VoidRiftTrap
	objects_container.add_child(rift1)
	rift1.position = Vector2(420, 360)
	
	var rift2: VoidRiftTrap = VOID_RIFT_SCENE.instantiate() as VoidRiftTrap
	objects_container.add_child(rift2)
	rift2.position = Vector2(860, 360)

func _create_fire_hazards() -> void:
	# Лужа лавы
	var lava1: LavaHazard = LAVA_HAZARD_SCENE.instantiate() as LavaHazard
	objects_container.add_child(lava1)
	lava1.position = Vector2(460, 360)
	
	# Лавовый гейзер
	var geyser1: LavaGeyserTrap = LAVA_GEYSER_SCENE.instantiate() as LavaGeyserTrap
	objects_container.add_child(geyser1)
	geyser1.position = Vector2(820, 360)
	
	if abs(room_data.grid_pos.x + room_data.grid_pos.y) % 2 == 1:
		var lava2: LavaHazard = LAVA_HAZARD_SCENE.instantiate() as LavaHazard
		objects_container.add_child(lava2)
		lava2.position = Vector2(640, 240)

func _create_frost_ice_patches() -> void:
	var patch1: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
	objects_container.add_child(patch1)
	patch1.position = Vector2(480, 360)
	
	var patch2: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
	objects_container.add_child(patch2)
	patch2.position = Vector2(800, 360)
	
	if abs(room_data.grid_pos.x + room_data.grid_pos.y) % 2 == 1:
		var patch3: IcePatch = ICE_PATCH_SCENE.instantiate() as IcePatch
		objects_container.add_child(patch3)
		patch3.position = Vector2(640, 260)

func _create_castle_traps() -> void:
	var grate1: FireGrateTrap = FIRE_GRATE_SCENE.instantiate() as FireGrateTrap
	objects_container.add_child(grate1)
	grate1.position = Vector2(480, 360)
	
	var grate2: FireGrateTrap = FIRE_GRATE_SCENE.instantiate() as FireGrateTrap
	objects_container.add_child(grate2)
	grate2.position = Vector2(800, 360)
	
	var chandelier: FallingChandelierTrap = CHANDELIER_SCENE.instantiate() as FallingChandelierTrap
	objects_container.add_child(chandelier)
	chandelier.position = Vector2(640, 300)
	
	if abs(room_data.grid_pos.x + room_data.grid_pos.y) % 2 == 0:
		var lever: SecretLever = SECRET_LEVER_SCENE.instantiate() as SecretLever
		objects_container.add_child(lever)
		lever.position = Vector2(200, 180)

func _create_gorge_chasm_and_bridge() -> void:
	# Размещаем пропасти строго в угловых квадрантах комнаты,
	# чтобы коридоры у ВСЕХ 4 дверей (Сверху, Снизу, Слева, Справа) были полностью свободны и безопасны.
	var chasm1: ChasmHazard = CHASM_HAZARD_SCENE.instantiate() as ChasmHazard
	objects_container.add_child(chasm1)
	chasm1.position = Vector2(340, 220)
	chasm1.pit_size = Vector2(200, 140)
	chasm1.safe_respawn_position = global_position + Vector2(640, 360)
	if current_biome != null:
		chasm1.visual_pit.color = current_biome.chasm_color
	
	var chasm2: ChasmHazard = CHASM_HAZARD_SCENE.instantiate() as ChasmHazard
	objects_container.add_child(chasm2)
	chasm2.position = Vector2(940, 500)
	chasm2.pit_size = Vector2(200, 140)
	chasm2.safe_respawn_position = global_position + Vector2(640, 360)
	if current_biome != null:
		chasm2.visual_pit.color = current_biome.chasm_color
		
	var bridge: BridgeArea = BRIDGE_AREA_SCENE.instantiate() as BridgeArea
	objects_container.add_child(bridge)
	bridge.position = Vector2(340, 220)
	bridge.bridge_size = Vector2(80, 140)
	if current_biome != null:
		bridge.visual_rect.color = current_biome.bridge_color

func _configure_doors() -> void:
	var has_up: bool = room_data.doors.get(Vector2i.UP, false)
	var has_down: bool = room_data.doors.get(Vector2i.DOWN, false)
	var has_left: bool = room_data.doors.get(Vector2i.LEFT, false)
	var has_right: bool = room_data.doors.get(Vector2i.RIGHT, false)
	
	_setup_door(door_up, wall_blocker_up, Vector2i.UP)
	_setup_door(door_down, wall_blocker_down, Vector2i.DOWN)
	_setup_door(door_left, wall_blocker_left, Vector2i.LEFT)
	_setup_door(door_right, wall_blocker_right, Vector2i.RIGHT)
	
	_update_wall_geometry(has_up, has_down, has_left, has_right)

func _setup_door(door: DungeonDoor, blocker: StaticBody2D, dir: Vector2i) -> void:
	var has_door: bool = room_data.doors.get(dir, false)
	door.visible = has_door
	door.monitoring = has_door
	blocker.set_collision_layer_value(1, not has_door)
	blocker.visible = false # Блокер используется только как коллизия. Стена рисуется единым монолитом!
	
	if has_door and not _all_floor_rooms.is_empty():
		var neighbor_pos: Vector2i = room_data.grid_pos + dir
		if _all_floor_rooms.has(neighbor_pos):
			var neighbor: RoomData = _all_floor_rooms[neighbor_pos] as RoomData
			if neighbor != null:
				door.target_room_type = neighbor.room_type

func _update_wall_geometry(has_up: bool, has_down: bool, has_left: bool, has_right: bool) -> void:
	var w1: ColorRect = get_node_or_null("VisualWalls/W1") as ColorRect
	var w2: ColorRect = get_node_or_null("VisualWalls/W2") as ColorRect
	var w3: ColorRect = get_node_or_null("VisualWalls/W3") as ColorRect
	var w4: ColorRect = get_node_or_null("VisualWalls/W4") as ColorRect
	var w5: ColorRect = get_node_or_null("VisualWalls/W5") as ColorRect
	var w6: ColorRect = get_node_or_null("VisualWalls/W6") as ColorRect
	var w7: ColorRect = get_node_or_null("VisualWalls/W7") as ColorRect
	var w8: ColorRect = get_node_or_null("VisualWalls/W8") as ColorRect
	
	var shadow_l: ColorRect = get_node_or_null("WallShadowLeft") as ColorRect
	var shadow_r: ColorRect = get_node_or_null("WallShadowRight") as ColorRect
	
	var torch_l: Node2D = get_node_or_null("%Torches/TorchLeft") as Node2D
	var torch_r: Node2D = get_node_or_null("%Torches/TorchRight") as Node2D
	
	# Верхняя стена: если двери нет — W1 бесшовно продолжается на всю ширину (1260px)
	if w1 != null and w2 != null:
		if has_up:
			w1.offset_right = 592.0
			w2.visible = true
			if shadow_l != null: shadow_l.offset_right = 592.0
			if shadow_r != null: shadow_r.visible = true
			if torch_l != null: torch_l.position = Vector2(540, 52)
			if torch_r != null: torch_r.position = Vector2(740, 52)
		else:
			w1.offset_right = 1260.0
			w2.visible = false
			if shadow_l != null: shadow_l.offset_right = 1220.0
			if shadow_r != null: shadow_r.visible = false
			if torch_l != null: torch_l.position = Vector2(400, 52)
			if torch_r != null: torch_r.position = Vector2(880, 52)
	
	# Нижняя стена: если двери нет — W3 продолжается на всю ширину
	if w3 != null and w4 != null:
		if has_down:
			w3.offset_right = 592.0
			w4.visible = true
		else:
			w3.offset_right = 1260.0
			w4.visible = false
	
	# Левая стена: если двери нет — W5 продолжается сверху донизу (660px)
	if w5 != null and w6 != null:
		if has_left:
			w5.offset_bottom = 312.0
			w6.visible = true
		else:
			w5.offset_bottom = 660.0
			w6.visible = false
	
	# Правая стена: если двери нет — W7 продолжается сверху донизу (660px)
	if w7 != null and w8 != null:
		if has_right:
			w7.offset_bottom = 312.0
			w8.visible = true
		else:
			w7.offset_bottom = 660.0
			w8.visible = false

func on_player_entered() -> void:
	room_data.is_visited = true
	room_data.is_discovered = true
	
	EventBus.room_entered.emit({
		"grid_pos": room_data.grid_pos,
		"type": room_data.get_type_name()
	})
	
	var is_hostile: bool = (room_data.room_type == RoomData.RoomType.COMBAT or \
							room_data.room_type == RoomData.RoomType.ELITE or \
							room_data.room_type == RoomData.RoomType.BOSS)
	
	if is_hostile and not room_data.is_cleared:
		_start_combat()
	else:
		_unlock_all_doors()

func _start_combat() -> void:
	_lock_all_doors()
	active_enemies.clear()
	if not enemies_container.child_entered_tree.is_connected(_on_enemy_child_entered):
		enemies_container.child_entered_tree.connect(_on_enemy_child_entered)
	var spawned: Array[Node2D] = wave_spawner.spawn_room_enemies(self, room_data, current_biome)
	for enemy in spawned:
		_register_enemy(enemy)

func _on_enemy_child_entered(node: Node) -> void:
	if node is Node2D:
		call_deferred("_check_and_register_child", node)

func _check_and_register_child(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is IcePillar or node is Phylactery:
		return
	if node is CharacterBody2D or node.is_in_group("enemies") or node.is_in_group("bosses"):
		_register_enemy(node as Node2D)

func _register_enemy(enemy: Node2D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy in active_enemies:
		return
	active_enemies.append(enemy)
	
	if enemy is EnemyBase:
		var eb: EnemyBase = enemy as EnemyBase
		if not eb.permanently_died.is_connected(_on_enemy_died):
			eb.permanently_died.connect(func(_e): _on_enemy_died(enemy))
	elif enemy.has_signal("boss_defeated"):
		enemy.connect("boss_defeated", func(): _on_enemy_died(enemy))
	else:
		var hc: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null:
			hc.died.connect(func(): _on_enemy_died(enemy))
	
	if not enemy.tree_exited.is_connected(_on_enemy_died):
		enemy.tree_exited.connect(func(): _on_enemy_died(enemy))

func _on_enemy_died(enemy: Node2D) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	if active_enemies.is_empty():
		_finish_combat()

func _finish_combat() -> void:
	if enemies_container.child_entered_tree.is_connected(_on_enemy_child_entered):
		enemies_container.child_entered_tree.disconnect(_on_enemy_child_entered)
	room_data.is_cleared = true
	_unlock_all_doors()
	if room_data.room_type != RoomData.RoomType.BOSS:
		_spawn_room_clear_reward()
	EventBus.room_cleared.emit()
	room_cleared.emit()
	SaveManager.save_run()

func _spawn_room_clear_reward() -> void:
	var rng: RandomNumberGenerator = GameState.rng
	var roll: float = rng.randf()
	
	if roll < 0.25:
		var coin: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		coin.pickup_type = PickupBase.PickupType.GOLD
		coin.amount = rng.randi_range(3, 8)
		objects_container.add_child(coin)
		coin.position = Vector2(640, 360)
	elif roll < 0.45:
		var heart: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		heart.pickup_type = PickupBase.PickupType.HEART
		heart.amount = 25
		objects_container.add_child(heart)
		heart.position = Vector2(640, 360)
	elif roll < 0.60:
		var key: PickupBase = PICKUP_SCENE.instantiate() as PickupBase
		key.pickup_type = PickupBase.PickupType.KEY
		key.amount = 1
		objects_container.add_child(key)
		key.position = Vector2(640, 360)
	elif roll < 0.75:
		var chest: TreasureChest = TREASURE_CHEST_SCENE.instantiate() as TreasureChest
		chest.requires_key = (rng.randf() > 0.5)
		objects_container.add_child(chest)
		chest.position = Vector2(640, 360)

func _lock_all_doors() -> void:
	door_up.is_open = false
	door_down.is_open = false
	door_left.is_open = false
	door_right.is_open = false

func _unlock_all_doors() -> void:
	door_up.is_open = true
	door_down.is_open = true
	door_left.is_open = true
	door_right.is_open = true

func _setup_treasure_room() -> void:
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	var item: ItemData = null
	if loot_table != null:
		item = loot_table.roll_item(GameState.rng)
	
	if item != null:
		var pedestal: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		objects_container.add_child(pedestal)
		pedestal.position = Vector2(640, 360)
		pedestal.setup(item, 0, false)
	else:
		var chest: TreasureChest = TREASURE_CHEST_SCENE.instantiate() as TreasureChest
		objects_container.add_child(chest)
		chest.position = Vector2(640, 360)

func _setup_shop_room() -> void:
	# Ковер / рунический круг под торговцем
	var shop_carpet: Sprite2D = Sprite2D.new()
	shop_carpet.texture = EffectsHelper.get_spark_texture()
	shop_carpet.scale = Vector2(5.5, 2.4)
	shop_carpet.modulate = Color(0.85, 0.65, 0.2, 0.35)
	shop_carpet.position = Vector2(640, 235)
	objects_container.add_child(shop_carpet)
	
	var merchant: Sprite2D = Sprite2D.new()
	merchant.texture = SpriteGenerator.get_enemy_texture("necromancer")
	merchant.modulate = Color(1.2, 1.0, 0.6)
	merchant.position = Vector2(640, 220)
	objects_container.add_child(merchant)
	
	# Стилизованная плашка торговца по центру
	var label: Label = Label.new()
	label.text = "СТРАНСТВУЮЩИЙ ТОРГОВЕЦ"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(240, 24)
	label.position = Vector2(640 - 120, 172)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.13, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 0.85, 0.3, 0.85)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.expand_margin_left = 8.0
	style.expand_margin_top = 2.0
	style.expand_margin_right = 8.0
	style.expand_margin_bottom = 2.0
	label.add_theme_stylebox_override("normal", style)
	objects_container.add_child(label)
	
	var loot_table: LootTable = load("res://data/items/default_loot_table.tres") as LootTable
	var rolled_items: Array[ItemData] = []
	if loot_table != null:
		rolled_items = loot_table.roll_multiple_unique(2, GameState.rng)
	
	if rolled_items.size() > 0:
		var it1: ItemData = rolled_items[0]
		var ped1: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		objects_container.add_child(ped1)
		ped1.position = Vector2(480, 360)
		ped1.setup(it1, it1.cost_gold, false)
	
	if rolled_items.size() > 1:
		var it2: ItemData = rolled_items[1]
		var ped2: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
		objects_container.add_child(ped2)
		ped2.position = Vector2(640, 360)
		ped2.setup(it2, it2.cost_gold, false)
	
	var key_ped: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate() as ItemPedestal
	objects_container.add_child(key_ped)
	key_ped.position = Vector2(800, 360)
	var key_item: ItemData = ItemData.new()
	key_item.id = "shop_key"
	key_item.name = "Ключ"
	key_item.rarity = "common"
	key_ped.setup(key_item, 10, false)

func _on_door_entered(direction: Vector2i) -> void:
	door_entered.emit(direction)
