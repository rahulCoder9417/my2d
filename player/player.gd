extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var state := PlayerState.new()


func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		velocity += get_gravity() * delta
		coyote_timer -= delta

# Jump buffer handling
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5

	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	state.position = global_position
	state.velocity = velocity
	state.is_on_floor = is_on_floor()
	state.facing = sign(velocity.x)
	state.is_jumping = velocity.y < 0
