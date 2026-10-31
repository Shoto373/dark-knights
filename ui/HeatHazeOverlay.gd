class_name HeatHazeOverlay
extends CanvasLayer

## Атмосферный оверлей жара и поднимающегося пепла в Мире огня

@onready var vignette_rect: ColorRect = %VignetteRect
@onready var ember_particles: CPUParticles2D = %EmberParticles

func _ready() -> void:
	layer = 10
	ember_particles.emitting = true
