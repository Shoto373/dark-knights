class_name BlizzardOverlay
extends CanvasLayer

## Атмосферный оверлей метели: завихрения снега и ограничение видимости

@onready var vignette_rect: ColorRect = %VignetteRect
@onready var snow_particles: CPUParticles2D = %SnowParticles

func _ready() -> void:
	layer = 10
	snow_particles.emitting = true
