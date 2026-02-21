extends CharacterBody2D
class_name Player2

#-----------
# COMPONENTS
#-----------
@onready var shoulder_marker_2d : Marker2D = $Gameplay/ShoulderMarker2D

#-----------
# PUBLIC MARKER API
#-----------
func get_shoulder_global_position() -> Vector2:
	return shoulder_marker_2d.global_position

func get_marker_global_positions() -> Dictionary:
	return {
		"shoulder": shoulder_marker_2d.global_position
	}

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
const PLATFORM_LAYER: int = 1 << 4 # layer 5
const DROP_THROUGH_TIME: float = 0.2

#-----------
# ROPE MID-AIR
#-----------
var is_rope_midair: bool = false

func set_rope_midair(enabled: bool) -> void:
	is_rope_midair = enabled
	# IMPORTANT: stop jump-hold behaviour immediately when entering rope-midair
	if is_rope_midair:
		is_jumping = false
		jump_time = 0.0

func get_rope_midair() -> bool:
	return is_rope_midair

#-----------
# "WEIGHT" / PLATFORM INFLUENCE (IMPULSE VERSION)
#-----------
@export var player_mass: float = 1.0
@export var rope_platform_body_path: NodePath
@export var only_affect_platform_layer: bool = true
@export var landing_weight_impulse: float = 140.0
@export var landing_push_impulse: float = 55.0
@export var move_change_impulse: float = 35.0
@export var move_change_threshold: float = 20.0
@export var drop_through_nudge: float = 80.0
@export var drop_only_on_platform: bool = true

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

# Cached each frame AFTER move_and_slide()
var is_on_platform: bool = false
var floor_rigid_body: RigidBody2D = null

# For impulse detection
var _prev_floor_rigid_body: RigidBody2D = null
var _prev_x_velocity: float = 0.0

# Cached rope platform reference (optional)
var _rope_platform_body: RigidBody2D = null

# Drop-through latch
var _dropping_through: bool = false

#-----------
# INPUT HELPERS
#-----------
func _jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("P2_up") or Input.is_action_just_pressed("both_up")

func _jump_held() -> bool:
	return Input.is_action_pressed("P2_up") or Input.is_action_pressed("both_up")

func _jump_just_released() -> bool:
	var either_released := Input.is_action_just_released("P2_up") or Input.is_action_just_released("both_up")
	return either_released and not _jump_held()

func _down_just_pressed() -> bool:
	return Input.is_action_just_pressed("P2_down") or Input.is_action_just_pressed("both_down")

func _down_held() -> bool:
	return Input.is_action_pressed("P2_down") or Input.is_action_pressed("both_down")

#-----------
# PHYSICS
#-----------
func _ready() -> void:
	if rope_platform_body_path != NodePath():
		var n: Node = get_node_or_null(rope_platform_body_path)
		if n is RigidBody2D:
			_rope_platform_body = n as RigidBody2D

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_coyote_time(delta)
	_handle_input(delta)
	_update_state()

	# Drop-through timer
	if drop_through_timer > 0.0:
		drop_through_timer -= delta
		if drop_through_timer <= 0.0:
			collision_mask |= PLATFORM_LAYER
			_dropping_through = false

	move_and_slide()

	_update_floor_info()
	_apply_platform_impulses()

	was_on_floor = is_on_floor()
	_prev_floor_rigid_body = floor_rigid_body
	_prev_x_velocity = velocity.x

func _apply_gravity(delta: float) -> void:
	# If rope is holding us midair, gravity is disabled
	if is_rope_midair:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
		return

	if is_on_platform and not _dropping_through:
		velocity.y = minf(velocity.y, 0.0)

#-----------
# FLOOR / PLATFORM DETECTION
#-----------
func _update_floor_info() -> void:
	is_on_platform = false
	floor_rigid_body = null

	var up_dir: Vector2 = up_direction

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_normal().dot(up_dir) > 0.7:
			var collider: Object = col.get_collider()
			if collider == null:
				continue

			if collider is RigidBody2D:
				floor_rigid_body = collider as RigidBody2D

			var layer_mask: int = 0
			if collider is CollisionObject2D:
				layer_mask = (collider as CollisionObject2D).collision_layer
			elif collider is TileMap:
				layer_mask = (collider as TileMap).collision_layer

			if (layer_mask & PLATFORM_LAYER) != 0:
				is_on_platform = true

#-----------
# PLATFORM INFLUENCE (IMPULSES)
#-----------
func _should_affect_floor_body(rb: RigidBody2D) -> bool:
	if rb == null:
		return false
	if not is_on_floor():
		return false

	if _rope_platform_body != null:
		return rb == _rope_platform_body

	if only_affect_platform_layer:
		return (rb.collision_layer & PLATFORM_LAYER) != 0

	return true

func _apply_platform_impulses() -> void:
	if not _should_affect_floor_body(floor_rigid_body):
		return

	var offset: Vector2 = global_position - floor_rigid_body.global_position

	var just_landed: bool = (not was_on_floor) and is_on_floor()
	var changed_floor: bool = (_prev_floor_rigid_body != null and _prev_floor_rigid_body != floor_rigid_body)

	if just_landed or changed_floor:
		floor_rigid_body.apply_impulse(Vector2(0.0, landing_weight_impulse * player_mass), offset)

		var clamped_x: float = clampf(velocity.x, -MOVE_SPEED, MOVE_SPEED)
		var x_imp: float = clamped_x / MOVE_SPEED
		floor_rigid_body.apply_impulse(Vector2(x_imp * landing_push_impulse * player_mass, 0.0), offset)

	var x_change: float = absf(velocity.x - _prev_x_velocity)
	if x_change >= move_change_threshold:
		var dir: float = signf(velocity.x)
		if dir != 0.0:
			floor_rigid_body.apply_impulse(Vector2(dir * move_change_impulse * player_mass, 0.0), offset)

#-----------
# COYOTE TIME
#-----------
func _handle_coyote_time(delta: float) -> void:
	if is_on_floor():
		jump_count = 0
		coyote_time_counter = COYOTE_TIME
	else:
		coyote_time_counter = maxf(coyote_time_counter - delta, 0.0)

func _can_jump() -> bool:
	return jump_count < MAX_JUMPS and (is_on_floor() or coyote_time_counter > 0.0)

#-----------
# INPUT
#-----------
func _handle_input(delta: float) -> void:
	# Horizontal always works
	var direction := 0
	if Input.is_action_pressed("P2_left") or Input.is_action_pressed("both_left"):
		direction -= 1
	if Input.is_action_pressed("P2_right") or Input.is_action_pressed("both_right"):
		direction += 1
	velocity.x = direction * MOVE_SPEED

	# IMPORTANT: While rope-midair, UP/DOWN are reserved for rope climbing (handled by CharacterManager)
	if is_rope_midair:
		is_jumping = false
		jump_time = 0.0
		return

	# Normal ground/air input below
	if _down_just_pressed() and is_on_floor():
		if (not drop_only_on_platform) or is_on_platform:
			_ignore_platforms_temporarily()
			_dropping_through = true
			is_jumping = false
			jump_time = 0.0
			velocity.y = maxf(velocity.y, drop_through_nudge)
			return

	if _jump_just_pressed() and _can_jump():
		_start_jump()

	if _jump_held() and is_jumping:
		if jump_time < MAX_JUMP_TIME:
			velocity.y = JUMP_FORCE
			jump_time += delta
		else:
			is_jumping = false

	if _jump_just_released():
		is_jumping = false

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
	elif absf(velocity.x) > 1.0:
		current_state = PlayerState.WALK
	else:
		current_state = PlayerState.IDLE
