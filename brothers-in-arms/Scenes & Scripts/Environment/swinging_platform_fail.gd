extends Node2D

#-----------
# COMPONENTS
#-----------
@onready var rope_start_marker_2d : Marker2D = $AnchorStaticBody2D/RopeStartMarker2D
@onready var rope_end_marker_2d : Marker2D = $PlatformRigidBody2D/RopeEndMarker2D
@onready var line_2d : Line2D = $Line2D
@onready var platform_rigid_body_2d : RigidBody2D = $PlatformRigidBody2D
@onready var pin_joint_2d : PinJoint2D = $PinJoint2D

#-----------
# TUNING (EXPORTED)
#-----------
@export_range(0.0, 1.0, 0.001) var joint_softness: float = 0.0
# Higher = settles faster (less wobble)
@export_range(0.0, 20.0, 0.1) var platform_linear_damp: float = 6.0
@export_range(0.0, 20.0, 0.1) var platform_angular_damp: float = 10.0

# Optional speed clamps (px/s)
@export var clamp_vertical_speed: bool = true
@export var max_up_speed: float = 350.0
@export var max_down_speed: float = 900.0

func _ready() -> void:
	# Rope line setup
	line_2d.clear_points()
	line_2d.add_point(Vector2.ZERO)
	line_2d.add_point(Vector2.ZERO)

	_apply_physics_tuning()

func _physics_process(_delta: float) -> void:
	# Let you tweak live in the inspector while running
	_apply_physics_tuning()

	if clamp_vertical_speed:
		var v := platform_rigid_body_2d.linear_velocity
		v.y = clamp(v.y, -max_up_speed, max_down_speed)
		platform_rigid_body_2d.linear_velocity = v

	# Draw rope (Line2D points are local)
	var start_local := line_2d.to_local(rope_start_marker_2d.global_position)
	var end_local := line_2d.to_local(rope_end_marker_2d.global_position)
	line_2d.set_point_position(0, start_local)
	line_2d.set_point_position(1, end_local)

func _apply_physics_tuning() -> void:
	# Joint “flex” control (springiness knob)
	pin_joint_2d.softness = joint_softness

	# Platform settling control
	platform_rigid_body_2d.linear_damp = platform_linear_damp
	platform_rigid_body_2d.angular_damp = platform_angular_damp
