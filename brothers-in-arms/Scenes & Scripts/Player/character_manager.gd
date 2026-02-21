extends Node2D
class_name CharacterManager

#-----------
# COMPONENTS
#-----------
@onready var player_1 : Player1 = $Player1
@onready var player_2 : Player2 = $Player2

@onready var p_1_mindistance_marker_2d : Marker2D = $Player1/P1MindistanceMarker2D
@onready var p_2_mindistance_marker_2d : Marker2D = $Player2/P2MindistanceMarker2D

@onready var main_camera_2d : Camera2D = $Gameplay/MainCamera2D

# PLAYER ROPE (VISUAL)
@onready var line_2d : Line2D = $Gameplay/Line2D

#-----------
# VARIABLES (TUNING)
#-----------

@export_group("Camera")

## Extra padding (pixels) around both players when framing the camera.
@export var camera_padding: Vector2 = Vector2(220.0, 140.0)

## Minimum camera zoom (smaller = more zoomed out).
@export var min_zoom: float = 0.55

## Maximum camera zoom (larger = more zoomed in).
@export var max_zoom: float = 1.35

## How quickly the camera zoom interpolates to the target zoom (higher = snappier).
@export var zoom_smooth: float = 6.0

## How quickly the camera position interpolates to the midpoint (higher = snappier).
@export var position_smooth: float = 8.0


@export_group("Camera - Distance")

## If players are closer than this (px), camera uses max_zoom for a tighter shot.
@export var close_distance_threshold: float = 50.0


@export_group("Rope - Core")

## Maximum allowed distance (px) between rope markers before correction/pull begins.
@export var max_travel_distance: float = 260.0

## Rope positional correction strength (higher = tighter rope, less stretch).
@export var rope_strength: float = 18.0

## Rope damping against relative velocity along the rope (higher = less oscillation).
@export var rope_damping: float = 10.0

## Maximum velocity correction speed (px/s) the rope can apply along its axis.
@export var max_correction_speed: float = 520.0

## Maximum positional correction (px per physics frame) applied by the soft solver.
@export var max_position_correction: float = 30.0


@export_group("Rope - Hard Clamp")

## Enable hard clamp when rope exceeds max_travel_distance + hard_rope_slack.
@export var hard_rope_enabled: bool = true

## Allowed overshoot (px) beyond max_travel_distance before hard clamp engages.
@export var hard_rope_slack: float = 6.0

## Maximum hard-clamp snap (px per physics frame). Large values = snap all excess.
@export var hard_rope_max_snap: float = 99999.0


@export_group("Rope - Tug-of-War Bias")

## If enabled, distributes rope correction unevenly based on bracing (grounded + input).
@export var brace_bias_enabled: bool = true

## Extra brace weight when grounded (higher = grounded player moves less).
@export var grounded_brace_bonus: float = 0.35

## Extra brace weight when pushing against rope direction (higher = that player moves less).
@export var input_brace_bonus: float = 0.45

## Minimum weight used in brace calculations (prevents extreme bias/instability).
@export var min_weight: float = 0.2


@export_group("Rope - Damping")

## Damping applied to velocity perpendicular to the rope direction (reduces sideways wobble).
@export var perpendicular_damping: float = 0.10


@export_group("Rope - Midair (Dangling)")

## Enables dangling detection and midair behaviour when rope is taut.
@export var rope_midair_enabled: bool = true

## Taut threshold ratio of max_travel_distance (0.95 = taut at 95% of max).
@export var rope_midair_taut_ratio: float = 0.95

## Vertical separation (px) needed to mark the lower player as "dangling".
@export var rope_midair_fall_threshold: float = 26.0


@export_group("Swing - Arcade")

## Enables arcade pendulum swing behaviour for the dangling player.
@export var swing_enabled: bool = true

## Gravity used for swing acceleration (px/s^2). Higher = stronger pendulum pull.
@export var swing_gravity: float = 1200.0

## Multiplier on swing acceleration (1.0 = normal; >1.0 = more swing force).
@export var swing_accel: float = 1.0

## Exponential damping applied to tangential swing speed (higher = loses speed faster).
@export var swing_air_damping: float = 1.2

## Maximum tangential swing speed (px/s).
@export var swing_max_speed: float = 900.0


@export_group("Swing - Return Help")

## Minimum tangential acceleration applied when off-center to ensure return to bottom.
@export var swing_return_min_accel: float = 900.0

## Deadzone for return help; below this, minimum accel isn't forced.
@export var swing_return_deadzone: float = 0.06


@export_group("Swing - Pump")

## Allows pumping the swing using horizontal input to gain/maintain speed.
@export var swing_pump_enabled: bool = true

## Tangential acceleration (px/s^2) applied when pumping.
@export var swing_pump_accel: float = 820.0

## If true, only pumps when input matches current swing direction (more "physical").
@export var swing_pump_requires_matching_dir: bool = true

## Minimum input magnitude needed to count as pumping.
@export var swing_pump_deadzone: float = 0.2


@export_group("Swing - Apex Release")

## If true, releases at the swing turning point (direction flip) and gives free control briefly.
@export var swing_apex_release_enabled: bool = true

## Duration (seconds) of free-control window after apex release (dangling won't re-latch during this).
@export var swing_apex_free_time: float = 0.35

## If |tangential_speed| is below this when the direction flips, we count it as "apex".
@export var swing_apex_speed_threshold: float = 120.0

## Upward velocity (px/s) applied on apex release. Set this to your player's jump force (negative = up).
@export var swing_apex_jump_velocity: float = -420.0

## Optional extra horizontal velocity (px/s) added in the current swing direction on apex release.
@export var swing_apex_pop_horizontal: float = 120.0

## Minimum time (seconds) between apex releases (prevents double-triggers).
@export var swing_apex_retrigger_lock: float = 0.18


@export_group("Rope - Climb")

## Enables rope climbing while dangling using Up/Down inputs.
@export var rope_climb_enabled: bool = true

## Climb speed (px/s) used to shorten/lengthen rope while dangling (Up shortens).
@export var rope_climb_speed: float = 220.0

## Minimum rope length (px) allowed while climbing.
@export var rope_climb_min_length: float = 120.0

## Distance (px) you must climb up (shorten rope) from hang start to trigger a climb jump.
@export var rope_climb_limit: float = 90.0

## Upward velocity applied (px/s) when climb limit reached (negative = up).
@export var rope_climb_jump_force: float = -520.0

## Cooldown (seconds) after climb-jump where dangling is disabled (prevents instant re-latch).
@export var rope_climb_jump_cooldown: float = 0.15


@export_group("Debug")

## Toggle Line2D debug rope visibility.
@export var debug_line_enabled: bool = true

## Width (pixels) of the debug rope Line2D.
@export var debug_line_width: float = 3.0


var players_distance: float = 0.0

# Effective rope length used while dangling/climbing
var _rope_current_length: float = 0.0
var _rope_base_length: float = 0.0
var _climb_cooldown_timer: float = 0.0

# Free-control window after apex release
var _swing_free_timer: float = 0.0

# Apex detection state (turning point via tangential direction flip)
var _p1_prev_tangent: float = 0.0
var _p2_prev_tangent: float = 0.0
var _p1_tangent_init: bool = false
var _p2_tangent_init: bool = false
var _apex_lock_timer: float = 0.0


#-----------
# LIFECYCLE
#-----------
func _ready() -> void:
	main_camera_2d.make_current()
	process_priority = 1000

	line_2d.visible = debug_line_enabled
	line_2d.width = debug_line_width

	_rope_current_length = max_travel_distance
	_rope_base_length = max_travel_distance


func _physics_process(delta: float) -> void:
	line_2d.visible = debug_line_enabled
	line_2d.width = debug_line_width

	if _climb_cooldown_timer > 0.0:
		_climb_cooldown_timer = maxf(_climb_cooldown_timer - delta, 0.0)

	if _swing_free_timer > 0.0:
		_swing_free_timer = maxf(_swing_free_timer - delta, 0.0)

	if _apex_lock_timer > 0.0:
		_apex_lock_timer = maxf(_apex_lock_timer - delta, 0.0)

	_update_players_distance()

	_apply_tug_of_war_rope(delta)
	_update_players_distance()

	_update_rope_midair_by_height()

	if swing_enabled:
		_apply_arcade_swing_and_climb(delta)
		_update_players_distance()

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
# ROPE MID-AIR (LATCHED) — ONLY LOWER PLAYER
#-----------
func _update_rope_midair_by_height() -> void:
	if not rope_midair_enabled:
		player_1.set_rope_midair(false)
		player_2.set_rope_midair(false)
		return

	# Disable dangling during cooldowns / free-control windows
	if _climb_cooldown_timer > 0.0 or _swing_free_timer > 0.0:
		player_1.set_rope_midair(false)
		player_2.set_rope_midair(false)
		return

	var p1_dangling: bool = player_1.get_rope_midair()
	var p2_dangling: bool = player_2.get_rope_midair()

	# If already dangling, keep latched until landing.
	if p1_dangling or p2_dangling:
		if p1_dangling and player_1.is_on_floor():
			player_1.set_rope_midair(false)
		if p2_dangling and player_2.is_on_floor():
			player_2.set_rope_midair(false)

		if not player_1.get_rope_midair() and not player_2.get_rope_midair():
			_rope_current_length = max_travel_distance
			_rope_base_length = max_travel_distance
		return

	# Not currently dangling: decide whether to start dangling.
	var taut: bool = players_distance >= (max_travel_distance * rope_midair_taut_ratio)
	if not taut:
		player_1.set_rope_midair(false)
		player_2.set_rope_midair(false)
		return

	var y1: float = p_1_mindistance_marker_2d.global_position.y
	var y2: float = p_2_mindistance_marker_2d.global_position.y
	var dy: float = y1 - y2

	var start_p1_dangling := false
	var start_p2_dangling := false

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

		# init tangent trackers for new bob
		if start_p1_dangling:
			_p1_tangent_init = false
		if start_p2_dangling:
			_p2_tangent_init = false


#-----------
# ARCADEY SWING + ROPE CLIMB + APEX RELEASE (TURNING POINT) + REAL JUMP
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
	var bob_is_p1: bool = false

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

	# -------------------------
	# ROPE CLIMB
	# -------------------------
	if rope_climb_enabled:
		var climb_input := _get_bob_vertical_input(bob_is_p1) # up=-1, down=+1

		var max_len_allowed := max_travel_distance
		var min_len_allowed := maxf(rope_climb_min_length, _rope_base_length - rope_climb_limit)

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

			var vel_jump := bob_player.velocity
			vel_jump.y = rope_climb_jump_force
			bob_player.velocity = vel_jump
			return
	else:
		_rope_current_length = max_travel_distance
		_rope_base_length = max_travel_distance

	# -------------------------
	# SWING PHYSICS (tangential only)
	# -------------------------
	var vel2: Vector2 = bob_player.velocity

	# Remove radial velocity (prevents stretching)
	var radial_speed: float = vel2.dot(r_hat)
	vel2 -= r_hat * radial_speed

	# Pendulum accel
	var down: Vector2 = Vector2(0.0, 1.0)
	var sin_theta: float = down.dot(tangent)
	var tangential_accel: float = swing_gravity * sin_theta * swing_accel
	if absf(sin_theta) > swing_return_deadzone:
		tangential_accel = signf(sin_theta) * maxf(absf(tangential_accel), swing_return_min_accel)

	vel2 += tangent * tangential_accel * delta

	# Pump
	if swing_pump_enabled:
		var input_dir: float = _get_bob_horizontal_input(bob_is_p1)
		if absf(input_dir) >= swing_pump_deadzone:
			var pump_sign: float = input_dir * signf(tangent.x)
			if not swing_pump_requires_matching_dir:
				vel2 += tangent * (swing_pump_accel * pump_sign) * delta
			else:
				var current_tangent_speed := vel2.dot(tangent)
				var swing_dir := signf(current_tangent_speed)
				if swing_dir == 0.0 or signf(pump_sign) == swing_dir:
					vel2 += tangent * (swing_pump_accel * pump_sign) * delta

	# Dampen/cap tangential speed
	var tangential_speed: float = vel2.dot(tangent)
	tangential_speed *= exp(-swing_air_damping * delta)
	tangential_speed = clampf(tangential_speed, -swing_max_speed, swing_max_speed)

	# -------------------------
	# APEX RELEASE: detect turning point by tangential direction flip
	# -------------------------
	if swing_apex_release_enabled and _apex_lock_timer <= 0.0:
		if _check_apex_tangent_flip(bob_is_p1, tangential_speed):
			# release rope midair -> gravity will apply again in Player script
			if bob_is_p1:
				player_1.set_rope_midair(false)
			else:
				player_2.set_rope_midair(false)

			# real jump
			var out_vel := bob_player.velocity
			out_vel.y = swing_apex_jump_velocity

			# optional directional shove (use tangent.x sign)
			if swing_apex_pop_horizontal != 0.0:
				var dir_sign := signf(tangent.x)
				if dir_sign == 0.0:
					dir_sign = 1.0
				out_vel.x += dir_sign * swing_apex_pop_horizontal

			bob_player.velocity = out_vel

			_rope_current_length = max_travel_distance
			_rope_base_length = max_travel_distance
			_swing_free_timer = swing_apex_free_time
			_apex_lock_timer = swing_apex_retrigger_lock
			return

	# Rebuild velocity
	var v_tangent: Vector2 = tangent * tangential_speed
	var v_other: Vector2 = vel2 - (tangent * vel2.dot(tangent))
	bob_player.velocity = v_other + v_tangent

	# Snap dangling marker to current rope length
	var desired_marker_pos: Vector2 = anchor_pos + (r_hat * _rope_current_length)
	_set_player_pos_from_marker(bob_player, bob_marker, desired_marker_pos)


func _check_apex_tangent_flip(bob_is_p1: bool, tangent_speed: float) -> bool:
	# Only count an apex if we're near a turning point (slow)
	if absf(tangent_speed) > swing_apex_speed_threshold:
		# still update history so we can detect flips later
		if bob_is_p1:
			_p1_prev_tangent = tangent_speed
			_p1_tangent_init = true
		else:
			_p2_prev_tangent = tangent_speed
			_p2_tangent_init = true
		return false

	# Need a previous sample to compare
	if bob_is_p1:
		if not _p1_tangent_init:
			_p1_tangent_init = true
			_p1_prev_tangent = tangent_speed
			return false

		var prev := _p1_prev_tangent
		_p1_prev_tangent = tangent_speed

		# flip = sign change across 0
		return (prev > 0.0 and tangent_speed < 0.0) or (prev < 0.0 and tangent_speed > 0.0)

	# P2
	if not _p2_tangent_init:
		_p2_tangent_init = true
		_p2_prev_tangent = tangent_speed
		return false

	var prev2 := _p2_prev_tangent
	_p2_prev_tangent = tangent_speed
	return (prev2 > 0.0 and tangent_speed < 0.0) or (prev2 < 0.0 and tangent_speed > 0.0)


func _get_bob_horizontal_input(bob_is_p1: bool) -> float:
	if bob_is_p1:
		return signf(player_1.velocity.x)
	return signf(player_2.velocity.x)


func _get_bob_vertical_input(bob_is_p1: bool) -> float:
	var up := false
	var down := false

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
# ROPE (TUG-OF-WAR FEEL) - MARKER-STRICT
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

	var share1: float = inv1 / inv_sum
	var share2: float = inv2 / inv_sum

	# Hard clamp
	if hard_rope_enabled and dist > (max_travel_distance + hard_rope_slack):
		var hard_excess := dist - max_travel_distance
		var snap := minf(hard_excess, hard_rope_max_snap)

		var p1_target := p1 + dir * (snap * share1)
		var p2_target := p2 - dir * (snap * share2)

		_set_player_pos_from_marker(player_1, p_1_mindistance_marker_2d, p1_target)
		_set_player_pos_from_marker(player_2, p_2_mindistance_marker_2d, p2_target)

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

	var p1_marker_target := p1 + dir * (step * share1)
	var p2_marker_target := p2 - dir * (step * share2)

	_set_player_pos_from_marker(player_1, p_1_mindistance_marker_2d, p1_marker_target)
	_set_player_pos_from_marker(player_2, p_2_mindistance_marker_2d, p2_marker_target)

	# Velocity correction
	var v1: Vector2 = player_1.velocity
	var v2: Vector2 = player_2.velocity
	var rel_speed_along: float = (v2 - v1).dot(dir)

	var correction_speed: float = (excess * rope_strength) - (rel_speed_along * rope_damping)
	correction_speed = clampf(correction_speed, 0.0, max_correction_speed)
	var correction_vel: Vector2 = dir * correction_speed

	player_1.velocity += correction_vel * share1
	player_2.velocity -= correction_vel * share2

	if perpendicular_damping > 0.0:
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		var v1_perp: float = player_1.velocity.dot(perp)
		var v2_perp: float = player_2.velocity.dot(perp)

		player_1.velocity -= perp * (v1_perp * perpendicular_damping)
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
