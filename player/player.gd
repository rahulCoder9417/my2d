extends CharacterBody2D
@onready var GhostScene := preload("res://ghost_player/ghost_player.tscn")
@onready var camera_controller := get_parent().get_node("Camera")

# --------------------
# CONSTANTS
# --------------------
const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12
const DECELERATION := 1800.0

const MAX_FRAMES := 300 # ~5 seconds at 60fps

# --------------------
# STATE & TIMERS
# --------------------
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

var state := PlayerState.new()
var frame_history: Array[FrameRecord] = []
var is_replaying := false
var saved_player_position: Vector2

# --------------------
# INPUT ABSTRACTION
# --------------------
func get_move_direction() -> int:
	# -1 = left, 0 = idle, 1 = right
	return int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))

func wants_to_jump() -> bool:
	return Input.is_action_just_pressed("Jump")

func released_jump() -> bool:
	return Input.is_action_just_released("Jump")

func wants_replay()->bool:
	return Input.is_action_just_pressed("spawn_ghost")
func get_input_state() -> InputState:
	var input := InputState.new()
	input.move_dir = get_move_direction()
	input.jump_pressed = wants_to_jump()
	input.jump_released = released_jump()
	input.replay = wants_replay()
	return input

# --------------------
# SIMULATION
# --------------------
func simulate(input: InputState, delta: float) -> void:
	if(input.replay):
		start_reverse_replay()
		return
	# --- Coyote time update ---
	$Sprite2D.flip_h =state.facing<0
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# --- Gravity ---
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- Jump buffer ---
	if input.jump_pressed:
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# --- Jump execution ---
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	# --- Variable jump height ---
	if input.jump_released and velocity.y < 0:
		velocity.y *= 0.5

	# --- Horizontal movement ---
	if input.move_dir != 0:
		velocity.x = input.move_dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)

	move_and_slide()

# --------------------
# PLAYER STATE UPDATE
# --------------------
func update_player_state() -> void:
	state.position = global_position
	state.velocity = velocity
	state.is_on_floor = is_on_floor()
	if abs(velocity.x) > 1:
		state.facing = sign(velocity.x)
	state.is_jumping = velocity.y < 0

# --------------------
# FRAME RECORDING
# --------------------
func record_frame(input: InputState) -> void:
	var frame := FrameRecord.new()
	frame.input = input
	frame.state = state.copy() # IMPORTANT: deep copy
	frame_history.append(frame)

	if frame_history.size() > MAX_FRAMES:
		frame_history.pop_front()
		
#Recorder Frame
func get_recorded_frames() -> Array[FrameRecord]:
	return frame_history.duplicate(true)
#===========
#SPAWN_GHOST
#===========
func start_reverse_replay():
	if frame_history.is_empty():
		return

	enter_replay_mode()

	var ghost := GhostScene.instantiate()
	get_parent().add_child(ghost)

	camera_controller.target = ghost

	ghost.global_position = frame_history[-1].state.position
	ghost.start_reverse_playback(get_recorded_frames())

	ghost.replay_finished.connect(func():
		camera_controller.target = self
		exit_replay_mode()
	)
#---------------------
#GET REPLAY
#---------------------
func enter_replay_mode():
	is_replaying = true
	saved_player_position = global_position
	visible = false
	set_physics_process(false)

func exit_replay_mode():
	global_position = saved_player_position
	visible = true
	set_physics_process(true)
	is_replaying = false
#==========
#READY MODE
#==========
func _ready() -> void:
	camera_controller.target = self
# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta: float) -> void:
	if is_replaying:
		return
	var input := get_input_state()
	simulate(input, delta)
	update_player_state()
	record_frame(input)
