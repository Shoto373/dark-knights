class_name SpriteGenerator
extends RefCounted

## Процедурный генератор высококачественных пиксель-арт спрайтов и иконок
## Создает детализированные текстуры персонажей, врагов и боссов с контурами, штриховкой и бликами.

static var _cache: Dictionary = {}

# Цветовая палитра
const C_TRANSPARENT: Color = Color(0, 0, 0, 0)
const C_OUTLINE: Color = Color(0.08, 0.08, 0.12, 1.0)
const C_DARK_OUTLINE: Color = Color(0.04, 0.04, 0.06, 1.0)

# ==========================================
# ПУБЛИЧНЫЕ МЕТОДЫ ПОЛУЧЕНИЯ ТЕКСТУР
# ==========================================

static func get_hero_texture(hero_id: String) -> Texture2D:
	var key: String = "hero_" + hero_id
	if _cache.has(key):
		return _cache[key]
	
	var svg_path: String = "res://assets/sprites/hero_%s.svg" % hero_id
	if ResourceLoader.exists(svg_path):
		var tex: Texture2D = load(svg_path)
		if tex:
			_cache[key] = tex
			return tex
	
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	
	match hero_id:
		"warrior":
			_draw_warrior_sprite(img)
		"mage":
			_draw_mage_sprite(img)
		"ranger":
			_draw_ranger_sprite(img)
		_:
			_draw_warrior_sprite(img)
	
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_hero_icon(hero_id: String) -> Texture2D:
	var key: String = "icon_hero_" + hero_id
	if _cache.has(key):
		return _cache[key]
	
	var svg_path: String = "res://assets/sprites/icon_%s.svg" % hero_id
	if ResourceLoader.exists(svg_path):
		var tex: Texture2D = load(svg_path)
		if tex:
			_cache[key] = tex
			return tex
	
	var img: Image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	
	# Золотая рамка иконки
	_draw_box(img, 1, 1, 38, 38, Color(0.85, 0.7, 0.25, 1.0))
	_draw_box(img, 2, 2, 36, 36, Color(0.12, 0.14, 0.2, 1.0))
	
	# Портрет по центру
	match hero_id:
		"warrior":
			_draw_warrior_portrait(img, 4, 4)
		"mage":
			_draw_mage_portrait(img, 4, 4)
		"ranger":
			_draw_ranger_portrait(img, 4, 4)
		_:
			_draw_warrior_portrait(img, 4, 4)
			
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_enemy_texture(enemy_type: String) -> Texture2D:
	var clean_type: String = enemy_type.trim_prefix("enemy_")
	match clean_type:
		"boulder_thrower": clean_type = "stone_thrower"
		"frost_wraith": clean_type = "ice_wraith"
		"necromancer": clean_type = "necromancer_acolyte"
		"crossbowman": clean_type = "skeleton_crossbowman"

	var key: String = "enemy_" + clean_type
	if _cache.has(key):
		return _cache[key]
		
	var svg_path: String = "res://assets/sprites/enemy_%s.svg" % clean_type
	if ResourceLoader.exists(svg_path):
		var tex: Texture2D = load(svg_path)
		if tex:
			_cache[key] = tex
			return tex
			
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	
	match clean_type:
		# Темница гоблинов
		"goblin_slasher":
			_draw_goblin_slasher(img)
		"goblin_archer":
			_draw_goblin_archer(img)
		"goblin_shaman":
			_draw_goblin_shaman(img)
		"goblin_brute":
			_draw_goblin_brute(img)
			
		# Ущелье троллей
		"troll_brute":
			_draw_troll_brute(img)
		"stone_thrower":
			_draw_troll_thrower(img)
		"troll_regenerator":
			_draw_troll_regen(img)
			
		# Замок скелетов
		"skeleton_swordsman":
			_draw_skeleton_swordsman(img)
		"skeleton_crossbowman":
			_draw_skeleton_crossbowman(img)
		"necromancer_acolyte":
			_draw_necromancer(img)
		"knight_guard":
			_draw_knight_guard(img)
			
		# Мир холода
		"ice_wraith":
			_draw_ice_wraith(img)
		"frost_golem":
			_draw_frost_golem(img)
		"lich_apprentice":
			_draw_lich_apprentice(img)
		"ice_spider":
			_draw_ice_spider(img)
			
		# Мир огня
		"lava_slime":
			_draw_lava_slime(img)
		"fire_elemental":
			_draw_fire_elemental(img)
		"flame_cultist":
			_draw_flame_cultist(img)
		"magma_worm":
			_draw_magma_worm(img)
			
		# Чистилище
		"shadow_chimera":
			_draw_shadow_chimera(img)
		"fallen_archon":
			_draw_fallen_archon(img)
		"void_specter":
			_draw_void_specter(img)
		"purgatory_executioner":
			_draw_executioner(img)
			
		_:
			_draw_goblin_slasher(img)
			
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_boss_texture(boss_id: String) -> Texture2D:
	var key: String = "boss_" + boss_id
	if _cache.has(key):
		return _cache[key]
		
	var mapped_name: String = ""
	match boss_id:
		"goblin_boss", "boss_goblin": mapped_name = "boss_goblin"
		"troll_king", "boss_troll": mapped_name = "boss_troll"
		"skeleton_knight", "boss_skeleton_knight", "boss_skeleton": mapped_name = "boss_skeleton"
		"lich_king", "boss_lich_king", "boss_lich": mapped_name = "boss_lich"
		"dragon", "boss_dragon": mapped_name = "boss_dragon"
		"purgatory_lord", "boss_purgatory_lord", "boss_purgatory": mapped_name = "boss_purgatory"
		_:
			if boss_id.begins_with("boss_"):
				mapped_name = boss_id
			else:
				mapped_name = "boss_" + boss_id

	var svg_path: String = "res://assets/sprites/%s.svg" % mapped_name
	if ResourceLoader.exists(svg_path):
		var tex: Texture2D = load(svg_path)
		if tex:
			_cache[key] = tex
			return tex

	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	
	match boss_id:
		"goblin_boss", "boss_goblin":
			_draw_boss_goblin(img)
		"troll_king", "boss_troll":
			_draw_boss_troll(img)
		"skeleton_knight", "boss_skeleton_knight":
			_draw_boss_skeleton(img)
		"lich_king", "boss_lich_king":
			_draw_boss_lich(img)
		"dragon", "boss_dragon":
			_draw_boss_dragon(img)
		"purgatory_lord", "boss_purgatory_lord":
			_draw_boss_purgatory(img)
		_:
			_draw_boss_goblin(img)
			
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_weapon_texture(hero_or_weapon: String) -> Texture2D:
	var key: String = "weapon_" + hero_or_weapon
	if _cache.has(key):
		return _cache[key]
	var weapon_file: String = "weapon_sword.svg"
	match hero_or_weapon:
		"warrior", "sword":
			weapon_file = "weapon_sword.svg"
		"mage", "staff":
			weapon_file = "weapon_staff.svg"
		"ranger", "bow":
			weapon_file = "weapon_bow.svg"
		_:
			weapon_file = "weapon_sword.svg"
	var path: String = "res://assets/sprites/" + weapon_file
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache[key] = t
			return t
	return null

static func get_projectile_texture(proj_type: String) -> Texture2D:
	var key: String = "proj_" + proj_type
	if _cache.has(key):
		return _cache[key]
	var file_name: String = "projectile_magic_bolt.svg"
	match proj_type:
		"arrow", "ranger":
			file_name = "projectile_arrow.svg"
		"fire", "fireball":
			file_name = "projectile_fireball.svg"
		"frost", "freeze", "ice":
			file_name = "projectile_frost_shard.svg"
		"magic", "mage", _:
			file_name = "projectile_magic_bolt.svg"
	var path: String = "res://assets/sprites/" + file_name
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache[key] = t
			return t
	return null

static func get_portal_texture() -> Texture2D:
	if _cache.has("portal_rift"):
		return _cache["portal_rift"]
	var path: String = "res://assets/sprites/portal_rift.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["portal_rift"] = t
			return t
	return null

static func get_torch_texture() -> Texture2D:
	if _cache.has("wall_torch"):
		return _cache["wall_torch"]
	var path: String = "res://assets/sprites/wall_torch.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["wall_torch"] = t
			return t
	return null

static func get_torch_flame_texture() -> Texture2D:
	if _cache.has("torch_flame"):
		return _cache["torch_flame"]
	var path: String = "res://assets/sprites/torch_flame.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["torch_flame"] = t
			return t
	return null

static func get_light_halo_texture() -> Texture2D:
	if _cache.has("light_halo"):
		return _cache["light_halo"]
	var path: String = "res://assets/sprites/light_halo.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["light_halo"] = t
			return t
	return null

static func get_target_dummy_texture() -> Texture2D:
	if _cache.has("target_dummy"):
		return _cache["target_dummy"]
	var path: String = "res://assets/sprites/target_dummy.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["target_dummy"] = t
			return t
	return null

static func get_trap_texture(extended: bool) -> Texture2D:
	var key: String = "trap_spikes_" + ("ext" if extended else "ret")
	if _cache.has(key):
		return _cache[key]
	var file_name: String = "trap_spikes_extended.svg" if extended else "trap_spikes_retracted.svg"
	var path: String = "res://assets/sprites/" + file_name
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache[key] = t
			return t
	return null

static func get_pillar_texture() -> Texture2D:
	if _cache.has("pillar_corner"):
		return _cache["pillar_corner"]
	var path: String = "res://assets/sprites/pillar_corner.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["pillar_corner"] = t
			return t
	return null

static func get_dungeon_tile_texture() -> Texture2D:
	if _cache.has("dungeon_stone_tile"):
		return _cache["dungeon_stone_tile"]
	var path: String = "res://assets/sprites/dungeon_stone_tile.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["dungeon_stone_tile"] = t
			return t
	return null

static func get_wall_brick_texture() -> Texture2D:
	if _cache.has("dungeon_wall_brick"):
		return _cache["dungeon_wall_brick"]
	var path: String = "res://assets/sprites/dungeon_wall_brick.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["dungeon_wall_brick"] = t
			return t
	return null

static func get_floor_crest_texture() -> Texture2D:
	if _cache.has("dungeon_floor_crest"):
		return _cache["dungeon_floor_crest"]
	var path: String = "res://assets/sprites/dungeon_floor_crest.svg"
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_cache["dungeon_floor_crest"] = t
			return t
	return null

static func get_item_texture(item_data: ItemData) -> Texture2D:
	if item_data == null:
		return null
	if item_data.icon != null:
		return item_data.icon
	
	var item_id: String = item_data.id if not item_data.id.is_empty() else item_data.name.to_lower()
	var key: String = "item_" + item_id
	if _cache.has(key):
		return _cache[key]
	
	var img: Image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	
	var r_col: Color = item_data.get_rarity_color()
	_draw_item_icon(img, item_id, item_data.tags, r_col)
	
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func _draw_item_icon(img: Image, item_id: String, tags: Array[String], r_col: Color) -> void:
	var id_lower: String = item_id.to_lower()
	if id_lower.contains("sword") or id_lower.contains("blade") or id_lower.contains("dagger") or id_lower.contains("axe"):
		_draw_item_sword(img, r_col)
	elif id_lower.contains("shield") or id_lower.contains("buckler") or tags.has("armor"):
		_draw_item_shield(img, r_col)
	elif id_lower.contains("ring"):
		_draw_item_ring(img, r_col)
	elif id_lower.contains("boots"):
		_draw_item_boots(img, r_col)
	elif id_lower.contains("amulet") or id_lower.contains("pendant") or id_lower.contains("heart") or id_lower.contains("core"):
		_draw_item_amulet(img, r_col)
	elif id_lower.contains("helmet") or id_lower.contains("cowl") or id_lower.contains("crown"):
		_draw_item_helmet(img, r_col)
	elif id_lower.contains("tome") or id_lower.contains("orb") or id_lower.contains("shard") or id_lower.contains("feather") or id_lower.contains("stone"):
		_draw_item_tome(img, r_col)
	elif id_lower.contains("apple") or id_lower.contains("potion") or id_lower.contains("fang"):
		_draw_item_potion(img, r_col)
	else:
		_draw_item_relic(img, r_col)

static func _draw_item_sword(img: Image, r_col: Color) -> void:
	# Рукоять и гарда
	_fill_rect(img, 4, 18, 4, 3, Color(0.4, 0.25, 0.1))
	_set_p(img, 3, 20, Color(0.85, 0.7, 0.2)) # Навершие
	_fill_rect(img, 6, 15, 6, 2, Color(0.7, 0.65, 0.6)) # Гарда
	# Клинок по диагонали
	for i in range(12):
		var px: int = 8 + i
		var py: int = 14 - i
		_set_p(img, px, py, Color(0.85, 0.9, 0.95))
		_set_p(img, px - 1, py, Color(0.65, 0.7, 0.75))
		_set_p(img, px, py + 1, Color(0.5, 0.55, 0.6))
	# Острие и руническое сияние
	_set_p(img, 20, 2, Color(1, 1, 1))
	_set_p(img, 9, 16, r_col)

static func _draw_item_shield(img: Image, r_col: Color) -> void:
	# Корпус щита
	_draw_box(img, 5, 4, 14, 15, Color(0.2, 0.22, 0.26))
	_fill_rect(img, 6, 5, 12, 13, Color(0.35, 0.38, 0.45))
	# Нижнее сужение
	_fill_rect(img, 7, 18, 10, 2, Color(0.2, 0.22, 0.26))
	_fill_rect(img, 9, 20, 6, 2, Color(0.2, 0.22, 0.26))
	_set_p(img, 11, 22, Color(0.2, 0.22, 0.26))
	_set_p(img, 12, 22, Color(0.2, 0.22, 0.26))
	# Геральдический крест
	_fill_rect(img, 11, 7, 2, 9, r_col)
	_fill_rect(img, 8, 10, 8, 2, r_col)

static func _draw_item_ring(img: Image, r_col: Color) -> void:
	# Золотой обод кольца
	_draw_box(img, 6, 8, 12, 12, Color(0.85, 0.65, 0.15))
	_fill_rect(img, 8, 10, 8, 8, C_TRANSPARENT)
	# Драгоценный камень
	_fill_rect(img, 10, 4, 4, 4, r_col)
	_set_p(img, 11, 5, Color(1, 1, 1)) # Блик

static func _draw_item_boots(img: Image, r_col: Color) -> void:
	# Голенище
	_fill_rect(img, 7, 5, 6, 10, Color(0.3, 0.25, 0.2))
	# Подошва и носок
	_fill_rect(img, 7, 15, 11, 4, Color(0.2, 0.15, 0.1))
	_set_p(img, 18, 16, Color(0.2, 0.15, 0.1))
	# Пряжка редкости
	_fill_rect(img, 8, 9, 4, 2, r_col)

static func _draw_item_amulet(img: Image, r_col: Color) -> void:
	# Цепочка
	_set_p(img, 8, 4, Color(0.85, 0.7, 0.2))
	_set_p(img, 9, 6, Color(0.85, 0.7, 0.2))
	_set_p(img, 15, 4, Color(0.85, 0.7, 0.2))
	_set_p(img, 14, 6, Color(0.85, 0.7, 0.2))
	# Медальон / Сердце
	_fill_rect(img, 9, 8, 6, 7, r_col)
	_draw_box(img, 8, 7, 8, 9, Color(0.85, 0.7, 0.2))
	_set_p(img, 11, 10, Color(1, 1, 1))

static func _draw_item_helmet(img: Image, r_col: Color) -> void:
	# Шлем
	_draw_box(img, 6, 6, 12, 13, Color(0.2, 0.22, 0.26))
	_fill_rect(img, 7, 7, 10, 11, Color(0.4, 0.44, 0.5))
	# Прорезь для глаз
	_fill_rect(img, 8, 12, 8, 2, Color(0.08, 0.08, 0.12))
	# Плюмаж / гребень
	_fill_rect(img, 11, 3, 2, 4, r_col)

static func _draw_item_tome(img: Image, r_col: Color) -> void:
	# Обложка гримуара
	_fill_rect(img, 5, 5, 14, 15, Color(0.25, 0.18, 0.35))
	_draw_box(img, 5, 5, 14, 15, Color(0.85, 0.7, 0.2))
	# Страницы
	_fill_rect(img, 18, 6, 2, 13, Color(0.9, 0.85, 0.7))
	# Рунический символ
	_fill_rect(img, 9, 9, 5, 5, r_col)
	_set_p(img, 11, 11, Color(1, 1, 1))

static func _draw_item_potion(img: Image, r_col: Color) -> void:
	# Пробка и горлышко
	_fill_rect(img, 10, 4, 4, 3, Color(0.5, 0.35, 0.2))
	_fill_rect(img, 11, 7, 2, 3, Color(0.7, 0.85, 0.9, 0.8))
	# Колба с зельем
	_draw_box(img, 7, 10, 10, 10, Color(0.6, 0.75, 0.85))
	_fill_rect(img, 8, 12, 8, 7, r_col)
	_set_p(img, 9, 14, Color(1, 1, 1))

static func _draw_item_relic(img: Image, r_col: Color) -> void:
	# Рунический камень
	_draw_box(img, 6, 5, 12, 14, Color(0.3, 0.34, 0.4))
	_fill_rect(img, 7, 6, 10, 12, Color(0.18, 0.2, 0.25))
	# Светящаяся руна в центре
	_fill_rect(img, 10, 9, 4, 6, r_col)
	_set_p(img, 11, 8, r_col)
	_set_p(img, 12, 8, r_col)
	_set_p(img, 11, 11, Color(1, 1, 1))

# ==========================================
# ВСПОМОГАТЕЛЬНЫЕ ГРАФИЧЕСКИЕ ПРИМИТИВЫ
# ==========================================

static func _set_p(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)

static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			_set_p(img, px, py, col)

static func _draw_box(img: Image, x: int, y: int, w: int, h: int, border_col: Color) -> void:
	for px in range(x, x + w):
		_set_p(img, px, y, border_col)
		_set_p(img, px, y + h - 1, border_col)
	for py in range(y, y + h):
		_set_p(img, x, py, border_col)
		_set_p(img, x + w - 1, py, border_col)

# ==========================================
# ГЕРОИ (32x32 СПРАЙТЫ)
# ==========================================

static func _draw_warrior_sprite(img: Image) -> void:
	# Синий плащ за спиной
	_fill_rect(img, 9, 12, 14, 15, Color(0.12, 0.22, 0.45))
	_fill_rect(img, 10, 13, 12, 13, Color(0.18, 0.35, 0.65))
	
	# Стальной шлем с забралом
	_fill_rect(img, 11, 4, 10, 10, C_OUTLINE)
	_fill_rect(img, 12, 5, 8, 8, Color(0.65, 0.7, 0.78))
	_fill_rect(img, 13, 5, 6, 3, Color(0.85, 0.88, 0.95)) # Блик шлема
	# Т-образная прорезь забрала и сияющие глаза
	_fill_rect(img, 13, 9, 6, 2, C_DARK_OUTLINE)
	_fill_rect(img, 15, 9, 2, 5, C_DARK_OUTLINE)
	_set_p(img, 14, 9, Color(0.3, 0.85, 1.0)) # Свет глаз
	_set_p(img, 17, 9, Color(0.3, 0.85, 1.0))
	
	# Нагрудник (стальные латы с золотой инкрустацией)
	_fill_rect(img, 11, 14, 10, 10, C_OUTLINE)
	_fill_rect(img, 12, 15, 8, 8, Color(0.55, 0.6, 0.7))
	_fill_rect(img, 14, 16, 4, 5, Color(0.9, 0.75, 0.2)) # Золотой герб
	
	# Стальные наплечники
	_fill_rect(img, 9, 14, 3, 5, Color(0.7, 0.75, 0.85))
	_fill_rect(img, 20, 14, 3, 5, Color(0.7, 0.75, 0.85))
	
	# Пояс и поножи
	_fill_rect(img, 12, 22, 8, 2, Color(0.35, 0.22, 0.1))
	_fill_rect(img, 12, 24, 3, 6, Color(0.45, 0.5, 0.58))
	_fill_rect(img, 17, 24, 3, 6, Color(0.45, 0.5, 0.58))
	
	# Стальные латные наручи и рукавицы (оружие динамически управляется WeaponPivot)
	_fill_rect(img, 8, 18, 3, 4, Color(0.55, 0.6, 0.7))
	_fill_rect(img, 21, 18, 3, 4, Color(0.55, 0.6, 0.7))

static func _draw_mage_sprite(img: Image) -> void:
	# Фиолетовая мантия мага
	_fill_rect(img, 10, 13, 12, 15, C_OUTLINE)
	_fill_rect(img, 11, 14, 10, 13, Color(0.35, 0.15, 0.55))
	_fill_rect(img, 13, 14, 6, 13, Color(0.45, 0.2, 0.7))
	_fill_rect(img, 15, 14, 2, 13, Color(0.85, 0.75, 0.25)) # Золотая тесьма
	
	# Глубокий капюшон
	_fill_rect(img, 10, 4, 12, 11, C_OUTLINE)
	_fill_rect(img, 11, 5, 10, 9, Color(0.3, 0.12, 0.5))
	_fill_rect(img, 12, 8, 8, 5, C_DARK_OUTLINE) # Тень под капюшоном
	# Мистические сияющие фиолетово-голубые глаза
	_set_p(img, 14, 10, Color(0.5, 0.95, 1.0))
	_set_p(img, 17, 10, Color(0.5, 0.95, 1.0))
	_set_p(img, 13, 10, Color(0.8, 0.4, 1.0))
	_set_p(img, 18, 10, Color(0.8, 0.4, 1.0))
	
	# Рукава мантии и золотая кайма (оружие динамически управляется WeaponPivot)
	_fill_rect(img, 8, 16, 3, 6, Color(0.3, 0.12, 0.5))
	_fill_rect(img, 21, 16, 3, 6, Color(0.3, 0.12, 0.5))
	_fill_rect(img, 8, 21, 3, 2, Color(0.85, 0.75, 0.25))
	_fill_rect(img, 21, 21, 3, 2, Color(0.85, 0.75, 0.25))

static func _draw_ranger_sprite(img: Image) -> void:
	# Зеленый лесной плащ и колчан
	_fill_rect(img, 9, 13, 14, 14, C_OUTLINE)
	_fill_rect(img, 10, 14, 12, 12, Color(0.18, 0.38, 0.22))
	# Колчан со стрелами на плече
	_fill_rect(img, 20, 9, 3, 8, Color(0.45, 0.3, 0.15))
	_set_p(img, 21, 8, Color(0.9, 0.9, 0.9)) # Оперение
	_set_p(img, 22, 7, Color(0.9, 0.9, 0.9))
	
	# Капюшон следопыта с маской
	_fill_rect(img, 11, 4, 10, 10, C_OUTLINE)
	_fill_rect(img, 12, 5, 8, 8, Color(0.22, 0.45, 0.25))
	# Зоркие янтарные глаза
	_fill_rect(img, 13, 8, 6, 2, C_DARK_OUTLINE)
	_set_p(img, 14, 8, Color(1.0, 0.85, 0.2))
	_set_p(img, 17, 8, Color(1.0, 0.85, 0.2))
	# Кожаная полумаска
	_fill_rect(img, 13, 10, 6, 3, Color(0.38, 0.25, 0.15))
	
	# Кожаный доспех с ремнями
	_fill_rect(img, 12, 14, 8, 8, Color(0.35, 0.24, 0.14))
	_fill_rect(img, 14, 14, 2, 8, Color(0.55, 0.4, 0.25))
	_fill_rect(img, 12, 22, 3, 7, Color(0.2, 0.3, 0.2))
	_fill_rect(img, 17, 22, 3, 7, Color(0.2, 0.3, 0.2))
	
	# Кожаные наручи (лук динамически управляется WeaponPivot)
	_fill_rect(img, 8, 16, 3, 5, Color(0.38, 0.25, 0.15))
	_fill_rect(img, 21, 16, 3, 5, Color(0.38, 0.25, 0.15))

# ==========================================
# ИКОНКИ ГЕРОЕВ (ПОРТРЕТЫ 40x40)
# ==========================================

static func _draw_warrior_portrait(img: Image, ox: int, oy: int) -> void:
	_fill_rect(img, ox + 6, oy + 4, 20, 20, Color(0.65, 0.7, 0.78))
	_draw_box(img, ox + 5, oy + 3, 22, 22, C_DARK_OUTLINE)
	_fill_rect(img, ox + 8, oy + 5, 16, 5, Color(0.85, 0.88, 0.95))
	_fill_rect(img, ox + 9, oy + 12, 14, 4, C_DARK_OUTLINE)
	_fill_rect(img, ox + 15, oy + 12, 2, 9, C_DARK_OUTLINE)
	_fill_rect(img, ox + 11, oy + 13, 3, 2, Color(0.3, 0.85, 1.0))
	_fill_rect(img, ox + 18, oy + 13, 3, 2, Color(0.3, 0.85, 1.0))
	_fill_rect(img, ox + 8, oy + 24, 16, 6, Color(0.55, 0.6, 0.7))

static func _draw_mage_portrait(img: Image, ox: int, oy: int) -> void:
	_fill_rect(img, ox + 5, oy + 4, 22, 22, Color(0.35, 0.15, 0.55))
	_draw_box(img, ox + 4, oy + 3, 24, 24, C_DARK_OUTLINE)
	_fill_rect(img, ox + 8, oy + 10, 16, 12, C_DARK_OUTLINE)
	_fill_rect(img, ox + 10, oy + 13, 4, 3, Color(0.4, 0.95, 1.0))
	_fill_rect(img, ox + 18, oy + 13, 4, 3, Color(0.4, 0.95, 1.0))
	_fill_rect(img, ox + 8, oy + 24, 16, 6, Color(0.85, 0.75, 0.25))

static func _draw_ranger_portrait(img: Image, ox: int, oy: int) -> void:
	_fill_rect(img, ox + 6, oy + 4, 20, 20, Color(0.22, 0.45, 0.25))
	_draw_box(img, ox + 5, oy + 3, 22, 22, C_DARK_OUTLINE)
	_fill_rect(img, ox + 9, oy + 11, 14, 4, C_DARK_OUTLINE)
	_fill_rect(img, ox + 10, oy + 12, 4, 2, Color(1.0, 0.85, 0.2))
	_fill_rect(img, ox + 18, oy + 12, 4, 2, Color(1.0, 0.85, 0.2))
	_fill_rect(img, ox + 9, oy + 15, 14, 8, Color(0.38, 0.25, 0.15))

# ==========================================
# ВРАГИ (32x32 СПРАЙТЫ ПО БИОМАМ)
# ==========================================

# 1. Гоблины
static func _draw_goblin_slasher(img: Image) -> void:
	_fill_rect(img, 11, 6, 10, 9, Color(0.3, 0.65, 0.25))
	_draw_box(img, 10, 5, 12, 11, C_OUTLINE)
	# Острые уши
	_fill_rect(img, 7, 7, 3, 3, Color(0.3, 0.65, 0.25))
	_fill_rect(img, 22, 7, 3, 3, Color(0.3, 0.65, 0.25))
	# Красные злобные глаза
	_fill_rect(img, 13, 9, 2, 2, Color(0.95, 0.15, 0.15))
	_fill_rect(img, 17, 9, 2, 2, Color(0.95, 0.15, 0.15))
	# Торс в лохмотьях
	_fill_rect(img, 11, 15, 10, 9, Color(0.45, 0.32, 0.2))
	# Тесак
	_fill_rect(img, 23, 11, 3, 10, Color(0.7, 0.75, 0.8))
	_fill_rect(img, 22, 19, 2, 4, Color(0.4, 0.2, 0.1))

static func _draw_goblin_archer(img: Image) -> void:
	_draw_goblin_slasher(img)
	# Лук вместо тесака
	_fill_rect(img, 22, 10, 2, 12, Color(0.55, 0.38, 0.2))

static func _draw_goblin_shaman(img: Image) -> void:
	_fill_rect(img, 11, 8, 10, 8, Color(0.32, 0.58, 0.28))
	# Магическая костяная маска / череп
	_fill_rect(img, 12, 5, 8, 7, Color(0.9, 0.9, 0.85))
	_set_p(img, 14, 8, Color(0.1, 0.1, 0.1))
	_set_p(img, 17, 8, Color(0.1, 0.1, 0.1))
	# Посох с черепом
	_fill_rect(img, 24, 7, 2, 17, Color(0.4, 0.25, 0.15))
	_fill_rect(img, 23, 4, 4, 4, Color(0.95, 0.85, 0.2))

static func _draw_goblin_brute(img: Image) -> void:
	# Массивное зеленое тело
	_fill_rect(img, 8, 5, 16, 12, Color(0.25, 0.55, 0.2))
	_draw_box(img, 7, 4, 18, 14, C_OUTLINE)
	_fill_rect(img, 11, 9, 3, 2, Color(1, 0.2, 0.2))
	_fill_rect(img, 18, 9, 3, 2, Color(1, 0.2, 0.2))
	# Торс с железным поясом
	_fill_rect(img, 9, 16, 14, 10, Color(0.35, 0.35, 0.4))
	# Шипованная дубина
	_fill_rect(img, 25, 6, 4, 16, Color(0.5, 0.35, 0.2))
	_set_p(img, 24, 8, Color(0.8, 0.8, 0.85))
	_set_p(img, 29, 10, Color(0.8, 0.8, 0.85))

# 2. Тролли
static func _draw_troll_brute(img: Image) -> void:
	_fill_rect(img, 8, 6, 16, 13, Color(0.45, 0.42, 0.4))
	_draw_box(img, 7, 5, 18, 15, C_OUTLINE)
	_fill_rect(img, 11, 10, 3, 3, Color(1.0, 0.5, 0.1))
	_fill_rect(img, 18, 10, 3, 3, Color(1.0, 0.5, 0.1))
	# Каменная броня
	_fill_rect(img, 9, 17, 14, 10, Color(0.35, 0.32, 0.3))

static func _draw_troll_thrower(img: Image) -> void:
	_draw_troll_brute(img)
	# Валун в руке
	_fill_rect(img, 23, 12, 7, 7, Color(0.55, 0.52, 0.48))
	_draw_box(img, 22, 11, 9, 9, C_OUTLINE)

static func _draw_troll_regen(img: Image) -> void:
	_draw_troll_brute(img)
	# Зеленые светящиеся руны регенерации
	_fill_rect(img, 12, 18, 2, 6, Color(0.3, 0.95, 0.4))
	_fill_rect(img, 18, 18, 2, 6, Color(0.3, 0.95, 0.4))

# 3. Скелеты
static func _draw_skeleton_swordsman(img: Image) -> void:
	# Белый череп
	_fill_rect(img, 11, 5, 10, 9, Color(0.9, 0.92, 0.92))
	_draw_box(img, 10, 4, 12, 11, C_OUTLINE)
	# Глазницы с синим огнем
	_fill_rect(img, 13, 8, 2, 3, Color(0.1, 0.1, 0.15))
	_fill_rect(img, 17, 8, 2, 3, Color(0.1, 0.1, 0.15))
	_set_p(img, 13, 9, Color(0.3, 0.8, 1.0))
	_set_p(img, 17, 9, Color(0.3, 0.8, 1.0))
	# Грудная клетка (ребра)
	_fill_rect(img, 12, 15, 8, 8, Color(0.85, 0.85, 0.85))
	_fill_rect(img, 13, 16, 6, 1, C_OUTLINE)
	_fill_rect(img, 13, 18, 6, 1, C_OUTLINE)
	# Ржавый меч
	_fill_rect(img, 24, 7, 2, 14, Color(0.65, 0.55, 0.45))

static func _draw_skeleton_crossbowman(img: Image) -> void:
	_draw_skeleton_swordsman(img)
	_fill_rect(img, 22, 12, 6, 6, Color(0.4, 0.28, 0.18))

static func _draw_necromancer(img: Image) -> void:
	_fill_rect(img, 10, 5, 12, 12, Color(0.2, 0.15, 0.3))
	_draw_box(img, 9, 4, 14, 14, C_OUTLINE)
	_fill_rect(img, 13, 9, 2, 2, Color(0.8, 0.2, 0.9))
	_fill_rect(img, 17, 9, 2, 2, Color(0.8, 0.2, 0.9))
	_fill_rect(img, 10, 16, 12, 11, Color(0.15, 0.1, 0.25))

static func _draw_knight_guard(img: Image) -> void:
	_draw_skeleton_swordsman(img)
	# Башенный щит спереди
	_fill_rect(img, 4, 10, 7, 16, Color(0.45, 0.5, 0.6))
	_draw_box(img, 3, 9, 9, 18, Color(0.85, 0.75, 0.3))

# 4. Мир холода
static func _draw_ice_wraith(img: Image) -> void:
	_fill_rect(img, 10, 6, 12, 16, Color(0.5, 0.8, 1.0, 0.85))
	_draw_box(img, 9, 5, 14, 18, Color(0.85, 0.95, 1.0))
	_fill_rect(img, 13, 9, 2, 2, Color(1, 1, 1))
	_fill_rect(img, 17, 9, 2, 2, Color(1, 1, 1))

static func _draw_frost_golem(img: Image) -> void:
	_fill_rect(img, 8, 5, 16, 18, Color(0.35, 0.6, 0.85))
	_draw_box(img, 7, 4, 18, 20, Color(0.8, 0.95, 1.0))
	_fill_rect(img, 11, 9, 3, 3, Color(0.9, 1.0, 1.0))
	_fill_rect(img, 18, 9, 3, 3, Color(0.9, 1.0, 1.0))

static func _draw_lich_apprentice(img: Image) -> void:
	_fill_rect(img, 10, 6, 12, 18, Color(0.2, 0.35, 0.6))
	_draw_box(img, 9, 5, 14, 20, Color(0.5, 0.8, 1.0))
	_fill_rect(img, 13, 10, 2, 2, Color(0.4, 0.9, 1.0))
	_fill_rect(img, 17, 10, 2, 2, Color(0.4, 0.9, 1.0))

static func _draw_ice_spider(img: Image) -> void:
	_fill_rect(img, 10, 10, 12, 10, Color(0.4, 0.7, 0.9))
	_draw_box(img, 9, 9, 14, 12, Color(0.8, 0.95, 1.0))
	# Глаза
	_set_p(img, 12, 12, Color(0.1, 0.9, 1.0))
	_set_p(img, 14, 12, Color(0.1, 0.9, 1.0))
	_set_p(img, 16, 12, Color(0.1, 0.9, 1.0))
	_set_p(img, 18, 12, Color(0.1, 0.9, 1.0))
	# Лапки
	_fill_rect(img, 5, 8, 4, 2, Color(0.3, 0.6, 0.8))
	_fill_rect(img, 23, 8, 4, 2, Color(0.3, 0.6, 0.8))

# 5. Мир огня
static func _draw_lava_slime(img: Image) -> void:
	_fill_rect(img, 9, 10, 14, 12, Color(0.95, 0.45, 0.1))
	_fill_rect(img, 12, 12, 8, 8, Color(1.0, 0.8, 0.2)) # Раскаленное ядро
	_draw_box(img, 8, 9, 16, 14, Color(0.5, 0.15, 0.05))
	_fill_rect(img, 12, 13, 2, 2, Color(1, 1, 1))
	_fill_rect(img, 18, 13, 2, 2, Color(1, 1, 1))

static func _draw_fire_elemental(img: Image) -> void:
	_fill_rect(img, 10, 6, 12, 16, Color(1.0, 0.35, 0.1))
	_draw_box(img, 9, 5, 14, 18, Color(1.0, 0.8, 0.2))
	_fill_rect(img, 13, 10, 2, 2, Color(1, 1, 0.4))
	_fill_rect(img, 17, 10, 2, 2, Color(1, 1, 0.4))

static func _draw_flame_cultist(img: Image) -> void:
	_fill_rect(img, 10, 6, 12, 18, Color(0.5, 0.1, 0.1))
	_draw_box(img, 9, 5, 14, 20, Color(0.9, 0.3, 0.1))
	_fill_rect(img, 13, 10, 2, 2, Color(1, 0.6, 0.1))
	_fill_rect(img, 17, 10, 2, 2, Color(1, 0.6, 0.1))

static func _draw_magma_worm(img: Image) -> void:
	_fill_rect(img, 9, 7, 14, 16, Color(0.35, 0.12, 0.08))
	_draw_box(img, 8, 6, 16, 18, Color(0.9, 0.4, 0.1))
	_fill_rect(img, 11, 11, 10, 2, Color(1.0, 0.6, 0.1))
	_fill_rect(img, 11, 16, 10, 2, Color(1.0, 0.6, 0.1))

# 6. Чистилище
static func _draw_shadow_chimera(img: Image) -> void:
	_fill_rect(img, 8, 6, 16, 16, Color(0.2, 0.1, 0.3))
	_draw_box(img, 7, 5, 18, 18, Color(0.6, 0.2, 0.8))
	_fill_rect(img, 11, 9, 3, 2, Color(0.4, 1.0, 0.5)) # Ядовитые глаза
	_fill_rect(img, 18, 9, 3, 2, Color(0.4, 1.0, 0.5))

static func _draw_fallen_archon(img: Image) -> void:
	_fill_rect(img, 10, 6, 12, 18, Color(0.4, 0.35, 0.2))
	_draw_box(img, 9, 5, 14, 20, Color(0.9, 0.8, 0.3))
	_fill_rect(img, 5, 8, 5, 12, Color(0.2, 0.15, 0.3)) # Темные крылья
	_fill_rect(img, 22, 8, 5, 12, Color(0.2, 0.15, 0.3))
	_fill_rect(img, 13, 10, 2, 2, Color(1.0, 0.9, 0.4))
	_fill_rect(img, 17, 10, 2, 2, Color(1.0, 0.9, 0.4))

static func _draw_void_specter(img: Image) -> void:
	_fill_rect(img, 10, 6, 12, 18, Color(0.12, 0.08, 0.22, 0.9))
	_draw_box(img, 9, 5, 14, 20, Color(0.7, 0.4, 1.0))
	_fill_rect(img, 14, 11, 4, 4, Color(1.0, 1.0, 1.0)) # Око пустоты

static func _draw_executioner(img: Image) -> void:
	_fill_rect(img, 8, 5, 16, 20, Color(0.25, 0.2, 0.28))
	_draw_box(img, 7, 4, 18, 22, Color(0.7, 0.2, 0.4))
	_fill_rect(img, 12, 9, 3, 2, Color(0.9, 0.1, 0.2))
	_fill_rect(img, 17, 9, 3, 2, Color(0.9, 0.1, 0.2))
	# Топор палача
	_fill_rect(img, 24, 4, 6, 8, Color(0.7, 0.75, 0.85))
	_fill_rect(img, 26, 12, 2, 14, Color(0.4, 0.25, 0.15))

# ==========================================
# БОССЫ (48x48 СПРАЙТЫ)
# ==========================================

static func _draw_boss_goblin(img: Image) -> void:
	_fill_rect(img, 12, 8, 24, 20, Color(0.28, 0.58, 0.22))
	_draw_box(img, 11, 7, 26, 22, C_DARK_OUTLINE)
	# Корона из костей и рогов
	_fill_rect(img, 14, 3, 4, 5, Color(0.9, 0.85, 0.7))
	_fill_rect(img, 22, 2, 4, 6, Color(0.9, 0.85, 0.7))
	_fill_rect(img, 30, 3, 4, 5, Color(0.9, 0.85, 0.7))
	# Злобные горящие глаза
	_fill_rect(img, 17, 14, 4, 3, Color(1.0, 0.2, 0.1))
	_fill_rect(img, 27, 14, 4, 3, Color(1.0, 0.2, 0.1))
	# Боевой раскрас
	_fill_rect(img, 18, 18, 12, 2, Color(0.85, 0.1, 0.1))
	# Массивный торс в доспехе
	_fill_rect(img, 14, 28, 20, 14, Color(0.45, 0.35, 0.25))

static func _draw_boss_troll(img: Image) -> void:
	_fill_rect(img, 10, 8, 28, 26, Color(0.42, 0.4, 0.38))
	_draw_box(img, 9, 7, 30, 28, C_DARK_OUTLINE)
	_fill_rect(img, 16, 15, 4, 4, Color(1.0, 0.55, 0.1))
	_fill_rect(img, 28, 15, 4, 4, Color(1.0, 0.55, 0.1))
	# Моховая борода
	_fill_rect(img, 16, 24, 16, 6, Color(0.25, 0.38, 0.2))

static func _draw_boss_skeleton(img: Image) -> void:
	_fill_rect(img, 14, 8, 20, 18, Color(0.9, 0.92, 0.95))
	_draw_box(img, 13, 7, 22, 20, C_DARK_OUTLINE)
	# Золотая корона лорда
	_fill_rect(img, 16, 4, 16, 4, Color(0.9, 0.75, 0.2))
	# Глазницы с проклятым огнем
	_fill_rect(img, 17, 14, 4, 4, Color(0.1, 0.1, 0.2))
	_fill_rect(img, 27, 14, 4, 4, Color(0.1, 0.1, 0.2))
	_set_p(img, 18, 15, Color(0.2, 0.7, 1.0))
	_set_p(img, 28, 15, Color(0.2, 0.7, 1.0))
	# Черные латы
	_fill_rect(img, 14, 26, 20, 16, Color(0.2, 0.22, 0.26))

static func _draw_boss_lich(img: Image) -> void:
	_fill_rect(img, 14, 8, 20, 20, Color(0.25, 0.45, 0.7))
	_draw_box(img, 13, 7, 22, 22, Color(0.6, 0.85, 1.0))
	_fill_rect(img, 18, 14, 3, 3, Color(0.3, 0.9, 1.0))
	_fill_rect(img, 27, 14, 3, 3, Color(0.3, 0.9, 1.0))
	# Ледяные крылья
	_fill_rect(img, 4, 12, 10, 18, Color(0.4, 0.7, 0.95, 0.8))
	_fill_rect(img, 34, 12, 10, 18, Color(0.4, 0.7, 0.95, 0.8))

static func _draw_boss_dragon(img: Image) -> void:
	_fill_rect(img, 12, 10, 24, 22, Color(0.85, 0.25, 0.1))
	_draw_box(img, 11, 9, 26, 24, Color(0.4, 0.08, 0.05))
	# Рога дракона
	_fill_rect(img, 10, 3, 4, 8, Color(0.2, 0.2, 0.2))
	_fill_rect(img, 34, 3, 4, 8, Color(0.2, 0.2, 0.2))
	# Горящие желтые глаза дракона
	_fill_rect(img, 16, 17, 4, 3, Color(1.0, 0.9, 0.1))
	_fill_rect(img, 28, 17, 4, 3, Color(1.0, 0.9, 0.1))
	# Распахнутые крылья
	_fill_rect(img, 2, 14, 10, 16, Color(0.65, 0.15, 0.08))
	_fill_rect(img, 36, 14, 10, 16, Color(0.65, 0.15, 0.08))

static func _draw_boss_purgatory(img: Image) -> void:
	_fill_rect(img, 12, 8, 24, 24, Color(0.18, 0.12, 0.3))
	_draw_box(img, 11, 7, 26, 26, Color(0.7, 0.4, 1.0))
	# Корона владыки
	_fill_rect(img, 16, 2, 16, 6, Color(0.85, 0.7, 0.3))
	# Разделенные глаза: огонь и лед
	_fill_rect(img, 16, 15, 4, 4, Color(1.0, 0.4, 0.1)) # Глаз огня
	_fill_rect(img, 28, 15, 4, 4, Color(0.2, 0.8, 1.0)) # Глаз льда
	# Астральные крылья пустоты
	_fill_rect(img, 2, 10, 10, 22, Color(0.4, 0.15, 0.55))
	_fill_rect(img, 36, 10, 10, 22, Color(0.4, 0.15, 0.55))

