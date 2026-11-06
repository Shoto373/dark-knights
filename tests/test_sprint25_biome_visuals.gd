extends GutTest

## Тесты Спринта 25: Полная визуальная дифференциация биомов (уникальные тайлы пола, стены, колонны, гербы и декор)

const BIOME_IDS: Array[String] = [
	"goblin_dungeon",
	"troll_gorge",
	"skeleton_castle",
	"frost_world",
	"fire_world",
	"purgatory"
]

func test_all_6_biomes_load_distinct_tile_textures() -> void:
	var loaded_tiles: Dictionary = {}
	for b_id in BIOME_IDS:
		var tex: Texture2D = SpriteGenerator.get_biome_tile_texture(b_id)
		assert_not_null(tex, "Текстура пола для биома '%s' успешно загружена" % b_id)
		# Проверяем уникальность текстур между биомами
		for other_id in loaded_tiles.keys():
			assert_ne(tex, loaded_tiles[other_id], "Тайлы пола биома '%s' визуально отличаются от '%s'" % [b_id, other_id])
		loaded_tiles[b_id] = tex

func test_all_6_biomes_load_distinct_wall_textures() -> void:
	var loaded_walls: Dictionary = {}
	for b_id in BIOME_IDS:
		var tex: Texture2D = SpriteGenerator.get_biome_wall_texture(b_id)
		assert_not_null(tex, "Текстура стен для биома '%s' успешно загружена" % b_id)
		for other_id in loaded_walls.keys():
			assert_ne(tex, loaded_walls[other_id], "Стены биома '%s' визуально отличаются от '%s'" % [b_id, other_id])
		loaded_walls[b_id] = tex

func test_all_6_biomes_load_distinct_pillar_textures() -> void:
	var loaded_pillars: Dictionary = {}
	for b_id in BIOME_IDS:
		var tex: Texture2D = SpriteGenerator.get_biome_pillar_texture(b_id)
		assert_not_null(tex, "Текстура колонн для биома '%s' успешно загружена" % b_id)
		for other_id in loaded_pillars.keys():
			assert_ne(tex, loaded_pillars[other_id], "Колонны биома '%s' визуально отличаются от '%s'" % [b_id, other_id])
		loaded_pillars[b_id] = tex

func test_all_6_biomes_load_distinct_crest_textures() -> void:
	var loaded_crests: Dictionary = {}
	for b_id in BIOME_IDS:
		var tex: Texture2D = SpriteGenerator.get_biome_crest_texture(b_id)
		assert_not_null(tex, "Герб пола для биома '%s' успешно загружен" % b_id)
		for other_id in loaded_crests.keys():
			assert_ne(tex, loaded_crests[other_id], "Герб биома '%s' визуально отличается от '%s'" % [b_id, other_id])
		loaded_crests[b_id] = tex

func test_room_setup_applies_unique_biome_textures_and_decor() -> void:
	var room_scene: PackedScene = load("res://levels/Room.tscn")
	assert_not_null(room_scene, "Сцена Room.tscn загружена")
	
	# 1. Проверяем Замок Скелетов
	var castle_room: DungeonRoom = room_scene.instantiate() as DungeonRoom
	add_child_autofree(castle_room)
	var castle_data: RoomData = RoomData.new()
	var castle_biome: BiomeData = load("res://data/biomes/skeleton_castle.tres") as BiomeData
	castle_room.setup(castle_data, castle_biome)
	
	var floor_tiles: TextureRect = castle_room.get_node("%FloorTiles") as TextureRect
	assert_eq(floor_tiles.texture, SpriteGenerator.get_biome_tile_texture("skeleton_castle"), "В Замке Скелетов установлена готическая мраморная плитка")
	
	var decor_castle: Node2D = castle_room.get_node_or_null("BiomeDecorContainer") as Node2D
	assert_not_null(decor_castle, "В Замке Скелетов создан контейнер биомного декора")
	assert_gt(decor_castle.get_child_count(), 0, "В Замке Скелетов расстелена королевская багровая ковровая дорожка")
	
	var crest_castle: Sprite2D = castle_room.get_node_or_null("BiomeFloorCrest") as Sprite2D
	assert_not_null(crest_castle, "В Замке Скелетов на полу нанесен геральдический герб")
	assert_eq(crest_castle.texture, SpriteGenerator.get_biome_crest_texture("skeleton_castle"), "Герб соответствует Замку Скелетов")
	
	# 2. Проверяем Мир Холода
	var frost_room: DungeonRoom = room_scene.instantiate() as DungeonRoom
	add_child_autofree(frost_room)
	var frost_data: RoomData = RoomData.new()
	var frost_biome: BiomeData = load("res://data/biomes/frost_world.tres") as BiomeData
	frost_room.setup(frost_data, frost_biome)
	
	var frost_floor: TextureRect = frost_room.get_node("%FloorTiles") as TextureRect
	assert_eq(frost_floor.texture, SpriteGenerator.get_biome_tile_texture("frost_world"), "В Мире Холода установлен текстурный ледник")
	assert_ne(frost_floor.texture, floor_tiles.texture, "Плитка Мира Холода кардинально отличается от Замка Скелетов")
	
	# 3. Проверяем Мир Огня
	var fire_room: DungeonRoom = room_scene.instantiate() as DungeonRoom
	add_child_autofree(fire_room)
	var fire_data: RoomData = RoomData.new()
	var fire_biome: BiomeData = load("res://data/biomes/fire_world.tres") as BiomeData
	fire_room.setup(fire_data, fire_biome)
	
	var fire_floor: TextureRect = fire_room.get_node("%FloorTiles") as TextureRect
	assert_eq(fire_floor.texture, SpriteGenerator.get_biome_tile_texture("fire_world"), "В Мире Огня установлены базальтовые плиты с лавой")
	assert_ne(fire_floor.texture, frost_floor.texture, "Плитка Мира Огня кардинально отличается от Мира Холода")

