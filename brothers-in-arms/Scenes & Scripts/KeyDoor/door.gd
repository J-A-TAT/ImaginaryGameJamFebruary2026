extends Node2D
class_name Door

@onready var animation_player: AnimationPlayer = $AnimationPlayer # "default" & "open"
@onready var blocker_sb_2d: StaticBody2D = $BlockerSB2D
@onready var keycheck_area_2d: Area2D = $KeycheckArea2D

@export_group("Door")
## If true, we free the whole door at the end of the open animation (optional).
@export var destroy_after_open: bool = false

func _ready() -> void:
	if animation_player != null:
		animation_player.play("default")
	else:
		push_warning("%s: Missing AnimationPlayer at $AnimationPlayer" % name)

# -----------------------------------------
# PUBLIC API
# -----------------------------------------

## Called from AnimationPlayer (animation event track) OR from code.
## Destroys the entire door scene.
func destroy() -> void:
	queue_free()

## Opens the door:
## - disables collisions (StaticBody2D + Area2D)
## - plays the "open" animation
func open() -> void:
	_disable_collisions()
	_play_open()

## Only disables collisions (useful if you want to time the animation yourself).
func disable_collisions() -> void:
	_disable_collisions()

# -----------------------------------------
# INTERNAL
# -----------------------------------------

func _disable_collisions() -> void:
	if blocker_sb_2d != null:
		blocker_sb_2d.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		blocker_sb_2d.set_deferred("collision_layer", 0)
		blocker_sb_2d.set_deferred("collision_mask", 0)

	if keycheck_area_2d != null:
		keycheck_area_2d.set_deferred("monitoring", false)
		keycheck_area_2d.set_deferred("monitorable", false)

		# Also disable the Area's collision shapes if any exist
		for c in keycheck_area_2d.get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).set_deferred("disabled", true)
			elif c is CollisionPolygon2D:
				(c as CollisionPolygon2D).set_deferred("disabled", true)

func _play_open() -> void:
	if animation_player == null:
		return

	animation_player.play("open")

	if destroy_after_open:
		# Wait for the animation to finish, then destroy.
		# (Safe even if it gets interrupted; it will just continue when finished.)
		if not animation_player.animation_finished.is_connected(_on_anim_finished):
			animation_player.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == &"open":
		# disconnect so it doesn't fire for other animations
		if animation_player != null and animation_player.animation_finished.is_connected(_on_anim_finished):
			animation_player.animation_finished.disconnect(_on_anim_finished)
		destroy()
