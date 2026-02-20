extends Node
class_name DepthSort2D

@export var enabled: bool = true
@export var y_offset: float = 0.0  # use this if your sprite pivot isn't at the feet
@export var z_bias: int = 0        # optional: push slightly above/below others

@export var update_mode := UpdateMode.PROCESS
enum UpdateMode { PROCESS, PHYSICS, MANUAL }

var _owner_2d: Node2D

func _ready() -> void:
	_owner_2d = get_parent() as Node2D
	if _owner_2d == null:
		push_warning("DepthSort2D must be a child of a Node2D/CharacterBody2D.")
		set_process(false)
		set_physics_process(false)
		return

	_apply()

func _process(_delta: float) -> void:
	if update_mode == UpdateMode.PROCESS:
		_apply()

func _physics_process(_delta: float) -> void:
	if update_mode == UpdateMode.PHYSICS:
		_apply()

func apply_now() -> void:
	_apply()

func _apply() -> void:
	if not enabled or _owner_2d == null:
		return

	# Global Y drives draw order: bigger Y draws in front.
	_owner_2d.z_index = int(round(_owner_2d.global_position.y + y_offset)) + z_bias
