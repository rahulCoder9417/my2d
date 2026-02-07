class_name PlayerState

var position: Vector2
var velocity: Vector2
var is_on_floor: bool
var facing: int
var is_jumping: bool

func copy() -> PlayerState:
	var s := PlayerState.new()
	s.position = position
	s.velocity = velocity
	s.is_on_floor = is_on_floor
	s.facing = facing
	s.is_jumping = is_jumping
	return s
