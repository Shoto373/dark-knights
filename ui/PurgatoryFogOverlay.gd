class_name PurgatoryFogOverlay
extends CanvasLayer

## Атмосферный эфирный оверлей Чистилища: мерцающий астральный туман и души

@onready var vignette_rect: ColorRect = %VignetteRect
@onready var mist_particles: CPUParticles2D = %MistParticles

func _ready() -> void:
	layer = 10
	mist_particles.emitting = true
