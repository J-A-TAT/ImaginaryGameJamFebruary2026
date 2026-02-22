extends StaticBody2D
class_name BasicHazard

# This should match what the Player checks for (Layer 7 => bit 6).
const HAZARD_LAYER_MASK: int = 1 << 6

@export_group("Hazard")
@export var knockback_force: float = 300.0

func _ready() -> void:
	# Ensure this hazard is on Physics Layer 7
	collision_layer |= HAZARD_LAYER_MASK

	# Optional: typically hazards don't need to collide with everything,
	# but they DO need to collide with the player. Leave your mask as-is
	# unless you want to restrict it.
	# collision_mask = 0

# Optional API (your Player reads this first if present)
func get_knockback_force() -> float:
	return knockback_force
