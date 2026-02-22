extends Node2D
class_name CharacterManager

#-----------
# COMPONENTS
#-----------
@onready var player_1: Player1 = $Player1
@onready var player_2: Player2 = $Player2

@onready var p_1_mindistance_marker_2d: Marker2D = $Player1/P1MindistanceMarker2D
@onready var p_2_mindistance_marker_2d: Marker2D = $Player2/P2MindistanceMarker2D

@onready var main_camera_2d: Camera2D = $Gameplay/MainCamera2D

# PLAYER ROPE (VISUAL) - this is now your "debug" and your stylised rope.
# Style it in the inspector: Gradient / Width Curve / Texture / Joint Mode / Cap Mode, etc.
@onready var line_2d: Line2D = $Gameplay/Line2D

# APEX (TIMERED)
@onready var apex_timer: Timer = $Gameplay/ApexTimer

#-----------
# VARIABLES (TUNING)
#-----------
@export_group("Camera")
@export var camera_padding: Vector2 = Vector2(220.0, 140.0)
@export var min_zoom: float = 0.55
@export var max_zoom: float = 1.35
@export var zoom_smooth: float = 6.0
@export var position_smooth: float = 8.0

@export_group("Camera - Distance")
@export var close_distance_threshold: float = 50.0

@export_group("Rope - Core")
@export var max_travel_distance: float = 260.0
@export var rope_strength: float = 18.0
@export var rope_damping: float = 10.0
@export var max_correction_speed: float = 520.0
@export var max_position_correction: float = 30.0

@export_group("Rope - Hard Clamp")
@export var hard_rope_enabled: bool = true
@export var hard_rope_slack: float = 6.0
@export var hard_rope_max_snap: float = 99999.0

@export_group("Rope - Tug-of-War Bias")
@export var brace_bias_enabled: bool = true
@export var grounded_brace_bonus: float = 0.35
@export var input_brace_bonus: float = 0.45
@export var min_weight: float = 0.2

@export_group("Rope - Damping")
@export var perpendicular_damping: float = 0.10

@export_group("Rope - Midair (Dangling)")
@export var rope_midair_enabled: bool = true
@export var rope_midair_taut_ratio: float = 0.95
@export var rope_midair_fall_threshold: float = 26.0

@export_group("Swing - Arcade")
@export var swing_enabled: bool = true
@export var swing_gravity: float = 1200.0
@export var swing_accel: float = 1.0
@export var swing_air_damping: float = 1.2
@export var swing_max_speed: float = 900.0

@export_group("Swing - Return Help")
@export var swing_return_min_accel: float = 900.0
@export var swing_return_deadzone: float = 0.06

@export_group("Swing - Pump")
@export var swing_pump_enabled: bool = true
@export var swing_pump_accel: float = 820.0
@export var swing_pump_requires_matching_dir: bool = true
@export var swing_pump_deadzone: float = 0.2

@export_group("Swing - Apex Release (Timered)")
@export var swing_apex_release_enabled: bool = true
@export var swing_apex_free_time: float = 0.35
@export var swing_apex_speed_threshold: float = 120.0
@export var swing_apex_jump_velocity: float = -420.0
@export var swing_apex_pop_horizontal: float = 120.0
@export var swing_apex_retrigger_lock: float = 0.18
@export var apex_peak_sfx_enabled: bool = true
@export var apex_jump_sfx_enabled: bool = true

@export_group("Swing - Apex Gate (IMPORTANT)")
@export var apex_min_angle_from_vertical_deg: float = 25.0

@export_group("Swing - Apex Timer Hold (INPUT LOCK)")
## If true, while apex timer is running we ignore player input completely (pump/climb/velocity.x influence).
## Rope still falls naturally because pendulum gravity continues.
@export var disable_input_while_apex_timer_active: bool = true
## Scale swing gravity/return-help while apex timer is active so the bob falls more like "no-input".
@export var apex_timer_swing_gravity_scale: float = 0.35
## Disable return-help while apex timer is active to prevent extra "snap" downward.
@export var apex_timer_disable_return_help: bool = true

@export_group("Swing - Apex Jump Height Clamp (PLAN B)")
@export var apex_jump_height_clamp_enabled: bool = true
@export var apex_jump_max_rise_px: float = 220.0
@export var apex_jump_clamp_duration: float = 0.35

@export_group("Rope - Apex Jump Tug Advantage (NEW)")
## When an apex jump fires, that player "wins" tug-of-war until they are grounded again.
## 1.0 = full win (other player takes 100% of correction), 0.0 = no advantage.
@export_range(0.0, 1.0, 0.01) var apex_tug_win_strength: float = 1.0

@export_group("Rope - Climb")
@export var rope_climb_enabled: bool = true
@export var rope_climb_speed: float = 220.0
@export var rope_climb_min_length: float = 120.0
@export var rope_climb_limit: float = 90.0
@export var rope_climb_jump_force: float = -520.0
@export var rope_climb_jump_cooldown: float = 0.15

@export_group("Rope - Visual")
## This replaces the debug line. Style the Line2D itself in the inspector (gradient/width curve/texture/etc).
@export var rope_line_enabled: bool = true

#-----------
# RUNTIME STATE
#-----------
var players_distance: float = 0.0

var _rope_current_length: float = 0.0
var _rope_base_length: float = 0.0
var _climb_cooldown_timer: float = 0.0
var _swing_free_timer: float = 0.0

# Apex detection state
var _p1_prev_tangent: float = 0.0
var _p2_prev_tangent: float = 0.0
var _p1_tangent_init: bool = false
var _p2_tangent_init: bool = false
var _apex_lock_timer: float = 0.0

# Apex pending
var _apex_pending: bool = false
var _apex_pending_bob_is_p1: bool = false
var _apex_pending_tangent_x_sign: float = 1.0

# During apex timer, keep a “trusted” velocity that ignores player input.
var _apex_hold_active: bool = false
var _apex_hold_bob_is_p1: bool = false
var _apex_hold_velocity: Vector2 = Vector2.ZERO

# Anchor state
var _anchor_active: bool = false
var _anchor_is_p1: bool = false

# Apex jump height clamp state
var _apex_clamp_active: bool = false
var _apex_clamp_is_p1: bool = false
var _apex_clamp_start_y: float = 0.0
var _apex_clamp_timer: float = 0.0

# Apex jump tug advantage state (wins tug-of-war until grounded)
var _apex_tug_adv_active: bool = false
var _apex_tug_adv_is_p1: bool = false


#-----------
# LIFECYCLE
#-----------
func _ready() -> void:
	main_camera_2d.make_current()
	process_priority = 1000

	# Rope visuals are controlled by the Line2D inspector now (gradient/texture/width curve, etc.)
	line_2d.visible = rope_line_enabled

	_rope_current_length = max_travel_distance
	_rope_base_length = max_travel_distance

	if apex_timer != null:
		apex_timer.one_shot = true
		if not apex_timer.timeout.is_connected(_on_apex_timer_timeout):
			apex_timer.timeout.connect(_on_apex_timer_timeout)
	else:
		push_warning("%s: ApexTimer node is missing at $Gameplay/ApexTimer" % name)


func _physics_process(delta: float) -> void:
	line_2d.visible = rope_line_enabled

	if _climb_cooldown_timer > 0.0:
		_climb_cooldown_timer = maxf(_climb_cooldown_timer - delta, 0.0)

	if _swing_free_timer > 0.0:
		_swing_free_timer = maxf(_swing_free_timer - delta, 0.0)

	if _apex_lock_timer > 0.0:
		_apex_lock_timer = maxf(_apex_lock_timer - delta, 0.0)

	# End tug advantage when the apex-jumper is grounded again
	_update_apex_tug_advantage_end()

	_update_players_distance()

	_apply_tug_of_war_rope(delta)
	_update_players_distance()

	_update_rope_midair_by_height()
	_update_anchor_lock_grounded_only()
	_cancel_apex_if_invalid()

	if swing_enabled:
		_apply_arcade_swing_and_climb(delta)
		_update_players_distance()

	_apply_apex_jump_height_clamp(delta)

	_update_rope_line()
	_update_camera(delta)


#-----------
# DISTANCE + ROPE LINE (VISUAL)
#-----------
func _update_players_distance() -> void:
	players_distance = p_1_mindistance_marker_2d.global_position.distance_to(
		p_2_mindistance_marker_2d.global_position
	)


func _update_rope_line() -> void:
	# Only update points. Everything else is styled in the Line2D inspector.
	line_2d.points = [
		line_2d.to_local(p_1_mindistance_marker_2d.global_position),
		line_2d.to_local(p_2_mindistance_marker_2d.global_position)
	]


#-----------
# MARKER-CONSTRAINT HELPERS
#-----------
func _set_player_pos_from_marker(player: Node2D, marker: Marker2D, new_marker_pos: Vector2) -> void:
	var offset: Vector2 = marker.global_position - player.global_position
	player.global_position = new_marker_pos - offset


#-----------
# APEX TUG ADVANTAGE
#-----------
func _start_apex_tug_advantage(bob_is_p1: bool) -> void:
	_apex_tug_adv_active = true
	_apex_tug_adv_is_p1 = bob_is_p1


func _update_apex_tug_advantage_end() -> void:
	if not _apex_tug_adv_active:
		return

	if _apex_tug_adv_is_p1:
		if player_1.is_on_floor():
			_apex_tug_adv_active = false
	else:
		if player_2.is_on_floor():
			_apex_tug_adv_active = false


#-----------
# ANCHOR LOCK (GROUNDED ONLY)
#-----------
func _update_anchor_lock_grounded_only() -> void:
	var p1_dangling: bool = player_1.get_rope_midair()
	var p2_dangling: bool = player_2.get_rope_midair()

	_anchor_active = false

	if p1_dangling and not p2_dangling:
		if player_2.is_on_floor():
			_anchor_active = true
			_anchor_is_p1 = false
	elif p2_dangling and not p1_dangling:
		if player_1.is_on_floor():
			_anchor_active = true
			_anchor_is_p1 = true

	if _anchor_active:
		if _anchor_is_p1:
			if player_1.has_method("lock_movement"):
				player_1.lock_movement(true)
			if player_2.has_method("lock_movement"):
				player_2.lock_movement(false)
		else:
			if player_2.has_method("lock_movement"):
				player_2.lock_movement(true)
			if player_1.has_method("lock_movement"):
				player_1.lock_movement(false)
	else:
		if player_1.has_method("lock_movement"):
			player_1.lock_movement(false)
		if player_2.has_method("lock_movement"):
			player_2.lock_movement(false)


#-----------
# ROPE MID-AIR (LATCHED) — ONLY LOWER PLAYER
#-----------
func _update_rope_midair_by_height() -> void:
	if not rope_midair_enabled:
		player_1.set_rope_midair(false)
		player_2.set_rope_midair(false)
		return

	if _climb_cooldown_timer > 0.0 or _swing_free_timer > 0.0:
		player_1.set_rope_midair(false)
		player_2.set_rope_midair(false)
		return

	var p1_dangling: bool = player_1.get_rope_midair()
	var p2_dangling: bool = player_2.get_rope_midair()

	# Already dangling?
	if p1_dangling or p2_dangling:
		if p1_dangling and player_1.is_on_floor():
			player_1.set_rope_midair(false)
		if p2_dangling and player_2.is_on_floor():
			player_2.set_rope_midair(false)

		if not player_1.get_rope_midair() and not player_2.get_rope_midair():
			_rope_current_length = max_travel_distance
			_rope_base_length = max_travel_distance
		return

	var taut: bool = players_distance >= (max_travel_distance * rope_midair_taut_ratio)
	if not taut:
		player_1.set_rope_midair(false)
		player_2.set_rope_midair(false)
		return

	var y1: float = p_1_mindistance_marker_2d.global_position.y
	var y2: float = p_2_mindistance_marker_2d.global_position.y
	var dy: float = y1 - y2

	var start_p1_dangling: bool = false
	var start_p2_dangling: bool = false

	if dy >= rope_midair_fall_threshold:
		start_p1_dangling = true
	elif dy <= -rope_midair_fall_threshold:
		start_p2_dangling = true

	if start_p1_dangling and player_1.is_on_floor():
		start_p1_dangling = false
	if start_p2_dangling and player_2.is_on_floor():
		start_p2_dangling = false

	player_1.set_rope_midair(start_p1_dangling)
	player_2.set_rope_midair(start_p2_dangling)

	if start_p1_dangling or start_p2_dangling:
		_rope_base_length = clampf(players_distance, rope_climb_min_length, max_travel_distance)
		_rope_current_length = _rope_base_length
		if start_p1_dangling:
			_p1_tangent_init = false
		if start_p2_dangling:
			_p2_tangent_init = false


#-----------
# APEX PENDING VALIDATION
#-----------
func _cancel_apex_if_invalid() -> void:
	if not _apex_pending:
		return

	var p1_dangling: bool = player_1.get_rope_midair()
	var p2_dangling: bool = player_2.get_rope_midair()

	var bob_still_dangling: bool
	if _apex_pending_bob_is_p1:
		bob_still_dangling = p1_dangling
	else:
		bob_still_dangling = p2_dangling

	if not bob_still_dangling:
		_apex_pending = false
		_apex_hold_active = false
		_apex_hold_velocity = Vector2.ZERO

		if apex_timer != null and apex_timer.time_left > 0.0:
			apex_timer.stop()


#-----------
# APEX GATE
#-----------
func _is_valid_apex_geometry(r_hat: Vector2) -> bool:
	var down: Vector2 = Vector2(0.0, 1.0)
	var dot_down: float = clampf(r_hat.dot(down), -1.0, 1.0)
	var angle_from_vertical: float = acos(dot_down)
	var min_angle: float = deg_to_rad(apex_min_angle_from_vertical_deg)
	return angle_from_vertical >= min_angle


#-----------
# SWING / CLIMB / APEX TIMER START
#   While apex timer is running:
#     - input is ignored (pump + climb disabled)
#     - pendulum fall still happens, but gravity can be scaled and return-help disabled
#-----------
func _apply_arcade_swing_and_climb(delta: float) -> void:
	var p1_is_dangling: bool = player_1.get_rope_midair()
	var p2_is_dangling: bool = player_2.get_rope_midair()
	if not p1_is_dangling and not p2_is_dangling:
		_rope_current_length = max_travel_distance
		_rope_base_length = max_travel_distance
		_p1_tangent_init = false
		_p2_tangent_init = false
		return

	var anchor_marker: Marker2D
	var bob_marker: Marker2D
	var bob_player: CharacterBody2D
	var bob_is_p1: bool

	if p1_is_dangling:
		bob_player = player_1
		bob_marker = p_1_mindistance_marker_2d
		anchor_marker = p_2_mindistance_marker_2d
		bob_is_p1 = true
	else:
		bob_player = player_2
		bob_marker = p_2_mindistance_marker_2d
		anchor_marker = p_1_mindistance_marker_2d
		bob_is_p1 = false

	var anchor_pos: Vector2 = anchor_marker.global_position
	var bob_pos: Vector2 = bob_marker.global_position

	var r_vec: Vector2 = bob_pos - anchor_pos
	var r_len: float = r_vec.length()
	if r_len <= 0.0001:
		return

	var r_hat: Vector2 = r_vec / r_len
	var tangent: Vector2 = Vector2(-r_hat.y, r_hat.x)

	# Apex timer waiting?
	var apex_waiting: bool = false
	if _apex_pending:
		apex_waiting = true
	elif apex_timer != null and apex_timer.time_left > 0.0:
		apex_waiting = true

	# -------------------------
	# CLIMB (disabled during apex timer if input lock is enabled)
	# -------------------------
	var allow_climb: bool = rope_climb_enabled
	if apex_waiting and disable_input_while_apex_timer_active:
		allow_climb = false

	if allow_climb:
		var climb_input: float = _get_bob_vertical_input(bob_is_p1)
		var max_len_allowed: float = max_travel_distance
		var min_len_allowed: float = maxf(rope_climb_min_length, _rope_base_length - rope_climb_limit)

		if climb_input != 0.0:
			_rope_current_length += climb_input * rope_climb_speed * delta
			_rope_current_length = clampf(_rope_current_length, min_len_allowed, max_len_allowed)

		if _rope_current_length <= (_rope_base_length - rope_climb_limit + 0.001):
			_rope_current_length = max_travel_distance
			_rope_base_length = max_travel_distance
			_climb_cooldown_timer = rope_climb_jump_cooldown

			if bob_is_p1:
				player_1.set_rope_midair(false)
			else:
				player_2.set_rope_midair(false)

			var vel_jump: Vector2 = bob_player.velocity
			vel_jump.y = rope_climb_jump_force
			bob_player.velocity = vel_jump
			return

	# -------------------------
	# Velocity source (hold during apex timer so player input can't override)
	# -------------------------
	var vel2: Vector2
	if apex_waiting and disable_input_while_apex_timer_active:
		if not _apex_hold_active or _apex_hold_bob_is_p1 != bob_is_p1:
			_apex_hold_active = true
			_apex_hold_bob_is_p1 = bob_is_p1
			_apex_hold_velocity = bob_player.velocity
		vel2 = _apex_hold_velocity
	else:
		vel2 = bob_player.velocity

	# Remove radial velocity (prevents stretch)
	var radial_speed: float = vel2.dot(r_hat)
	vel2 -= r_hat * radial_speed

	# Pendulum accel (always allowed; scaled during apex wait if desired)
	var grav_scale: float = 1.0
	if apex_waiting and disable_input_while_apex_timer_active:
		grav_scale = apex_timer_swing_gravity_scale

	var down: Vector2 = Vector2(0.0, 1.0)
	var sin_theta: float = down.dot(tangent)
	var tangential_accel: float = swing_gravity * sin_theta * swing_accel * grav_scale

	var allow_return_help: bool = true
	if apex_waiting and disable_input_while_apex_timer_active and apex_timer_disable_return_help:
		allow_return_help = false

	if allow_return_help and absf(sin_theta) > swing_return_deadzone:
		tangential_accel = signf(sin_theta) * maxf(absf(tangential_accel), swing_return_min_accel * grav_scale)

	vel2 += tangent * tangential_accel * delta

	# Pump (disabled during apex wait if input lock is enabled)
	var allow_pump: bool = swing_pump_enabled
	if apex_waiting and disable_input_while_apex_timer_active:
		allow_pump = false

	if allow_pump:
		var input_dir: float = _get_bob_horizontal_input(bob_is_p1)
		if absf(input_dir) >= swing_pump_deadzone:
			var pump_sign: float = input_dir * signf(tangent.x)
			if not swing_pump_requires_matching_dir:
				vel2 += tangent * (swing_pump_accel * pump_sign) * delta
			else:
				var current_tangent_speed: float = vel2.dot(tangent)
				var swing_dir: float = signf(current_tangent_speed)
				if swing_dir == 0.0 or signf(pump_sign) == swing_dir:
					vel2 += tangent * (swing_pump_accel * pump_sign) * delta

	# Dampen/cap tangential speed
	var tangential_speed: float = vel2.dot(tangent)
	tangential_speed *= exp(-swing_air_damping * delta)
	tangential_speed = clampf(tangential_speed, -swing_max_speed, swing_max_speed)

	var v_other: Vector2 = vel2 - (tangent * vel2.dot(tangent))
	vel2 = v_other + (tangent * tangential_speed)

	# Start apex timer only when NOT already waiting
	if (not apex_waiting) and swing_apex_release_enabled and _apex_lock_timer <= 0.0:
		if _is_valid_apex_geometry(r_hat):
			var flip_detected: bool = _check_apex_tangent_flip(bob_is_p1, vel2.dot(tangent))
			if flip_detected:
				_start_apex_timer_for_bob(bob_is_p1, tangent.x)

	# Commit
	bob_player.velocity = vel2

	if apex_waiting and disable_input_while_apex_timer_active:
		_apex_hold_active = true
		_apex_hold_bob_is_p1 = bob_is_p1
		_apex_hold_velocity = vel2

	# Snap dangling marker to current rope length
	var desired_marker_pos: Vector2 = anchor_pos + (r_hat * _rope_current_length)
	_set_player_pos_from_marker(bob_player, bob_marker, desired_marker_pos)


#-----------
# APEX TIMER START + SFX
#-----------
func _start_apex_timer_for_bob(bob_is_p1: bool, tangent_x_sign: float) -> void:
	if apex_timer == null:
		return
	if _apex_pending or apex_timer.time_left > 0.0:
		return

	_apex_pending = true
	_apex_pending_bob_is_p1 = bob_is_p1

	_apex_pending_tangent_x_sign = tangent_x_sign
	if _apex_pending_tangent_x_sign == 0.0:
		_apex_pending_tangent_x_sign = 1.0

	# initialise hold velocity at the moment the timer starts (locks out input)
	if disable_input_while_apex_timer_active:
		_apex_hold_active = true
		_apex_hold_bob_is_p1 = bob_is_p1
		if bob_is_p1:
			_apex_hold_velocity = player_1.velocity
		else:
			_apex_hold_velocity = player_2.velocity

	if apex_peak_sfx_enabled:
		var bob_for_sfx: Node = null
		if bob_is_p1:
			bob_for_sfx = player_1
		else:
			bob_for_sfx = player_2

		if bob_for_sfx != null and bob_for_sfx.has_method("play_swing_peak_sfx"):
			bob_for_sfx.call_deferred("play_swing_peak_sfx")

	apex_timer.start()


#-----------
# APEX TIMER TIMEOUT -> EXECUTE JUMP + SFX
#-----------
func _on_apex_timer_timeout() -> void:
	if not _apex_pending:
		return

	var bob_is_p1: bool = _apex_pending_bob_is_p1
	var bob: CharacterBody2D = null

	if bob_is_p1:
		bob = player_1
		if not player_1.get_rope_midair():
			_apex_pending = false
			_apex_hold_active = false
			return
	else:
		bob = player_2
		if not player_2.get_rope_midair():
			_apex_pending = false
			_apex_hold_active = false
			return

	if bob == null:
		_apex_pending = false
		_apex_hold_active = false
		return

	_execute_apex_jump(bob_is_p1, _apex_pending_tangent_x_sign)
	_apex_pending = false

	_apex_hold_active = false
	_apex_hold_velocity = Vector2.ZERO


func _execute_apex_jump(bob_is_p1: bool, tangent_x_sign: float) -> void:
	# Release rope-midair so Player gravity resumes
	if bob_is_p1:
		player_1.set_rope_midair(false)
	else:
		player_2.set_rope_midair(false)

	# SFX on jump
	if apex_jump_sfx_enabled:
		var bob_for_sfx: Node = null
		if bob_is_p1:
			bob_for_sfx = player_1
		else:
			bob_for_sfx = player_2

		if bob_for_sfx != null and bob_for_sfx.has_method("play_swing_apex_jump_sfx"):
			bob_for_sfx.call_deferred("play_swing_apex_jump_sfx")

	# Apply velocity
	var bob: CharacterBody2D = null
	if bob_is_p1:
		bob = player_1
	else:
		bob = player_2

	if bob == null:
		return

	# Start apex height clamp
	if apex_jump_height_clamp_enabled:
		_apex_clamp_active = true
		_apex_clamp_is_p1 = bob_is_p1
		_apex_clamp_start_y = bob.global_position.y
		_apex_clamp_timer = maxf(apex_jump_clamp_duration, 0.0)

	# Start tug advantage (wins tug-of-war until grounded)
	_start_apex_tug_advantage(bob_is_p1)

	var out_vel: Vector2 = bob.velocity
	out_vel.y = swing_apex_jump_velocity

	if swing_apex_pop_horizontal != 0.0:
		var dir_sign: float = signf(tangent_x_sign)
		if dir_sign == 0.0:
			dir_sign = 1.0
		out_vel.x += dir_sign * swing_apex_pop_horizontal

	bob.velocity = out_vel

	_rope_current_length = max_travel_distance
	_rope_base_length = max_travel_distance
	_swing_free_timer = swing_apex_free_time
	_apex_lock_timer = swing_apex_retrigger_lock


#-----------
# APEX JUMP HEIGHT CLAMP
#-----------
func _apply_apex_jump_height_clamp(delta: float) -> void:
	if not apex_jump_height_clamp_enabled:
		_apex_clamp_active = false
		return
	if not _apex_clamp_active:
		return

	_apex_clamp_timer = maxf(_apex_clamp_timer - delta, 0.0)
	if _apex_clamp_timer <= 0.0:
		_apex_clamp_active = false
		return

	var bob: CharacterBody2D = null
	if _apex_clamp_is_p1:
		bob = player_1
	else:
		bob = player_2

	if bob == null:
		_apex_clamp_active = false
		return

	# If bob is already falling (or not going up), stop clamping early
	if bob.velocity.y >= 0.0:
		_apex_clamp_active = false
		return

	# Cap the highest point (smaller Y = higher up)
	var target_y: float = _apex_clamp_start_y - apex_jump_max_rise_px
	if bob.global_position.y < target_y:
		var gp: Vector2 = bob.global_position
		gp.y = target_y
		bob.global_position = gp

		# Kill upward velocity so we don't keep shoving into the cap
		var v: Vector2 = bob.velocity
		if v.y < 0.0:
			v.y = 0.0
		bob.velocity = v


#-----------
# APEX DETECTION (tangential sign flip near slow speeds)
#-----------
func _check_apex_tangent_flip(bob_is_p1: bool, tangent_speed: float) -> bool:
	if absf(tangent_speed) > swing_apex_speed_threshold:
		if bob_is_p1:
			_p1_prev_tangent = tangent_speed
			_p1_tangent_init = true
		else:
			_p2_prev_tangent = tangent_speed
			_p2_tangent_init = true
		return false

	if bob_is_p1:
		if not _p1_tangent_init:
			_p1_tangent_init = true
			_p1_prev_tangent = tangent_speed
			return false

		var prev: float = _p1_prev_tangent
		_p1_prev_tangent = tangent_speed
		return (prev > 0.0 and tangent_speed < 0.0) or (prev < 0.0 and tangent_speed > 0.0)

	# bob is p2
	if not _p2_tangent_init:
		_p2_tangent_init = true
		_p2_prev_tangent = tangent_speed
		return false

	var prev2: float = _p2_prev_tangent
	_p2_prev_tangent = tangent_speed
	return (prev2 > 0.0 and tangent_speed < 0.0) or (prev2 < 0.0 and tangent_speed > 0.0)


#-----------
# INPUT HELPERS
#-----------
func _get_bob_horizontal_input(bob_is_p1: bool) -> float:
	if bob_is_p1:
		return signf(player_1.velocity.x)
	return signf(player_2.velocity.x)


func _get_bob_vertical_input(bob_is_p1: bool) -> float:
	var up: bool = false
	var down: bool = false

	if bob_is_p1:
		up = Input.is_action_pressed("P1_up") or Input.is_action_pressed("both_up")
		down = Input.is_action_pressed("P1_down") or Input.is_action_pressed("both_down")
	else:
		up = Input.is_action_pressed("P2_up") or Input.is_action_pressed("both_up")
		down = Input.is_action_pressed("P2_down") or Input.is_action_pressed("both_down")

	if up and not down:
		return -1.0
	if down and not up:
		return 1.0
	return 0.0


#-----------
# ROPE (TUG-OF-WAR FEEL) - MARKER-STRICT + LOCK SUPPORT
#   Apex jumper "wins" tug-of-war until grounded again.
#-----------
func _apply_tug_of_war_rope(delta: float) -> void:
	var p1: Vector2 = p_1_mindistance_marker_2d.global_position
	var p2: Vector2 = p_2_mindistance_marker_2d.global_position

	var delta_vec: Vector2 = p2 - p1
	var dist: float = delta_vec.length()
	if dist <= 0.0001 or dist <= max_travel_distance:
		return

	var dir: Vector2 = delta_vec / dist
	var excess: float = dist - max_travel_distance

	var p1_locked: bool = player_1.has_method("is_movement_locked") and player_1.is_movement_locked()
	var p2_locked: bool = player_2.has_method("is_movement_locked") and player_2.is_movement_locked()

	var share1: float = 0.5
	var share2: float = 0.5

	# Hard overrides first: movement lock
	if p1_locked and not p2_locked:
		share1 = 0.0
		share2 = 1.0
	elif p2_locked and not p1_locked:
		share1 = 1.0
		share2 = 0.0
	else:
		# Normal weighting / brace bias
		var w1: float = 1.0
		var w2: float = 1.0

		if brace_bias_enabled:
			if player_1.is_on_floor():
				w1 += grounded_brace_bonus
			if player_2.is_on_floor():
				w2 += grounded_brace_bonus

			var sign_x_1: float = signf(player_1.velocity.x)
			var sign_x_2: float = signf(player_2.velocity.x)

			var p1_pushing_away: bool = (sign_x_1 != 0.0) and (sign_x_1 == -signf(dir.x))
			var p2_pushing_away: bool = (sign_x_2 != 0.0) and (sign_x_2 == signf(dir.x))

			if p1_pushing_away:
				w1 += input_brace_bonus
			if p2_pushing_away:
				w2 += input_brace_bonus

		w1 = maxf(w1, min_weight)
		w2 = maxf(w2, min_weight)

		var inv1: float = 1.0 / w1
		var inv2: float = 1.0 / w2
		var inv_sum: float = inv1 + inv2

		share1 = inv1 / inv_sum
		share2 = inv2 / inv_sum

	# Apex tug advantage override (unless someone is movement-locked)
	if _apex_tug_adv_active and (not p1_locked) and (not p2_locked):
		var s: float = clampf(apex_tug_win_strength, 0.0, 1.0)
		if _apex_tug_adv_is_p1:
			# P1 wins => P2 takes more correction
			share1 = share1 * (1.0 - s)
			share2 = 1.0 - share1
		else:
			# P2 wins => P1 takes more correction
			share2 = share2 * (1.0 - s)
			share1 = 1.0 - share2

	# Hard clamp
	if hard_rope_enabled and dist > (max_travel_distance + hard_rope_slack):
		var hard_excess: float = dist - max_travel_distance
		var snap: float = minf(hard_excess, hard_rope_max_snap)

		if share1 > 0.0:
			var p1_target: Vector2 = p1 + dir * (snap * share1)
			_set_player_pos_from_marker(player_1, p_1_mindistance_marker_2d, p1_target)
		if share2 > 0.0:
			var p2_target: Vector2 = p2 - dir * (snap * share2)
			_set_player_pos_from_marker(player_2, p_2_mindistance_marker_2d, p2_target)

		# Recompute after clamp
		p1 = p_1_mindistance_marker_2d.global_position
		p2 = p_2_mindistance_marker_2d.global_position
		delta_vec = p2 - p1
		dist = delta_vec.length()
		if dist <= 0.0001 or dist <= max_travel_distance:
			return

		dir = delta_vec / dist
		excess = dist - max_travel_distance

	# Soft spring correction
	var desired_step: float = excess * rope_strength * delta
	var step: float = minf(desired_step, max_position_correction)

	if share1 > 0.0:
		var p1_marker_target: Vector2 = p1 + dir * (step * share1)
		_set_player_pos_from_marker(player_1, p_1_mindistance_marker_2d, p1_marker_target)
	if share2 > 0.0:
		var p2_marker_target: Vector2 = p2 - dir * (step * share2)
		_set_player_pos_from_marker(player_2, p_2_mindistance_marker_2d, p2_marker_target)

	# Velocity correction
	var v1: Vector2 = player_1.velocity
	var v2: Vector2 = player_2.velocity
	var rel_speed_along: float = (v2 - v1).dot(dir)

	var correction_speed: float = (excess * rope_strength) - (rel_speed_along * rope_damping)
	correction_speed = clampf(correction_speed, 0.0, max_correction_speed)
	var correction_vel: Vector2 = dir * correction_speed

	if share1 > 0.0:
		player_1.velocity += correction_vel * share1
	if share2 > 0.0:
		player_2.velocity -= correction_vel * share2

	# Perpendicular damping
	if perpendicular_damping > 0.0:
		var perp: Vector2 = Vector2(-dir.y, dir.x)

		if share1 > 0.0:
			var v1_perp: float = player_1.velocity.dot(perp)
			player_1.velocity -= perp * (v1_perp * perpendicular_damping)

		if share2 > 0.0:
			var v2_perp: float = player_2.velocity.dot(perp)
			player_2.velocity -= perp * (v2_perp * perpendicular_damping)


#-----------
# CAMERA FRAMING
#-----------
func _update_camera(delta: float) -> void:
	var p1: Vector2 = p_1_mindistance_marker_2d.global_position
	var p2: Vector2 = p_2_mindistance_marker_2d.global_position

	var target_pos: Vector2 = (p1 + p2) * 0.5
	main_camera_2d.global_position = main_camera_2d.global_position.lerp(
		target_pos,
		clamp(delta * position_smooth, 0.0, 1.0)
	)

	if players_distance < close_distance_threshold:
		var close_zoom: Vector2 = Vector2(max_zoom, max_zoom)
		main_camera_2d.zoom = main_camera_2d.zoom.lerp(
			close_zoom,
			clamp(delta * zoom_smooth, 0.0, 1.0)
		)
		return

	var rect: Rect2 = Rect2(p1, Vector2.ZERO).expand(p2)
	rect.position -= camera_padding
	rect.size += camera_padding * 2.0

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var zoom_x: float = viewport_size.x / maxf(rect.size.x, 1.0)
	var zoom_y: float = viewport_size.y / maxf(rect.size.y, 1.0)
	var desired_zoom: float = minf(zoom_x, zoom_y)
	desired_zoom = clamp(desired_zoom, min_zoom, max_zoom)

	var target_zoom: Vector2 = Vector2(desired_zoom, desired_zoom)
	main_camera_2d.zoom = main_camera_2d.zoom.lerp(
		target_zoom,
		clamp(delta * zoom_smooth, 0.0, 1.0)
	)
