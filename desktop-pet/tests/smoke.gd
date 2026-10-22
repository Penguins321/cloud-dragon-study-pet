extends SceneTree

func _initialize() -> void:
    preload("res://tests/smoke_runner.gd").run.call_deferred(self)
