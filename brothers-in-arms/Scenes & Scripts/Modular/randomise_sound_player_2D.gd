extends Node2D
class_name RandomSFXPlayer2D

#-----------
# COMPONENTS
#-----------
@onready var audio_cooldown_timer: Timer = $AudioCooldownTimer

#-----------
# SETTINGS
#-----------
@export_group("Cooldown")

## If true, sound playback is blocked while the cooldown timer is running.
@export var cooldown_enabled: bool = true

## Default cooldown length (seconds) to apply when a sound successfully plays.
## If your Timer already has a Wait Time set in the inspector, you can keep this at -1 to use that.
@export var cooldown_seconds: float = -1.0

## If true, calling play_random_child() during cooldown does nothing (silent fail).
## If false, it will push_warning() when blocked.
@export var suppress_cooldown_warnings: bool = true


@export_group("Random Pitch Requirements")

## If true, each child AudioStreamPlayer2D must have the RandomPitch script (method: play_randomised_pitch).
@export var require_random_pitch_script: bool = true

## If true, only includes children that are AudioStreamPlayer2D (ignores other nodes).
@export var only_audio_children: bool = true

## If true, prints a warning for any AudioStreamPlayer2D child that has no stream assigned.
@export var warn_if_missing_stream: bool = true

## If true, prints the list of loaded child players on ready.
@export var debug_print_loaded: bool = false


#-----------
# INTERNAL
#-----------
var _players: Array[AudioStreamPlayer2D] = []


func _ready() -> void:
	_setup_cooldown_timer()
	_cache_players()


func _setup_cooldown_timer() -> void:
	if audio_cooldown_timer == null:
		push_warning("%s: AudioCooldownTimer node not found. Cooldown will be ignored." % name)
		return

	audio_cooldown_timer.one_shot = true
	audio_cooldown_timer.autostart = false

	# If you set cooldown_seconds, we drive wait_time from script.
	if cooldown_seconds > 0.0:
		audio_cooldown_timer.wait_time = cooldown_seconds


func _cache_players() -> void:
	_players.clear()

	for c in get_children():
		if only_audio_children and not (c is AudioStreamPlayer2D):
			continue

		if c is AudioStreamPlayer2D:
			var p := c as AudioStreamPlayer2D
			_players.append(p)

			if warn_if_missing_stream and p.stream == null:
				push_warning("%s: Child '%s' has no AudioStream assigned (stream is null)." % [name, p.name])

			if require_random_pitch_script and not p.has_method("play_randomised_pitch"):
				push_error("%s: Child '%s' is missing RandomPitch script (expected method: play_randomised_pitch())." % [name, p.name])

	if _players.is_empty():
		push_warning("%s: No AudioStreamPlayer2D children found." % name)

	if debug_print_loaded:
		var names: Array[String] = []
		for p in _players:
			names.append(p.name)
		print("%s loaded players: %s" % [name, ", ".join(names)])


#-----------
# COOLDOWN API
#-----------
func can_play() -> bool:
	if not cooldown_enabled:
		return true
	if audio_cooldown_timer == null:
		return true
	return audio_cooldown_timer.is_stopped()


func start_cooldown(seconds: float = -1.0) -> void:
	if not cooldown_enabled:
		return
	if audio_cooldown_timer == null:
		return

	# Decide which wait time to use
	var t: float = seconds
	if t <= 0.0:
		t = cooldown_seconds

	# If still <= 0, fall back to timer's inspector wait_time
	if t > 0.0:
		audio_cooldown_timer.wait_time = t

	audio_cooldown_timer.start()


func reset_cooldown() -> void:
	if audio_cooldown_timer != null:
		audio_cooldown_timer.stop()


#-----------
# PLAY
#-----------
## Public: Plays a random child AudioStreamPlayer2D, respecting cooldown.
## - If it has play_randomised_pitch(), uses it.
## - Otherwise falls back to play() (unless require_random_pitch_script is true).
## - Starts cooldown ONLY if something actually played.
func play_random_child(min_pitch: float = -1.0, max_pitch: float = -1.0, cooldown_override: float = -1.0) -> void:
	if not can_play():
		if not suppress_cooldown_warnings:
			push_warning("%s: play_random_child blocked by cooldown." % name)
		return

	if _players.is_empty():
		push_warning("%s: play_random_child called but no players are cached." % name)
		return

	var idx := randi_range(0, _players.size() - 1)
	var p: AudioStreamPlayer2D = _players[idx]

	if p == null:
		push_warning("%s: Randomly selected a null player reference." % name)
		return

	# Actually play
	if require_random_pitch_script:
		if not p.has_method("play_randomised_pitch"):
			push_error("%s: Selected '%s' but it has no play_randomised_pitch()." % [name, p.name])
			return
		p.call("play_randomised_pitch", min_pitch, max_pitch)
	else:
		if p.has_method("play_randomised_pitch"):
			p.call("play_randomised_pitch", min_pitch, max_pitch)
		else:
			p.call_deferred("play")

	# Start cooldown after successful trigger
	start_cooldown(cooldown_override)


#-----------
# OPTIONAL HELPERS
#-----------
func rebuild_cache() -> void:
	_cache_players()


func get_player_count() -> int:
	return _players.size()
