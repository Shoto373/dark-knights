class_name LightTextureGenerator
extends RefCounted

## Процедурный генератор высококачественных текстур для PointLight2D (Godot 4 Forward+ Vulkan)

static var _cached_radial_texture: Texture2D = null

static func get_radial_light_texture(size: int = 128) -> Texture2D:
	if _cached_radial_texture != null:
		return _cached_radial_texture
	
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: float = (size - 1) * 0.5
	var max_radius: float = center
	
	for y in range(size):
		for x in range(size):
			var dist: float = Vector2(x - center, y - center).length()
			if dist >= max_radius:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
			else:
				var t: float = 1.0 - (dist / max_radius)
				# Кубическое сглаживание: очень мягкий спад освещенности без артефактов
				var alpha: float = t * t * (3.0 - 2.0 * t) * (t * 0.9 + 0.1)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	
	_cached_radial_texture = ImageTexture.create_from_image(img)
	return _cached_radial_texture

static func create_point_light(color: Color = Color(1.0, 0.8, 0.5), energy: float = 0.85, scale: float = 2.0) -> PointLight2D:
	var light: PointLight2D = PointLight2D.new()
	light.texture = get_radial_light_texture()
	light.color = color
	light.energy = energy
	light.texture_scale = scale
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	return light

