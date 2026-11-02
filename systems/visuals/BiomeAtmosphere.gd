class_name BiomeAtmosphere
extends Node2D

## Атмосферные частицы и динамическая среда для каждого биома

@onready var particles: CPUParticles2D = null

var current_biome: String = ""

func _ready() -> void:
	z_index = 5 # Поверх пола и окружения, под HUD

func setup_biome(biome_id: String) -> void:
	current_biome = biome_id
	_create_particles()

func _create_particles() -> void:
	if particles != null:
		particles.queue_free()
	
	particles = CPUParticles2D.new()
	particles.name = "AmbientParticles"
	particles.position = Vector2(640, 360) # Центр комнаты
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(620, 340)
	particles.z_index = 5
	
	# Мягкая радиальная текстура частицы
	particles.texture = EffectsHelper.get_spark_texture()
	
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0))
	grad.add_point(0.2, Color(1, 1, 1, 0.8))
	grad.add_point(0.8, Color(1, 1, 1, 0.8))
	grad.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = grad
	
	match current_biome:
		"hub":
			# Теплые золотистые пылинки в лучах факелов
			particles.amount = 35
			particles.lifetime = 4.5
			particles.direction = Vector2(0.3, -1.0).normalized()
			particles.spread = 40.0
			particles.gravity = Vector2(0, -6.0)
			particles.initial_velocity_min = 8.0
			particles.initial_velocity_max = 22.0
			particles.scale_amount_min = 1.0
			particles.scale_amount_max = 2.5
			particles.color = Color(1.0, 0.85, 0.45, 0.5)
			
		"goblin_dungeon", "dungeon":
			# Зеленые биолюминесцентные споры мха и подземелья
			particles.amount = 45
			particles.lifetime = 4.0
			particles.direction = Vector2(0.2, -1.0).normalized()
			particles.spread = 60.0
			particles.gravity = Vector2(0, -8.0)
			particles.initial_velocity_min = 10.0
			particles.initial_velocity_max = 26.0
			particles.scale_amount_min = 1.2
			particles.scale_amount_max = 2.8
			particles.color = Color(0.4, 1.2, 0.6, 0.6)
			
		"troll_gorge", "gorge":
			# Лесной бриз, опадающие листья и пыль ущелья
			particles.amount = 40
			particles.lifetime = 5.0
			particles.direction = Vector2(1.0, 0.4).normalized()
			particles.spread = 25.0
			particles.gravity = Vector2(15.0, 8.0)
			particles.initial_velocity_min = 25.0
			particles.initial_velocity_max = 55.0
			particles.scale_amount_min = 1.4
			particles.scale_amount_max = 3.2
			particles.color = Color(0.9, 0.7, 0.3, 0.55)
			
		"skeleton_castle", "castle":
			# Призрачные синие огоньки душ и могильный туман
			particles.amount = 50
			particles.lifetime = 4.0
			particles.direction = Vector2(-0.2, -1.0).normalized()
			particles.spread = 45.0
			particles.gravity = Vector2(0, -12.0)
			particles.initial_velocity_min = 12.0
			particles.initial_velocity_max = 32.0
			particles.scale_amount_min = 1.2
			particles.scale_amount_max = 3.0
			particles.color = Color(0.3, 0.8, 1.4, 0.65)
			
		"frost_world", "caves":
			# Мягкие падающие снежинки и морозная взвесь
			particles.amount = 65
			particles.lifetime = 5.5
			particles.direction = Vector2(-0.4, 1.0).normalized()
			particles.spread = 30.0
			particles.gravity = Vector2(-8.0, 20.0)
			particles.initial_velocity_min = 20.0
			particles.initial_velocity_max = 45.0
			particles.scale_amount_min = 1.0
			particles.scale_amount_max = 2.8
			particles.color = Color(0.85, 0.95, 1.2, 0.7)
			
		"fire_world", "mines":
			# Восходящие раскаленные вулканические искры и пепел
			particles.amount = 60
			particles.lifetime = 3.5
			particles.direction = Vector2(0.1, -1.0).normalized()
			particles.spread = 35.0
			particles.gravity = Vector2(0, -25.0)
			particles.initial_velocity_min = 30.0
			particles.initial_velocity_max = 75.0
			particles.scale_amount_min = 1.2
			particles.scale_amount_max = 3.2
			particles.color = Color(1.8, 0.7, 0.2, 0.75)
			
		"purgatory":
			# Темные вихри бездны и аметистовая астральная пыль
			particles.amount = 55
			particles.lifetime = 4.2
			particles.direction = Vector2(0.0, -1.0).normalized()
			particles.spread = 180.0
			particles.gravity = Vector2(0, -5.0)
			particles.initial_velocity_min = 15.0
			particles.initial_velocity_max = 40.0
			particles.scale_amount_min = 1.4
			particles.scale_amount_max = 3.5
			particles.color = Color(1.2, 0.4, 1.6, 0.65)
			
		_:
			particles.amount = 30
			particles.lifetime = 4.0
			particles.direction = Vector2(0, -1)
			particles.spread = 45.0
			particles.gravity = Vector2(0, -8.0)
			particles.color = Color(0.8, 0.8, 0.8, 0.4)
			
	add_child(particles)

