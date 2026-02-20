extends Node

# Drag this in the Inspector (0 = unlimited)
@export var fps_limit: int = 0

# Optional: show a one-line message when you apply the limit
@export var print_on_apply: bool = true

func _ready() -> void:
	_apply_fps_limit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		print("FPS: ", Engine.get_frames_per_second())

func _apply_fps_limit() -> void:
	# Godot uses 0 for "no limit"
	Engine.max_fps = max(0, fps_limit)
	if print_on_apply:
		if fps_limit <= 0:
			print("FPS limit: Unlimited")
		else:
			print("FPS limit: ", fps_limit)
