extends Node

func _ready() -> void:
	preload("res://tests/smoke_runner.gd").run.call_deferred(get_tree())
