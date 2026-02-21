extends CharacterBody2D
class_name Player1
#-----------
# CONSTANTS
#-----------
const GRAVITY: float = 1200.0
const MOVE_SPEED: float = 200.0
const JUMP_FORCE: float = -420.0
const MAX_JUMP_TIME: float = 0.25
const FAST_FALL_MULTIPLIER: float = 2.0
const COYOTE_TIME: float = 0.12
const MAX_JUMPS: int = 1
const PLATFORM_LAYER: int = 1 << 4
const DROP_THROUGH_TIME: float = 0.2
#-----------
# STATE MACHINE
#-----------
enum PlayerState { IDLE, WALK, JUMP }
var current_state: PlayerState = PlayerState.IDLE
#-----------
# JUMP CONTROL
#-----------
var jump_time: float = 0.0
var is_jumping: bool = false
var jump_count: int = 0
var was_on_floor: bool = false
var coyote_time_counter: float = 0.0
var drop_through_timer: float = 0.0
#-----------
# INPUT HELPERS
# Treat P1 and both as a single unified input so they share the same jump budget.
#-----------
func _jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("P1_up") or Input.is_action_just_pressed("both_up")

func _jump_held() -> bool:
	return Input.is_action_pressed("P1_up") or Input.is_action_pressed("both_up")

func _jump_just_released() -> bool:
	# Fires the frame either key is released, but only if neither is still held.
	var either_released := Input.is_action_just_released("P1_up") or Input.is_action_just_released("both_up")
	return either_released and not _jump_held()

func _down_just_pressed() -> bool:
	return Input.is_action_just_pressed("P1_down") or Input.is_action_just_pressed("both_down")

func _down_held() -> bool:
	return Input.is_action_pressed("P1_down") or Input.is_action_pressed("both_down")
#-----------
# PHYSICS
#-----------
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_coyote_time(delta)
	_handle_input(delta)
	_update_state()
	was_on_floor = is_on_floor()
	if drop_through_timer > 0.0:
		drop_through_timer -= delta
		if drop_through_timer <= 0.0:
			collision_mask |= PLATFORM_LAYER
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
#-----------
# COYOTE TIME
#-----------
func _handle_coyote_time(delta: float) -> void:
	if is_on_floor():
		jump_count = 0
		coyote_time_counter = COYOTE_TIME
	else:
		coyote_time_counter = max(coyote_time_counter - delta, 0.0)

func _can_jump() -> bool:
	return jump_count < MAX_JUMPS and (is_on_floor() or coyote_time_counter > 0.0)
#-----------
# INPUT
#-----------
func _handle_input(delta: float) -> void:
	var direction := 0
	if Input.is_action_pressed("P1_left") or Input.is_action_pressed("both_left"):
		direction -= 1
	if Input.is_action_pressed("P1_right") or Input.is_action_pressed("both_right"):
		direction += 1
	velocity.x = direction * MOVE_SPEED

	# Jump start — unified input, shared jump budget
	if _jump_just_pressed() and _can_jump():
		_start_jump()

	# Variable jump height — hold to float longer
	if _jump_held() and is_jumping:
		if jump_time < MAX_JUMP_TIME:
			velocity.y = JUMP_FORCE
			jump_time += delta
		else:
			is_jumping = false

	# Stop jump the moment neither key is held
	if _jump_just_released():
		is_jumping = false

	# Drop through platform
	if _down_just_pressed() and is_on_floor():
		_ignore_platforms_temporarily()

	# Fast fall
	if _down_held() and not is_on_floor():
		velocity.y += GRAVITY * FAST_FALL_MULTIPLIER * delta
#-----------
# JUMP FUNCTIONS
#-----------
func _start_jump() -> void:
	is_jumping = true
	jump_time = 0.0
	jump_count += 1
	velocity.y = JUMP_FORCE
	coyote_time_counter = 0.0

func _ignore_platforms_temporarily() -> void:
	collision_mask &= ~PLATFORM_LAYER
	drop_through_timer = DROP_THROUGH_TIME
#-----------
# STATE FUNCTIONS
#-----------
func _update_state() -> void:
	if not is_on_floor():
		current_state = PlayerState.JUMP
	elif abs(velocity.x) > 1.0:
		current_state = PlayerState.WALK
	else:
		current_state = PlayerState.IDLE
