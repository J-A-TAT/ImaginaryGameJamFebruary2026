extends Node2D

#----------
# VARIABLES
#----------
@export var play_on_startup: bool = true
@export var randomize_start_offsets: bool = false

# If true, searches all descendants (children, grandchildren, etc).
# If false, only searches direct children.
@export var include_descendants: bool = true

#----------
# LIFECYCLE
#----------
func _ready() -> void:
	if play_on_startup:
		play_all()

#----------
# INTERNAL
#----------
func _collect_animated_sprites(root: Node) -> Array[AnimatedSprite2D]:
	var result: Array[AnimatedSprite2D] = []

	for child in root.get_children():
		if child is AnimatedSprite2D:
			result.append(child as AnimatedSprite2D)

		if include_descendants and child.get_child_count() > 0:
			result.append_array(_collect_animated_sprites(child))

	return result

#----------
# FUNCTIONS
#----------
func play_all() -> void:
	var sprites := _collect_animated_sprites(self)

	for s in sprites:
		# Plays even if invisible.
		s.play()

		if randomize_start_offsets:
			var frames := s.sprite_frames
			if frames == null:
				continue
			var anim_name := s.animation
			var frame_count := frames.get_frame_count(anim_name)
			if frame_count > 0:
				s.frame = randi() % frame_count

func stop_all() -> void:
	var sprites := _collect_animated_sprites(self)
	for s in sprites:
		s.stop()

# Backwards-compatible name
func play_animation() -> void:
	play_all()
