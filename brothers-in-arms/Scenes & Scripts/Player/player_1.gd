extends CharacterBody2D
class_name Player1

#-----------
# COMPONENTS
#-----------
@onready var shoulder_marker_2d : Marker2D = $Gameplay/ShoulderMarker2D

# SPRITES
@onready var run : AnimatedSprite2D = $Artwork/Sprites/Run
@onready var idle : AnimatedSprite2D = $Artwork/Sprites/Idle
@onready var jump_start : AnimatedSprite2D = $Artwork/Sprites/JumpStart
@onready var jump_falling : AnimatedSprite2D = $Artwork/Sprites/JumpFalling
@onready var jump_end : AnimatedSprite2D = $Artwork/Sprites/JumpEnd
@onready var knockback : AnimatedSprite2D = $Artwork/Sprites/Knockback
@onready var hang_start : AnimatedSprite2D = $Artwork/Sprites/HangStart
@onready var hang : AnimatedSprite2D = $Artwork/Sprites/Hang
@onready var anchor : AnimatedSprite2D = $Artwork/Sprites/Anchor

@onready var jump_start_timer : Timer = $Artwork/Sprites/JumpStart/JumpStartTimer
@onready var jump_end_timer : Timer = $Artwork/Sprites/JumpEnd/JumpEndTimer
@onready var hang_start_transition_timer : Timer = $Artwork/Sprites/HangStart/HangStartTransitionTimer

#-----------
# SFX NODES (SAFE LOOKUP VIA NODEPATHS)
#   - Using NodePath + get_node_or_null so missing nodes don't hard-crash on ready.
#   - These should point at your RandomSFXPlayer2D nodes.
#-----------
@export_group("SFX - Node Paths")
@export var jump_sfx_path: NodePath = NodePath("Sound/JumpSFX")
@export var swing_peak_sfx_path: NodePath = NodePath("Sound/SwingPeakSFX")
@export var anchor_tension_sfx_path: NodePath = NodePath("Sound/AnchorTensionSFX")
@export var swing_apex_jump_sfx_path: NodePath = NodePath("Sound/SwingApexJumpSFX")
@export var hurt_sfx_path: NodePath = NodePath("Sound/HurtSFX")
@export var bounce_sfx_path: NodePath = NodePath("Sound/BounceSFX")

var jump_SFX: RandomSFXPlayer2D = null
var swing_peak_sfx: RandomSFXPlayer2D = null
var anchor_tension_sfx: RandomSFXPlayer2D = null
var swing_apex_jump_sfx: RandomSFXPlayer2D = null
var hurt_sfx: RandomSFXPlayer2D = null
var bounce_sfx: RandomSFXPlayer2D = null

@export var warn_if_missing_sfx_nodes: bool = true

#-----------
# PUBLIC MARKER API
#-----------
func get_shoulder_global_position() -> Vector2:
	return shoulder_marker_2d.global_position

func get_marker_global_positions() -> Dictionary:
	return { "shoulder": shoulder_marker_2d.global_position }

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
# MOVEMENT LOCK
#-----------
var _movement_locked: bool = false
var _locked_global_position: Vector2 = Vector2.ZERO

## Public: locks ALL movement (input, gravity, rope pushes, everything).
func lock_movement(enabled: bool) -> void:
	if _movement_locked == enabled:
		return

	_movement_locked = enabled

	if _movement_locked:
		_locked_global_position = global_position
		velocity = Vector2.ZERO
		is_jumping = false
		jump_time = 0.0

		# Anchor pose instantly
		set_animation(AnimKey.ANCHOR)

		# Play anchor tension once when becoming anchor
		_play_anchor_tension_sfx()
	else:
		_locked_global_position = global_position

func is_movement_locked() -> bool:
	return _movement_locked

func _apply_movement_lock() -> void:
	velocity = Vector2.ZERO
	global_position = _locked_global_position

#-----------
# ANIMATION SYSTEM (VISIBILITY + PUBLIC API)
#-----------
enum AnimKey {
	IDLE,
	RUN,
	JUMP_START,
	JUMP_FALLING,
	JUMP_END,
	KNOCKBACK,
	HANG_START,
	HANG,
	ANCHOR
}

var _anim_map: Dictionary = {}
var _current_anim_key: int = AnimKey.IDLE

@export var animations_play_when_hidden: bool = true
@export var run_deadzone: float = 1.0

# Jump animation control
var _is_in_jump_start: bool = false
var _is_in_jump_end: bool = false

# Hang animation control
var _is_in_hang_start: bool = false
var _was_rope_midair: bool = false

func set_animation(anim_key: int) -> void:
	if anim_key == _current_anim_key and _is_anim_visible(anim_key):
		return
	_current_anim_key = anim_key
	_show_only(anim_key)

func hide_all_animations() -> void:
	for k in _anim_map.keys():
		var s: AnimatedSprite2D = _anim_map[k]
		if s != null:
			s.visible = false

func set_all_animations_visible(visible_enabled: bool) -> void:
	for k in _anim_map.keys():
		var s: AnimatedSprite2D = _anim_map[k]
		if s != null:
			s.visible = visible_enabled

func get_current_animation() -> int:
	return _current_anim_key

func _is_anim_visible(anim_key: int) -> bool:
	var s: AnimatedSprite2D = _anim_map.get(anim_key, null)
	return s != null and s.visible

func _show_only(anim_key: int) -> void:
	for k in _anim_map.keys():
		var s: AnimatedSprite2D = _anim_map[k]
		if s == null:
			continue

		var should_show: bool = (int(k) == anim_key)
		s.visible = should_show

		var is_one_shot := (int(k) == AnimKey.JUMP_START) or (int(k) == AnimKey.JUMP_END) or (int(k) == AnimKey.HANG_START)

		if animations_play_when_hidden and (not is_one_shot) and not s.is_playing():
			s.play()

		if should_show:
			s.frame = 0
			s.play()

#-----------
# SPRITE FLIP
#-----------
@export var flip_deadzone: float = 1.0
var _facing_right: bool = true

func set_facing_right(enabled: bool) -> void:
	_facing_right = enabled
	_apply_flip_to_all()

func get_facing_right() -> bool:
	return _facing_right

func _apply_flip_to_all() -> void:
	var flip_h: bool = not _facing_right
	for s in _anim_map.values():
		if s != null:
			s.flip_h = flip_h

func _update_facing_from_velocity() -> void:
	if absf(velocity.x) <= flip_deadzone:
		return
	_facing_right = velocity.x > 0.0
	_apply_flip_to_all()

#-----------
# IDLE LOOK
#-----------
@export var idle_face_other_enabled: bool = true
@export var idle_face_deadzone: float = 1.0
@export var other_player_path: NodePath

var _other_player: Node2D = null

func _cache_other_player() -> void:
	if other_player_path == NodePath():
		_other_player = null
		return
	var n := get_node_or_null(other_player_path)
	_other_player = n as Node2D

func _face_other_player_if_idle() -> void:
	if not idle_face_other_enabled:
		return
	if _other_player == null:
		return
	if absf(velocity.x) > idle_face_deadzone:
		return

	_facing_right = _other_player.global_position.x >= global_position.x
	_apply_flip_to_all()

#-----------
# ROPE MID-AIR
#-----------
var is_rope_midair: bool = false

func set_rope_midair(enabled: bool) -> void:
	is_rope_midair = enabled
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
	return Input.is_action_just_pressed("P1_up") or Input.is_action_just_pressed("both_up")

func _jump_held() -> bool:
	return Input.is_action_pressed("P1_up") or Input.is_action_pressed("both_up")

func _jump_just_released() -> bool:
	var either_released := Input.is_action_just_released("P1_up") or Input.is_action_just_released("both_up")
	return either_released and not _jump_held()

func _down_just_pressed() -> bool:
	return Input.is_action_just_pressed("P1_down") or Input.is_action_just_pressed("both_down")

#-----------
# SFX TUNING
#-----------
@export_group("SFX - Jump")
## Minimum pitch used for jump SFX (1.0 = normal).
@export var jump_sfx_min_pitch: float = 0.95
## Maximum pitch used for jump SFX (1.0 = normal).
@export var jump_sfx_max_pitch: float = 1.05

@export_group("SFX - Anchor Tension")
## Minimum pitch used for anchor tension SFX (1.0 = normal).
@export var anchor_tension_sfx_min_pitch: float = 0.95
## Maximum pitch used for anchor tension SFX (1.0 = normal).
@export var anchor_tension_sfx_max_pitch: float = 1.05

@export_group("SFX - Swing Peak")
## Minimum pitch used for swing peak SFX (1.0 = normal).
@export var swing_peak_sfx_min_pitch: float = 0.95
## Maximum pitch used for swing peak SFX (1.0 = normal).
@export var swing_peak_sfx_max_pitch: float = 1.05

@export_group("SFX - Swing Apex Jump")
## Minimum pitch used for swing apex-jump SFX (1.0 = normal).
@export var swing_apex_jump_sfx_min_pitch: float = 0.95
## Maximum pitch used for swing apex-jump SFX (1.0 = normal).
@export var swing_apex_jump_sfx_max_pitch: float = 1.05

func _play_jump_sfx() -> void:
	if jump_SFX == null:
		return
	jump_SFX.call_deferred("play_random_child", jump_sfx_min_pitch, jump_sfx_max_pitch)

func _play_anchor_tension_sfx() -> void:
	if anchor_tension_sfx == null:
		return
	anchor_tension_sfx.call_deferred("play_random_child", anchor_tension_sfx_min_pitch, anchor_tension_sfx_max_pitch)

# NEW (PUBLIC): call from CharacterManager or anywhere
func play_swing_peak_sfx() -> void:
	if swing_peak_sfx == null:
		return
	swing_peak_sfx.call_deferred("play_random_child", swing_peak_sfx_min_pitch, swing_peak_sfx_max_pitch)

# NEW (PUBLIC): call from CharacterManager or anywhere
func play_swing_apex_jump_sfx() -> void:
	if swing_apex_jump_sfx == null:
		return
	swing_apex_jump_sfx.call_deferred("play_random_child", swing_apex_jump_sfx_min_pitch, swing_apex_jump_sfx_max_pitch)

func _cache_sfx_nodes() -> void:
	jump_SFX = get_node_or_null(jump_sfx_path) as RandomSFXPlayer2D
	swing_peak_sfx = get_node_or_null(swing_peak_sfx_path) as RandomSFXPlayer2D
	anchor_tension_sfx = get_node_or_null(anchor_tension_sfx_path) as RandomSFXPlayer2D
	swing_apex_jump_sfx = get_node_or_null(swing_apex_jump_sfx_path) as RandomSFXPlayer2D
	hurt_sfx = get_node_or_null(hurt_sfx_path) as RandomSFXPlayer2D
	bounce_sfx = get_node_or_null(bounce_sfx_path) as RandomSFXPlayer2D

	if warn_if_missing_sfx_nodes:
		if jump_SFX == null:
			push_warning("%s: Missing Jump SFX node at path '%s'." % [name, str(jump_sfx_path)])
		if anchor_tension_sfx == null:
			push_warning("%s: Missing Anchor Tension SFX node at path '%s'." % [name, str(anchor_tension_sfx_path)])
		if swing_peak_sfx == null:
			push_warning("%s: Missing Swing Peak SFX node at path '%s'." % [name, str(swing_peak_sfx_path)])
		if swing_apex_jump_sfx == null:
			push_warning("%s: Missing Swing Apex Jump SFX node at path '%s'." % [name, str(swing_apex_jump_sfx_path)])

#-----------
# LIFECYCLE
#-----------
func _ready() -> void:
	if rope_platform_body_path != NodePath():
		var n: Node = get_node_or_null(rope_platform_body_path)
		if n is RigidBody2D:
			_rope_platform_body = n as RigidBody2D

	_cache_other_player()
	_cache_sfx_nodes()

	_anim_map = {
		AnimKey.RUN: run,
		AnimKey.IDLE: idle,
		AnimKey.JUMP_START: jump_start,
		AnimKey.JUMP_FALLING: jump_falling,
		AnimKey.JUMP_END: jump_end,
		AnimKey.KNOCKBACK: knockback,
		AnimKey.HANG_START: hang_start,
		AnimKey.HANG: hang,
		AnimKey.ANCHOR: anchor,
	}

	# Timers: wire them up
	if jump_start_timer != null:
		jump_start_timer.one_shot = true
		if not jump_start_timer.timeout.is_connected(_on_jump_start_timeout):
			jump_start_timer.timeout.connect(_on_jump_start_timeout)

	if jump_end_timer != null:
		jump_end_timer.one_shot = true
		if not jump_end_timer.timeout.is_connected(_on_jump_end_timeout):
			jump_end_timer.timeout.connect(_on_jump_end_timeout)

	if hang_start_transition_timer != null:
		hang_start_transition_timer.one_shot = true
		if not hang_start_transition_timer.timeout.is_connected(_on_hang_start_timeout):
			hang_start_transition_timer.timeout.connect(_on_hang_start_timeout)

	# Optional: keep looped anims alive while hidden
	if animations_play_when_hidden:
		for k in _anim_map.keys():
			var s: AnimatedSprite2D = _anim_map[k]
			if s == null:
				continue
			var is_one_shot := (int(k) == AnimKey.JUMP_START) or (int(k) == AnimKey.JUMP_END) or (int(k) == AnimKey.HANG_START)
			if not is_one_shot:
				s.play()

	_apply_flip_to_all()
	set_animation(AnimKey.IDLE)

func _physics_process(delta: float) -> void:
	var prev_on_floor: bool = was_on_floor

	if _movement_locked:
		_apply_movement_lock()
		_update_animation(prev_on_floor)
		was_on_floor = is_on_floor()
		return

	_apply_gravity(delta)
	_handle_coyote_time(delta)
	_handle_input(delta)

	_update_facing_from_velocity()
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

	_update_animation(prev_on_floor)

	was_on_floor = is_on_floor()
	_prev_floor_rigid_body = floor_rigid_body
	_prev_x_velocity = velocity.x

#-----------
# GRAVITY
#-----------
func _apply_gravity(delta: float) -> void:
	if _movement_locked:
		return
	if is_rope_midair:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
		return

	if is_on_platform and not _dropping_through:
		velocity.y = minf(velocity.y, 0.0)

#-----------
# ANIMATION LOGIC (GROUND/AIR + JUMP + HANG)
#-----------
func _update_animation(prev_on_floor: bool) -> void:
	if _movement_locked:
		set_animation(AnimKey.ANCHOR)
		return

	if is_rope_midair and not _was_rope_midair:
		_was_rope_midair = true
		_play_hang_start()
		return

	if is_rope_midair:
		if _is_in_hang_start:
			return
		set_animation(AnimKey.HANG)
		return

	if (not is_rope_midair) and _was_rope_midair:
		_was_rope_midair = false
		_is_in_hang_start = false

	var now_on_floor: bool = is_on_floor()
	var just_landed: bool = (not prev_on_floor) and now_on_floor

	if just_landed:
		_play_jump_end()
		return

	if not now_on_floor:
		if _is_in_jump_start:
			return
		set_animation(AnimKey.JUMP_FALLING)
		return

	if _is_in_jump_end:
		return

	if absf(velocity.x) > run_deadzone:
		set_animation(AnimKey.RUN)
	else:
		set_animation(AnimKey.IDLE)
		_face_other_player_if_idle()

#-----------
# HANG START -> HANG
#-----------
func _play_hang_start() -> void:
	_is_in_hang_start = true
	set_animation(AnimKey.HANG_START)

	if hang_start_transition_timer != null:
		hang_start_transition_timer.start()
	else:
		_is_in_hang_start = false

func _on_hang_start_timeout() -> void:
	_is_in_hang_start = false
	if is_rope_midair and not _movement_locked:
		set_animation(AnimKey.HANG)

#-----------
# JUMP START/END
#-----------
func _play_jump_start() -> void:
	_is_in_jump_start = true
	set_animation(AnimKey.JUMP_START)
	if jump_start_timer != null:
		jump_start_timer.start()
	else:
		_is_in_jump_start = false

func _play_jump_end() -> void:
	_is_in_jump_start = false
	_is_in_jump_end = true
	set_animation(AnimKey.JUMP_END)
	if jump_end_timer != null:
		jump_end_timer.start()
	else:
		_is_in_jump_end = false

func _on_jump_start_timeout() -> void:
	_is_in_jump_start = false
	if not is_on_floor() and (not is_rope_midair):
		set_animation(AnimKey.JUMP_FALLING)

func _on_jump_end_timeout() -> void:
	_is_in_jump_end = false
	if is_on_floor():
		if absf(velocity.x) > run_deadzone:
			set_animation(AnimKey.RUN)
		else:
			set_animation(AnimKey.IDLE)
			_face_other_player_if_idle()

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
	if _movement_locked:
		return
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
	if _movement_locked:
		return

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
	if _movement_locked:
		velocity = Vector2.ZERO
		return

	var direction := 0
	if Input.is_action_pressed("P1_left") or Input.is_action_pressed("both_left"):
		direction -= 1
	if Input.is_action_pressed("P1_right") or Input.is_action_pressed("both_right"):
		direction += 1
	velocity.x = direction * MOVE_SPEED

	# Rope-midair: up/down reserved elsewhere
	if is_rope_midair:
		is_jumping = false
		jump_time = 0.0
		return

	# Drop-through
	if _down_just_pressed() and is_on_floor():
		if (not drop_only_on_platform) or is_on_platform:
			_ignore_platforms_temporarily()
			_dropping_through = true
			is_jumping = false
			jump_time = 0.0
			velocity.y = maxf(velocity.y, drop_through_nudge)
			return

	# Jump press -> play JumpStart + Jump SFX
	if _jump_just_pressed() and _can_jump():
		_start_jump()
		_play_jump_start()
		_play_jump_sfx()

	# Jump hold (variable height)
	if _jump_held() and is_jumping:
		if jump_time < MAX_JUMP_TIME:
			velocity.y = JUMP_FORCE
			jump_time += delta
		else:
			is_jumping = false

	if _jump_just_released():
		is_jumping = false

	# NOTE: Fast-fall removed to prevent anchor/platform issues.

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
