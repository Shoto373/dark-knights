class_name SvgGenerator
extends SceneTree

## Генератор векторных SVG-ассетов для всех персонажей, врагов и боссов

func _init() -> void:
	generate_all_svgs()
	quit()

static func generate_all_svgs() -> void:
	var dir_access: DirAccess = DirAccess.open("res://")
	if not dir_access.dir_exists("res://assets/sprites"):
		dir_access.make_dir_recursive("res://assets/sprites")
	
	var svgs: Dictionary = _get_svg_definitions()
	for file_name in svgs.keys():
		var path: String = "res://assets/sprites/" + file_name
		var content: String = svgs[file_name]
		if file_name.begins_with("boss_"):
			content = content.replace('width="96" height="96"', 'width="48" height="48"')
		elif file_name.begins_with("icon_"):
			content = content.replace('width="64" height="64"', 'width="40" height="40"')
		elif file_name.begins_with("hero_") or file_name.begins_with("enemy_"):
			content = content.replace('width="64" height="64"', 'width="32" height="32"')
		
		var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(content)
			f.close()

static func _get_svg_definitions() -> Dictionary:
	var d: Dictionary = {}
	
	# =====================
	# ГЕРОИ И ИКОНКИ
	# =====================
	d["hero_warrior.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 18 24 C 14 36, 12 50, 16 58 C 22 60, 42 60, 48 58 C 52 50, 50 36, 46 24 Z" fill="#1e3c72" stroke="#0b1320" stroke-width="2"/>
  <rect x="22" y="44" width="8" height="15" rx="3" fill="#2c3e50" stroke="#17202a" stroke-width="2"/>
  <rect x="34" y="44" width="8" height="15" rx="3" fill="#2c3e50" stroke="#17202a" stroke-width="2"/>
  <path d="M 20 25 L 44 25 L 41 44 L 23 44 Z" fill="#95a5a6" stroke="#1a252f" stroke-width="2"/>
  <rect x="30" y="28" width="4" height="12" fill="#f1c40f"/>
  <rect x="26" y="32" width="12" height="4" fill="#f1c40f"/>
  <circle cx="18" cy="27" r="6" fill="#bdc3c7" stroke="#b7950b" stroke-width="1.5"/>
  <circle cx="46" cy="27" r="6" fill="#bdc3c7" stroke="#b7950b" stroke-width="1.5"/>
  <path d="M 23 10 C 23 5, 41 5, 41 10 L 43 23 L 21 23 Z" fill="#bdc3c7" stroke="#1a252f" stroke-width="2"/>
  <path d="M 28 8 L 32 3 L 36 8 L 32 6 Z" fill="#f1c40f"/>
  <path d="M 25 15 L 39 15 L 34 18 L 30 18 Z" fill="#111118"/>
  <rect x="30.5" y="15" width="3" height="8" fill="#111118"/>
  <ellipse cx="28" cy="16" rx="2" ry="1.2" fill="#00ffff"/>
  <ellipse cx="36" cy="16" rx="2" ry="1.2" fill="#00ffff"/>
  <line x1="50" y1="18" x2="57" y2="46" stroke="#ecf0f1" stroke-width="3" stroke-linecap="round"/>
  <line x1="47" y1="26" x2="57" y2="23" stroke="#f1c40f" stroke-width="3" stroke-linecap="round"/>
</svg>"""

	d["hero_mage.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 24 22 L 40 22 L 46 58 L 18 58 Z" fill="#3b0764" stroke="#090114" stroke-width="2"/>
  <path d="M 31 24 L 31 58" stroke="#f59e0b" stroke-width="2" stroke-dasharray="3,2"/>
  <path d="M 32 4 C 20 8, 18 20, 20 25 C 26 26, 38 26, 44 25 C 46 20, 44 8, 32 4 Z" fill="#2c0b4d" stroke="#090114" stroke-width="2"/>
  <path d="M 23 14 C 23 11, 41 11, 41 14 C 42 22, 22 22, 23 14 Z" fill="#08020f"/>
  <circle cx="28" cy="17" r="2.2" fill="#38bdf8"/>
  <circle cx="36" cy="17" r="2.2" fill="#38bdf8"/>
  <circle cx="28" cy="17" r="1" fill="#ffffff"/>
  <circle cx="36" cy="17" r="1" fill="#ffffff"/>
  <line x1="50" y1="12" x2="52" y2="56" stroke="#5c2e14" stroke-width="3" stroke-linecap="round"/>
  <circle cx="51" cy="7" r="5" fill="#a855f7"/>
  <ellipse cx="51" cy="7" rx="7" ry="2" fill="none" stroke="#67e8f9" stroke-width="1.2"/>
</svg>"""

	d["hero_ranger.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 20 22 C 16 34, 14 46, 18 56 C 24 58, 40 58, 46 56 C 50 46, 48 34, 44 22 Z" fill="#1e3a1e" stroke="#0b1b09" stroke-width="2"/>
  <rect x="24" y="24" width="16" height="18" rx="3" fill="#8b5a2b" stroke="#2b1a0a" stroke-width="1.5"/>
  <line x1="24" y1="26" x2="38" y2="40" stroke="#4a2e12" stroke-width="2"/>
  <circle cx="31" cy="33" r="2.5" fill="#f1c40f"/>
  <rect x="25" y="42" width="5" height="16" rx="2" fill="#3d2b1f"/>
  <rect x="34" y="42" width="5" height="16" rx="2" fill="#3d2b1f"/>
  <path d="M 32 5 C 22 7, 20 18, 22 23 C 27 24, 37 24, 42 23 C 44 18, 42 7, 32 5 Z" fill="#2d5a27" stroke="#0e230b" stroke-width="2"/>
  <rect x="25" y="16" width="14" height="6" rx="2" fill="#4a2e12"/>
  <ellipse cx="28" cy="14" rx="2" ry="1.2" fill="#fbbf24"/>
  <ellipse cx="36" cy="14" rx="2" ry="1.2" fill="#fbbf24"/>
  <path d="M 12 12 Q 8 30 12 48" stroke="#8b5a2b" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  <line x1="12" y1="12" x2="12" y2="48" stroke="#f8fafc" stroke-width="1.2"/>
</svg>"""

	d["icon_warrior.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="2" y="2" width="60" height="60" rx="10" fill="#0f172a" stroke="#eab308" stroke-width="4"/>
  <circle cx="32" cy="32" r="24" fill="#1e293b"/>
  <path d="M 22 18 C 22 10, 42 10, 42 18 L 44 38 L 20 38 Z" fill="#94a3b8" stroke="#334155" stroke-width="2"/>
  <path d="M 28 14 L 32 8 L 36 14 Z" fill="#eab308"/>
  <path d="M 24 25 L 40 25 L 34 29 L 30 29 Z" fill="#090d16"/>
  <rect x="30" y="25" width="4" height="12" fill="#090d16"/>
  <ellipse cx="27" cy="27" rx="2" ry="1.2" fill="#38bdf8"/>
  <ellipse cx="37" cy="27" rx="2" ry="1.2" fill="#38bdf8"/>
  <path d="M 16 46 L 48 46 L 44 54 L 20 54 Z" fill="#475569" stroke="#1e293b" stroke-width="2"/>
</svg>"""

	d["icon_mage.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="2" y="2" width="60" height="60" rx="10" fill="#18042b" stroke="#eab308" stroke-width="4"/>
  <circle cx="32" cy="32" r="24" fill="#2e1065"/>
  <path d="M 32 8 C 18 13, 16 26, 18 34 C 24 36, 40 36, 46 34 C 48 26, 46 13, 32 8 Z" fill="#581c87" stroke="#1e0538" stroke-width="2"/>
  <path d="M 22 22 C 22 17, 42 17, 42 22 C 43 32, 21 32, 22 22 Z" fill="#090212"/>
  <circle cx="27" cy="25" r="2.5" fill="#38bdf8"/>
  <circle cx="37" cy="25" r="2.5" fill="#38bdf8"/>
  <path d="M 16 46 L 48 46 L 44 54 L 20 54 Z" fill="#3b0764"/>
</svg>"""

	d["icon_ranger.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="2" y="2" width="60" height="60" rx="10" fill="#05200e" stroke="#eab308" stroke-width="4"/>
  <circle cx="32" cy="32" r="24" fill="#0f3d1b"/>
  <path d="M 32 9 C 20 12, 18 24, 20 32 C 26 34, 38 34, 44 32 C 46 24, 44 12, 32 9 Z" fill="#15803d" stroke="#052e10" stroke-width="2"/>
  <rect x="23" y="23" width="18" height="9" rx="2" fill="#78350f"/>
  <ellipse cx="27" cy="20" rx="2.5" ry="1.5" fill="#fbbf24"/>
  <ellipse cx="37" cy="20" rx="2.5" ry="1.5" fill="#fbbf24"/>
  <path d="M 16 46 L 48 46 L 44 54 L 20 54 Z" fill="#365314"/>
</svg>"""

	# =====================
	# ГОБЛИНЫ
	# =====================
	d["enemy_goblin_slasher.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="22" rx="14" ry="12" fill="#4d7c0f" stroke="#1a2e05" stroke-width="2"/>
  <polygon points="18,20 4,14 16,26" fill="#4d7c0f" stroke="#1a2e05" stroke-width="2"/>
  <polygon points="46,20 60,14 48,26" fill="#4d7c0f" stroke="#1a2e05" stroke-width="2"/>
  <circle cx="26" cy="20" r="3" fill="#dc2626"/>
  <circle cx="38" cy="20" r="3" fill="#dc2626"/>
  <polygon points="28,27 30,30 32,27" fill="#fff"/>
  <polygon points="34,27 36,30 38,27" fill="#fff"/>
  <rect x="22" y="34" width="20" height="18" rx="4" fill="#78350f" stroke="#291103" stroke-width="2"/>
  <path d="M 48 24 L 56 16 L 62 22 L 54 40 L 46 36 Z" fill="#94a3b8" stroke="#334155" stroke-width="2"/>
  <rect x="44" y="36" width="4" height="10" fill="#451a03"/>
</svg>"""

	d["enemy_goblin_archer.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="22" rx="13" ry="11" fill="#65a30d" stroke="#1a2e05" stroke-width="2"/>
  <polygon points="19,20 6,15 17,25" fill="#65a30d" stroke="#1a2e05" stroke-width="2"/>
  <polygon points="45,20 58,15 47,25" fill="#65a30d" stroke="#1a2e05" stroke-width="2"/>
  <path d="M 20 18 Q 32 8 44 18 Z" fill="#713f12" stroke="#2e1005" stroke-width="1.5"/>
  <circle cx="27" cy="21" r="2.5" fill="#ef4444"/>
  <circle cx="37" cy="21" r="2.5" fill="#ef4444"/>
  <rect x="23" y="33" width="18" height="17" rx="3" fill="#3f6212" stroke="#1a2e05" stroke-width="2"/>
  <path d="M 12 16 Q 6 32 12 50" stroke="#78350f" stroke-width="3" fill="none" stroke-linecap="round"/>
  <line x1="12" y1="16" x2="12" y2="50" stroke="#f1f5f9" stroke-width="1"/>
</svg>"""

	d["enemy_goblin_shaman.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="25" rx="14" ry="12" fill="#4d7c0f" stroke="#1a2e05" stroke-width="2"/>
  <polygon points="18,22 5,16 17,28" fill="#4d7c0f"/>
  <polygon points="46,22 59,16 47,28" fill="#4d7c0f"/>
  <path d="M 22 18 C 22 8, 42 8, 42 18 L 40 24 L 24 24 Z" fill="#fef08a" stroke="#713f12" stroke-width="2"/>
  <circle cx="28" cy="18" r="3" fill="#1e1e1e"/><circle cx="36" cy="18" r="3" fill="#1e1e1e"/>
  <path d="M 22 36 L 42 36 L 46 58 L 18 58 Z" fill="#7c2d12" stroke="#2e1005" stroke-width="2"/>
  <line x1="52" y1="14" x2="52" y2="58" stroke="#fef08a" stroke-width="3.5"/>
  <circle cx="52" cy="12" r="5" fill="#f97316"/>
</svg>"""

	d["enemy_goblin_brute.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="36" rx="22" ry="14" fill="#365314" stroke="#142605" stroke-width="2"/>
  <ellipse cx="32" cy="20" rx="15" ry="13" fill="#3f6212" stroke="#142605" stroke-width="2"/>
  <polygon points="17,18 2,12 15,24" fill="#3f6212"/>
  <polygon points="47,18 62,12 49,24" fill="#3f6212"/>
  <circle cx="26" cy="22" r="3.5" fill="#ef4444"/>
  <circle cx="38" cy="22" r="3.5" fill="#ef4444"/>
  <polygon points="26,30 28,24 30,30" fill="#fff"/>
  <polygon points="34,30 36,24 38,30" fill="#fff"/>
  <rect x="48" y="10" width="10" height="34" rx="4" fill="#5c3818" stroke="#291103" stroke-width="2"/>
  <circle cx="49" cy="16" r="2" fill="#cbd5e1"/>
  <circle cx="57" cy="22" r="2" fill="#cbd5e1"/>
</svg>"""

	# =====================
	# ТРОЛЛИ
	# =====================
	d["enemy_troll_brute.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="34" rx="20" ry="16" fill="#475569" stroke="#1e293b" stroke-width="2"/>
  <ellipse cx="32" cy="20" rx="16" ry="13" fill="#64748b" stroke="#1e293b" stroke-width="2"/>
  <circle cx="26" cy="18" r="3.5" fill="#f97316"/>
  <circle cx="38" cy="18" r="3.5" fill="#f97316"/>
  <circle cx="52" cy="22" r="9" fill="#334155" stroke="#0f172a" stroke-width="2"/>
  <line x1="52" y1="31" x2="48" y2="54" stroke="#713f12" stroke-width="4"/>
</svg>"""

	d["enemy_stone_thrower.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="30" cy="36" rx="18" ry="14" fill="#475569" stroke="#1e293b" stroke-width="2"/>
  <ellipse cx="28" cy="22" rx="14" ry="12" fill="#64748b" stroke="#1e293b" stroke-width="2"/>
  <circle cx="24" cy="20" r="3" fill="#ea580c"/>
  <circle cx="34" cy="20" r="3" fill="#ea580c"/>
  <path d="M 40 8 C 44 4, 56 4, 60 10 C 64 16, 62 26, 56 30 C 48 32, 40 28, 38 20 Z" fill="#78716c" stroke="#292524" stroke-width="2"/>
</svg>"""

	d["enemy_troll_regenerator.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="34" rx="20" ry="16" fill="#334155" stroke="#0f172a" stroke-width="2"/>
  <ellipse cx="32" cy="20" rx="16" ry="13" fill="#475569" stroke="#0f172a" stroke-width="2"/>
  <circle cx="26" cy="18" r="3.5" fill="#22c55e"/>
  <circle cx="38" cy="18" r="3.5" fill="#22c55e"/>
  <path d="M 28 26 Q 32 34 26 44" stroke="#22c55e" stroke-width="3" fill="none"/>
  <path d="M 36 26 Q 32 34 38 44" stroke="#22c55e" stroke-width="3" fill="none"/>
</svg>"""

	# =====================
	# СКЕЛЕТЫ
	# =====================
	d["enemy_skeleton_swordsman.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 22 14 C 22 6, 42 6, 42 14 C 44 22, 38 28, 32 28 C 26 28, 20 22, 22 14 Z" fill="#e2e8f0" stroke="#475569" stroke-width="2"/>
  <circle cx="27" cy="16" r="3" fill="#0f172a"/><circle cx="27" cy="16" r="1.5" fill="#38bdf8"/>
  <circle cx="37" cy="16" r="3" fill="#0f172a"/><circle cx="37" cy="16" r="1.5" fill="#38bdf8"/>
  <line x1="32" y1="32" x2="32" y2="48" stroke="#94a3b8" stroke-width="3"/>
  <path d="M 24 36 Q 32 34 40 36 M 23 41 Q 32 39 41 41" stroke="#e2e8f0" stroke-width="2.5" fill="none"/>
  <line x1="50" y1="18" x2="54" y2="52" stroke="#cbd5e1" stroke-width="3"/>
  <circle cx="16" cy="40" r="9" fill="#64748b" stroke="#e2e8f0" stroke-width="2"/>
</svg>"""

	d["enemy_skeleton_crossbowman.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 24 16 C 24 8, 40 8, 40 16 C 42 24, 38 28, 32 28 C 26 28, 22 24, 24 16 Z" fill="#e2e8f0" stroke="#475569" stroke-width="2"/>
  <path d="M 18 16 C 18 6, 46 6, 46 16 L 44 26 L 20 26 Z" fill="#334155" opacity="0.85"/>
  <circle cx="28" cy="18" r="3" fill="#0f172a"/><circle cx="28" cy="18" r="1.5" fill="#f87171"/>
  <circle cx="36" cy="18" r="3" fill="#0f172a"/><circle cx="36" cy="18" r="1.5" fill="#f87171"/>
  <rect x="28" y="38" width="8" height="18" rx="2" fill="#78350f"/>
  <path d="M 16 42 Q 32 46 48 42" stroke="#64748b" stroke-width="3" fill="none"/>
</svg>"""

	d["enemy_necromancer_acolyte.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 20 22 L 44 22 L 48 58 L 16 58 Z" fill="#1e1b4b" stroke="#0f0e26" stroke-width="2"/>
  <path d="M 32 6 C 20 9, 18 20, 20 26 C 26 27, 38 27, 44 26 C 46 20, 44 9, 32 6 Z" fill="#312e81"/>
  <ellipse cx="32" cy="18" rx="9" ry="7" fill="#090821"/>
  <circle cx="28" cy="17" r="2.5" fill="#c084fc"/>
  <circle cx="36" cy="17" r="2.5" fill="#c084fc"/>
  <circle cx="50" cy="30" r="6" fill="#7e22ce"/>
</svg>"""

	d["enemy_knight_guard.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 22 10 C 22 4, 42 4, 42 10 L 44 24 L 20 24 Z" fill="#1e293b" stroke="#0f172a" stroke-width="2"/>
  <line x1="24" y1="16" x2="40" y2="16" stroke="#f87171" stroke-width="2"/>
  <path d="M 8 16 L 30 16 L 28 56 L 19 60 L 10 56 Z" fill="#334155" stroke="#e2e8f0" stroke-width="2.5"/>
  <line x1="19" y1="22" x2="19" y2="50" stroke="#fbbf24" stroke-width="3"/>
  <line x1="12" y1="32" x2="26" y2="32" stroke="#fbbf24" stroke-width="3"/>
</svg>"""

	# =====================
	# ХОЛОД
	# =====================
	d["enemy_ice_wraith.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 32 8 C 22 10, 18 20, 20 30 C 22 46, 16 54, 24 58 C 28 60, 36 60, 40 58 C 48 54, 42 46, 44 30 C 46 20, 42 10, 32 8 Z" fill="#38bdf8" opacity="0.85" stroke="#bae6fd" stroke-width="2"/>
  <circle cx="27" cy="22" r="3" fill="#ffffff"/>
  <circle cx="37" cy="22" r="3" fill="#ffffff"/>
</svg>"""

	d["enemy_frost_golem.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="18" y="24" width="28" height="26" rx="4" fill="#0284c7" stroke="#e0f2fe" stroke-width="2"/>
  <polygon points="24,8 40,8 44,22 20,22" fill="#0369a1" stroke="#e0f2fe" stroke-width="2"/>
  <circle cx="28" cy="15" r="3.5" fill="#f0f9ff"/>
  <circle cx="36" cy="15" r="3.5" fill="#f0f9ff"/>
</svg>"""

	d["enemy_lich_apprentice.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 22 22 L 42 22 L 46 58 L 18 58 Z" fill="#0369a1" stroke="#082f49" stroke-width="2"/>
  <path d="M 32 6 C 20 9, 18 20, 20 26 C 26 27, 38 27, 44 26 C 46 20, 44 9, 32 6 Z" fill="#0284c7"/>
  <circle cx="28" cy="18" r="2.5" fill="#67e8f9"/>
  <circle cx="36" cy="18" r="2.5" fill="#67e8f9"/>
</svg>"""

	d["enemy_ice_spider.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="32" rx="14" ry="12" fill="#0284c7" stroke="#bae6fd" stroke-width="2"/>
  <ellipse cx="32" cy="22" rx="9" ry="7" fill="#0369a1" stroke="#bae6fd" stroke-width="1.5"/>
  <circle cx="29" cy="21" r="1.5" fill="#38bdf8"/><circle cx="35" cy="21" r="1.5" fill="#38bdf8"/>
  <path d="M 20 26 L 8 16 M 20 32 L 6 32 M 20 38 L 8 48 M 44 26 L 56 16 M 44 32 L 58 32 M 44 38 L 56 48" stroke="#bae6fd" stroke-width="3" stroke-linecap="round"/>
</svg>"""

	# =====================
	# ОГОНЬ
	# =====================
	d["enemy_lava_slime.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 32 12 C 16 12, 10 32, 12 46 C 14 56, 50 56, 52 46 C 54 32, 48 12, 32 12 Z" fill="#ea580c" stroke="#7c2d12" stroke-width="2.5"/>
  <ellipse cx="32" cy="38" rx="12" ry="8" fill="#facc15"/>
  <circle cx="26" cy="30" r="3" fill="#ffffff"/>
  <circle cx="38" cy="30" r="3" fill="#ffffff"/>
</svg>"""

	d["enemy_fire_elemental.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 32 4 C 18 18, 16 36, 20 48 C 26 56, 38 56, 44 48 C 48 36, 46 18, 32 4 Z" fill="#f97316" stroke="#c2410c" stroke-width="2"/>
  <circle cx="28" cy="32" r="3" fill="#ef4444"/>
  <circle cx="36" cy="32" r="3" fill="#ef4444"/>
</svg>"""

	d["enemy_flame_cultist.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 22 22 L 42 22 L 46 58 L 18 58 Z" fill="#991b1b" stroke="#450a0a" stroke-width="2"/>
  <path d="M 32 6 C 20 9, 18 20, 20 26 C 26 27, 38 27, 44 26 C 46 20, 44 9, 32 6 Z" fill="#dc2626"/>
  <circle cx="28" cy="18" r="2.5" fill="#fbbf24"/>
  <circle cx="36" cy="18" r="2.5" fill="#fbbf24"/>
</svg>"""

	d["enemy_magma_worm.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="24" rx="16" ry="12" fill="#7c2d12" stroke="#ea580c" stroke-width="2"/>
  <ellipse cx="32" cy="38" rx="14" ry="9" fill="#451a03" stroke="#ea580c" stroke-width="2"/>
  <ellipse cx="32" cy="48" rx="10" ry="7" fill="#291103" stroke="#ea580c" stroke-width="2"/>
  <circle cx="26" cy="22" r="3" fill="#facc15"/>
  <circle cx="38" cy="22" r="3" fill="#facc15"/>
</svg>"""

	# =====================
	# ЧИСТИЛИЩЕ
	# =====================
	d["enemy_shadow_chimera.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <ellipse cx="32" cy="34" rx="18" ry="14" fill="#3b0764" stroke="#7e22ce" stroke-width="2"/>
  <ellipse cx="32" cy="20" rx="13" ry="10" fill="#581c87" stroke="#7e22ce" stroke-width="2"/>
  <polygon points="22,14 14,4 26,10" fill="#a855f7"/>
  <polygon points="42,14 50,4 38,10" fill="#a855f7"/>
  <circle cx="27" cy="19" r="3" fill="#4ade80"/>
  <circle cx="37" cy="19" r="3" fill="#4ade80"/>
</svg>"""

	d["enemy_fallen_archon.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 24 24 L 40 24 L 44 56 L 20 56 Z" fill="#78350f" stroke="#f59e0b" stroke-width="2"/>
  <path d="M 22 24 C 6 12, 4 36, 12 48 Z" fill="#1e1b4b"/>
  <path d="M 42 24 C 58 12, 60 36, 52 48 Z" fill="#1e1b4b"/>
  <circle cx="32" cy="16" r="8" fill="#fde047"/>
  <circle cx="29" cy="16" r="2" fill="#0f172a"/><circle cx="35" cy="16" r="2" fill="#0f172a"/>
  <circle cx="32" cy="8" r="6" fill="none" stroke="#7e22ce" stroke-width="2"/>
</svg>"""

	d["enemy_void_specter.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M 32 8 C 18 12, 14 26, 16 42 C 22 56, 42 56, 48 42 C 50 26, 46 12, 32 8 Z" fill="#090514" stroke="#a855f7" stroke-width="2"/>
  <circle cx="32" cy="24" r="7" fill="#c084fc"/>
  <circle cx="32" cy="24" r="3" fill="#ffffff"/>
</svg>"""

	d["enemy_purgatory_executioner.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="20" y="24" width="24" height="30" rx="4" fill="#18181b" stroke="#71717a" stroke-width="2"/>
  <path d="M 24 10 L 40 10 L 44 24 L 20 24 Z" fill="#09090b" stroke="#71717a" stroke-width="2"/>
  <circle cx="28" cy="18" r="2" fill="#ef4444"/><circle cx="36" cy="18" r="2" fill="#ef4444"/>
  <line x1="48" y1="8" x2="48" y2="56" stroke="#3f3f46" stroke-width="4"/>
</svg>"""

	# =====================
	# БОССЫ
	# =====================
	d["boss_goblin.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <ellipse cx="48" cy="54" rx="32" ry="24" fill="#365314" stroke="#142605" stroke-width="3"/>
  <ellipse cx="48" cy="34" rx="22" ry="18" fill="#4d7c0f" stroke="#142605" stroke-width="3"/>
  <polygon points="26,32 6,24 24,42" fill="#4d7c0f" stroke="#142605" stroke-width="2"/>
  <polygon points="70,32 90,24 72,42" fill="#4d7c0f" stroke="#142605" stroke-width="2"/>
  <path d="M 32 20 L 48 8 L 64 20 L 56 26 L 40 26 Z" fill="#fef08a" stroke="#713f12" stroke-width="2"/>
  <circle cx="39" cy="34" r="4.5" fill="#ef4444"/>
  <circle cx="57" cy="34" r="4.5" fill="#ef4444"/>
  <line x1="14" y1="28" x2="22" y2="70" stroke="#713f12" stroke-width="4"/>
  <line x1="82" y1="28" x2="74" y2="70" stroke="#713f12" stroke-width="4"/>
</svg>"""

	d["boss_troll.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <ellipse cx="48" cy="56" rx="36" ry="28" fill="#475569" stroke="#0f172a" stroke-width="3"/>
  <ellipse cx="48" cy="36" rx="26" ry="22" fill="#64748b" stroke="#0f172a" stroke-width="3"/>
  <polygon points="34,22 40,8 48,16 56,8 62,22" fill="#eab308" stroke="#713f12" stroke-width="2"/>
  <circle cx="38" cy="34" r="5" fill="#ea580c"/>
  <circle cx="58" cy="34" r="5" fill="#ea580c"/>
  <path d="M 34 46 C 34 62, 62 62, 62 46 Z" fill="#22c55e" stroke="#15803d" stroke-width="2"/>
  <circle cx="82" cy="32" r="13" fill="#334155" stroke="#0f172a" stroke-width="3"/>
  <line x1="82" y1="44" x2="74" y2="88" stroke="#78350f" stroke-width="6"/>
</svg>"""

	d["boss_skeleton.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <path d="M 22 36 C 14 56, 10 78, 18 90 C 28 94, 68 94, 78 90 C 86 78, 82 56, 74 36 Z" fill="#991b1b" stroke="#450a0a" stroke-width="3"/>
  <rect x="32" y="40" width="32" height="34" rx="6" fill="#1e293b" stroke="#0f172a" stroke-width="3"/>
  <polygon points="36,18 42,6 48,14 54,6 60,18" fill="#facc15" stroke="#854d0e" stroke-width="2"/>
  <circle cx="48" cy="28" r="14" fill="#e2e8f0" stroke="#334155" stroke-width="2"/>
  <circle cx="42" cy="28" r="4" fill="#090d16"/><circle cx="42" cy="28" r="1.5" fill="#38bdf8"/>
  <circle cx="54" cy="28" r="4" fill="#090d16"/><circle cx="54" cy="28" r="1.5" fill="#38bdf8"/>
  <line x1="76" y1="16" x2="84" y2="86" stroke="#93c5fd" stroke-width="5" stroke-linecap="round"/>
</svg>"""

	d["boss_lich.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <path d="M 32 36 C 8 20, 2 54, 16 70 Z" fill="#0284c7" opacity="0.8"/>
  <path d="M 64 36 C 88 20, 94 54, 80 70 Z" fill="#0284c7" opacity="0.8"/>
  <path d="M 32 34 L 64 34 L 70 88 L 26 88 Z" fill="#075985" stroke="#082f49" stroke-width="3"/>
  <polygon points="32,20 38,6 48,16 58,6 64,20" fill="#bae6fd" stroke="#0369a1" stroke-width="2"/>
  <circle cx="48" cy="28" r="13" fill="#0369a1"/>
  <circle cx="42" cy="28" r="3.5" fill="#e0f2fe"/>
  <circle cx="54" cy="28" r="3.5" fill="#e0f2fe"/>
</svg>"""

	d["boss_dragon.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <path d="M 36 40 C 10 16, 2 50, 14 74 C 24 58, 32 50, 36 48 Z" fill="#991b1b" stroke="#450a0a" stroke-width="2"/>
  <path d="M 60 40 C 86 16, 94 50, 82 74 C 72 58, 64 50, 60 48 Z" fill="#991b1b" stroke="#450a0a" stroke-width="2"/>
  <ellipse cx="48" cy="50" rx="20" ry="24" fill="#b91c1c" stroke="#450a0a" stroke-width="3"/>
  <path d="M 34 28 C 34 16, 62 16, 62 28 L 56 42 L 40 42 Z" fill="#dc2626" stroke="#450a0a" stroke-width="2.5"/>
  <path d="M 36 20 C 30 10, 22 8, 20 12 C 22 18, 30 22, 36 24 Z" fill="#18181b"/>
  <path d="M 60 20 C 66 10, 74 8, 76 12 C 74 18, 66 22, 60 24 Z" fill="#18181b"/>
  <ellipse cx="40" cy="28" rx="4" ry="2.5" fill="#facc15"/>
  <ellipse cx="56" cy="28" rx="4" ry="2.5" fill="#facc15"/>
</svg>"""

	d["boss_purgatory.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <path d="M 34 36 C 8 16, 4 56, 16 78 Z" fill="#2e1065" stroke="#7e22ce" stroke-width="2"/>
  <path d="M 62 36 C 88 16, 92 56, 80 78 Z" fill="#2e1065" stroke="#7e22ce" stroke-width="2"/>
  <path d="M 30 36 L 66 36 L 72 88 L 24 88 Z" fill="#18042b" stroke="#a855f7" stroke-width="3"/>
  <polygon points="32,18 40,4 48,14 56,4 64,18" fill="#facc15" stroke="#7e22ce" stroke-width="2"/>
  <circle cx="48" cy="28" r="14" fill="#090117" stroke="#c084fc" stroke-width="2"/>
  <circle cx="41" cy="28" r="4.5" fill="#f97316"/>
  <circle cx="55" cy="28" r="4.5" fill="#38bdf8"/>
</svg>"""

	# =====================
	# ОРУЖИЕ
	# =====================
	d["weapon_sword.svg"] = FileAccess.get_file_as_string("res://assets/sprites/weapon_sword.svg")
	d["weapon_staff.svg"] = FileAccess.get_file_as_string("res://assets/sprites/weapon_staff.svg")
	d["weapon_bow.svg"] = FileAccess.get_file_as_string("res://assets/sprites/weapon_bow.svg")

	# =====================
	# СНАРЯДЫ
	# =====================
	d["projectile_arrow.svg"] = FileAccess.get_file_as_string("res://assets/sprites/projectile_arrow.svg")
	d["projectile_magic_bolt.svg"] = FileAccess.get_file_as_string("res://assets/sprites/projectile_magic_bolt.svg")
	d["projectile_fireball.svg"] = FileAccess.get_file_as_string("res://assets/sprites/projectile_fireball.svg")
	d["projectile_frost_shard.svg"] = FileAccess.get_file_as_string("res://assets/sprites/projectile_frost_shard.svg")

	# =====================
	# ДЕКОРАЦИИ И ОКРУЖЕНИЕ
	# =====================
	d["portal_rift.svg"] = FileAccess.get_file_as_string("res://assets/sprites/portal_rift.svg")
	d["wall_torch.svg"] = FileAccess.get_file_as_string("res://assets/sprites/wall_torch.svg")
	d["torch_flame.svg"] = FileAccess.get_file_as_string("res://assets/sprites/torch_flame.svg")
	d["light_halo.svg"] = FileAccess.get_file_as_string("res://assets/sprites/light_halo.svg")
	d["target_dummy.svg"] = FileAccess.get_file_as_string("res://assets/sprites/target_dummy.svg")
	d["trap_spikes_retracted.svg"] = FileAccess.get_file_as_string("res://assets/sprites/trap_spikes_retracted.svg")
	d["trap_spikes_extended.svg"] = FileAccess.get_file_as_string("res://assets/sprites/trap_spikes_extended.svg")
	d["pillar_corner.svg"] = FileAccess.get_file_as_string("res://assets/sprites/pillar_corner.svg")
	d["dungeon_stone_tile.svg"] = FileAccess.get_file_as_string("res://assets/sprites/dungeon_stone_tile.svg")
	d["dungeon_wall_brick.svg"] = FileAccess.get_file_as_string("res://assets/sprites/dungeon_wall_brick.svg")
	d["dungeon_floor_crest.svg"] = FileAccess.get_file_as_string("res://assets/sprites/dungeon_floor_crest.svg")

	# =====================
	# ИКОНКИ И ЭЛЕМЕНТЫ HUD
	# =====================
	d["hud_health_flask.svg"] = FileAccess.get_file_as_string("res://assets/sprites/hud_health_flask.svg")
	d["hud_hero_badge.svg"] = FileAccess.get_file_as_string("res://assets/sprites/hud_hero_badge.svg")
	d["hud_icon_gold.svg"] = FileAccess.get_file_as_string("res://assets/sprites/hud_icon_gold.svg")
	d["hud_icon_key.svg"] = FileAccess.get_file_as_string("res://assets/sprites/hud_icon_key.svg")
	d["hud_icon_soul.svg"] = FileAccess.get_file_as_string("res://assets/sprites/hud_icon_soul.svg")
	d["hud_boss_crest.svg"] = FileAccess.get_file_as_string("res://assets/sprites/hud_boss_crest.svg")

	return d
