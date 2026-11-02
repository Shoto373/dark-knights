extends GutTest

## Тестирование шейдеров Vulkan Forward+, материалов и пост-обработки

func test_all_vulkan_shaders_load_and_compile() -> void:
	var shader_paths: Array[String] = [
		"res://shaders/magma_flow.gdshader",
		"res://shaders/shockwave.gdshader",
		"res://shaders/cinematic_atmosphere.gdshader",
		"res://shaders/dissolve_burn.gdshader",
		"res://shaders/heat_haze.gdshader",
		"res://shaders/hit_flash.gdshader"
	]
	
	for path in shader_paths:
		var shader: Shader = load(path) as Shader
		assert_not_null(shader, "Шейдер %s должен корректно загружаться" % path)
		if shader != null:
			var mat: ShaderMaterial = ShaderMaterial.new()
			mat.shader = shader
			assert_not_null(mat.shader, "ShaderMaterial должен успешно компилировать шейдер %s" % path)

func test_light_texture_generator_creates_valid_texture() -> void:
	var tex: Texture2D = LightTextureGenerator.get_radial_light_texture()
	assert_not_null(tex, "LightTextureGenerator должен генерировать текстуру света")
	assert_gt(tex.get_width(), 0, "Ширина текстуры света > 0")
	
	var light: PointLight2D = LightTextureGenerator.create_point_light(Color(1.0, 0.5, 0.2), 1.0, 2.0)
	assert_not_null(light, "create_point_light должен возвращать PointLight2D")
	assert_eq(light.blend_mode, PointLight2D.BLEND_MODE_ADD)
	light.free()

func test_dungeon_environment_configuration() -> void:
	var env_node: DungeonEnvironment = DungeonEnvironment.new()
	add_child_autofree(env_node)
	assert_not_null(env_node.environment, "Environment должен быть создан")
	assert_true(env_node.environment.glow_enabled, "Glow должен быть включен по умолчанию для Vulkan Forward+")
	assert_eq(env_node.environment.tonemap_mode, Environment.TONE_MAPPER_ACES, "Должен использоваться ACES тонемаппинг")

func test_post_process_layer_instantiation_and_biomes() -> void:
	var pp_scene: PackedScene = load("res://ui/PostProcessLayer.tscn")
	assert_not_null(pp_scene, "PostProcessLayer.tscn должен существовать")
	var pp = pp_scene.instantiate()
	add_child_autofree(pp)
	assert_not_null(pp, "PostProcessLayer должен инстанцироваться")
	
	pp.setup_biome("fire_world")
	var mat: ShaderMaterial = pp.color_rect.material as ShaderMaterial
	assert_not_null(mat, "ShaderMaterial должен быть назначен на ColorRect")
	var tint: Color = mat.get_shader_parameter("biome_tint")
	assert_gt(tint.r, 1.0, "Огненный биом имеет теплый оттенок")

func test_effects_helper_shockwave_and_dissolve() -> void:
	var root: Node2D = Node2D.new()
	add_child_autofree(root)
	
	EffectsHelper.spawn_shockwave(root, Vector2(100, 100), 120.0, 0.2, 0.04)
	assert_gt(root.get_child_count(), 0, "Ударная волна должна спавнить BackBufferCopy")
	
	var dummy_sprite: Sprite2D = Sprite2D.new()
	root.add_child(dummy_sprite)
	var tween: Tween = EffectsHelper.apply_burn_dissolve(dummy_sprite, 0.3)
	assert_not_null(tween, "Растворение должно создавать Tween")
	assert_true(dummy_sprite.material is ShaderMaterial, "Спрайт должен получить ShaderMaterial растворения")
