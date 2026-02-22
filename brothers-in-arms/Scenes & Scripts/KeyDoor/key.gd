extends Node2D
class_name KeyPickup

@export var destroy_sfx_path: NodePath = NodePath("Sound/DestroySFX")
@export var disable_on_destroy: bool = true

var _destroyed: bool = false

func destroy() -> void:
	if _destroyed:
		return
	_destroyed = true

	# Optional SFX (won't crash if missing)
	var sfx: Node = get_node_or_null(destroy_sfx_path)
	if sfx != null and sfx.has_method("play"):
		sfx.call_deferred("play")

	if disable_on_destroy:
		# Turn it off immediately so it can't be picked up twice in the same frame.
		visible = false
		set_process(false)
		set_physics_process(false)
		set_process_input(false)

		# If this KeyPickup has an Area2D/CollisionShape2D under it, disable collisions too.
		for child in get_children():
			if child is CollisionObject2D:
				(child as CollisionObject2D).set_deferred("monitoring", false)
				(child as CollisionObject2D).set_deferred("monitorable", false)

	queue_free()
