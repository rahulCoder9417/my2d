extends Node2D

@export var follow_speed := 8.0
var target: Node2D

func _process(delta):
	if target:
		global_position = global_position.lerp(
			target.global_position,
			follow_speed * delta
		)
