extends CharacterBody2D

# --------------------
# CONSTANTS
# --------------------
const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12

const MAX_FRAMES := 300 # ~5 seconds at 60fps

# --------------------
# STATE & TIMERS
# --------------------
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

var state := PlayerState.new()
var frame_history: Array[FrameRecord] = []

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

func get_input_state() -> InputState:
	var input := InputState.new()
	input.move_dir = get_move_direction()
	input.jump_pressed = wants_to_jump()
	input.jump_released = released_jump()
	return input

# --------------------
# SIMULATION
# --------------------
func simulate(input: InputState, delta: float) -> void:
	# --- Coyote time update ---
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
		
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)

	move_and_slide()

# --------------------
# PLAYER STATE UPDATE
# --------------------
func update_player_state() -> void:
	state.position = global_position
	state.velocity = velocity
	state.is_on_floor = is_on_floor()
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

# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta: float) -> void:
	var input := get_input_state()
	simulate(input, delta)
	update_player_state()
	record_frame(input)
