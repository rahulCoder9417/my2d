extends Node2D

var frames: Array[FrameRecord] = []
var frame_index := 0

signal replay_finished

func start_reverse_playback(recorded_frames: Array[FrameRecord]) -> void:
	frames = recorded_frames.duplicate(true)
	frames.reverse()
	frame_index = 0

func _process(_delta):
	if frame_index >= frames.size():
		emit_signal("replay_finished")
		queue_free()
		return

	var state := frames[frame_index].state
	global_position = state.position

	if has_node("Sprite2D"):
		$Sprite2D.flip_h = state.facing < 0

	frame_index += 1
