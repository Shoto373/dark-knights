class_name State
extends Node

## Базовый класс состояния для StateMachine

var state_machine: StateMachine = null
var actor: CharacterBody2D = null

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
