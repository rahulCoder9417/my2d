extends Node

const MAX_REWIND_TIME := 4.0
const PHYSICS_FPS := 60
const MAX_FRAMES := int(MAX_REWIND_TIME * PHYSICS_FPS)

var is_rewinding := false
var rewindables: Array = []
var rewind_frame_counter := 0

func _physics_process(_delta):
	if is_rewinding:
		rewind_frame_counter += 1
		
		for r in rewindables:
			r.rewind_step()

		if rewind_frame_counter >= MAX_FRAMES:
			stop_rewind()
	else:
		for r in rewindables:
			r.save_frame()

func start_rewind():
	if is_rewinding:
		return
	
	is_rewinding = true
	rewind_frame_counter = 0

func stop_rewind():
	if not is_rewinding:
		return
	
	is_rewinding = false
	rewind_frame_counter = 0
