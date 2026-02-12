extends CharacterBody2D

@onready var camera_controller := get_parent().get_node("Camera")

# --------------------
# CONSTANTS
# --------------------
const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12
const DECELERATION := 1800.0

# --------------------
# REWIND STORAGE
# --------------------
var frame_history: Array = []
var health := 3

# --------------------
# STATE & TIMERS
# --------------------
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var current_jump_type := "jump"

# --------------------
# INPUT
# --------------------
func get_move_direction() -> int:
	return int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))

func wants_to_jump() -> bool:
	return Input.is_action_just_pressed("Jump")

func released_jump() -> bool:
	return Input.is_action_just_released("Jump")

# --------------------
# SAVE FRAME (called by TimelineManager)
# --------------------
func save_frame():
	var sprite := $AnimatedSprite2D
	var state_data = {
		"position": global_position,
		"velocity": velocity,
		"health": health,
		"flip_h": sprite.flip_h,
		"animation": sprite.animation,
		"frame": sprite.frame,
		"jump_type": current_jump_type
	}

	frame_history.append(state_data)

	if frame_history.size() > TimelineManager.MAX_FRAMES:
		frame_history.pop_front()

# --------------------
# REWIND STEP (called by TimelineManager)
# --------------------
func rewind_step():
	if frame_history.is_empty():
		return

	var state_data = frame_history.pop_back()

	global_position = state_data.position
	velocity = state_data.velocity
	health = state_data.health
	current_jump_type = state_data.jump_type

	var sprite := $AnimatedSprite2D
	sprite.flip_h = state_data.flip_h

	if sprite.animation != state_data.animation:
		sprite.play(state_data.animation)

	sprite.frame = state_data.frame

# --------------------
# SIMULATION
# --------------------
func simulate(delta: float) -> void:

	# --- Coyote Time ---
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# --- Gravity ---
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- Jump Buffer ---
	if wants_to_jump():
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# --- Jump Execution ---
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		current_jump_type = "jump"
		jump_buffer_timer = 0
		coyote_timer = 0

	# --- Short Jump Detection ---
	if released_jump() and velocity.y < 0:
		velocity.y *= 0.5
		current_jump_type = "jump"

	# --- Horizontal Movement ---
	var move_dir := get_move_direction()

	if move_dir != 0:
		velocity.x = move_dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)

	move_and_slide()

# --------------------
# ANIMATION
# --------------------
func update_animation():
	var sprite := $AnimatedSprite2D

	# Flip
	if abs(velocity.x) > 1:
		sprite.flip_h = velocity.x < 0

	# Air animations
	if not is_on_floor():
		if sprite.animation != current_jump_type:
			sprite.play(current_jump_type)
	else:
		if abs(velocity.x) > 5:
			if sprite.animation != "run":
				sprite.play("run")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")

# --------------------
# READY
# --------------------
func _ready() -> void:
	TimelineManager.rewindables.append(self)
	camera_controller.target = self

# --------------------
# INPUT FOR REWIND
# --------------------
func _input(event):
	if event.is_action_pressed("rewind"):
		TimelineManager.start_rewind()

	if event.is_action_released("rewind"):
		TimelineManager.stop_rewind()

# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta):

	# During rewind, simulation is blocked
	if TimelineManager.is_rewinding:
		return

	simulate(delta)
	update_animation()
