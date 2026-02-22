extends AudioStreamPlayer2D
# NOTE: This script must be triggered by another script.

@export_group("Random Pitch")

## Minimum pitch scale used when playing (1.0 = normal pitch).
@export var random_pitch_min: float = 0.92

## Maximum pitch scale used when playing (1.0 = normal pitch).
@export var random_pitch_max: float = 1.08

## If true, swaps min/max automatically if they’re set the wrong way round.
@export var auto_fix_min_max: bool = true


## Public: Plays this AudioStreamPlayer2D with a randomised pitch.
## Uses call_deferred to avoid timing glitches if called during physics / state changes.
func play_randomised_pitch(min_pitch: float = -1.0, max_pitch: float = -1.0) -> void:
	var min_v: float = random_pitch_min
	var max_v: float = random_pitch_max

	# Allow per-call overrides
	if min_pitch >= 0.0:
		min_v = min_pitch
	if max_pitch >= 0.0:
		max_v = max_pitch

	# Safety: handle inverted ranges
	if auto_fix_min_max and min_v > max_v:
		var tmp := min_v
		min_v = max_v
		max_v = tmp

	pitch_scale = randf_range(min_v, max_v)

	# call_deferred: avoids glitches when triggered mid-frame (physics, collisions, animation swaps, etc.)
	call_deferred("play")
