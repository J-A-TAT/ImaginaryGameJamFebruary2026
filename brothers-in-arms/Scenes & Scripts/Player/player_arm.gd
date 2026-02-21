extends Node2D
class_name PlayerArm

#-----------
# COMPONENTS
#-----------
@onready var p_1_shoulder_marker_2d : Marker2D = $P1ShoulderMarker2D
@onready var p_2_shoulder_marker_2d : Marker2D = $P2ShoulderMarker2D

@onready var p_2_shoulder : StaticBody2D = $P2Shoulder
@onready var p_1_shoulder : StaticBody2D = $P1Shoulder

#-----------
# PUBLIC API (MARKERS)
#-----------
func get_p1_shoulder_global_position() -> Vector2:
	return p_1_shoulder_marker_2d.global_position

func get_p2_shoulder_global_position() -> Vector2:
	return p_2_shoulder_marker_2d.global_position

func get_marker_global_positions() -> Dictionary:
	return {
		"p1_shoulder": p_1_shoulder_marker_2d.global_position,
		"p2_shoulder": p_2_shoulder_marker_2d.global_position
	}

#-----------
# PUBLIC API (MOVE SHOULDERS)
# Call these from your CharacterManager each frame.
#-----------
func set_p1_shoulder_global_position(pos: Vector2) -> void:
	p_1_shoulder.global_position = pos
	p_1_shoulder_marker_2d.global_position = pos

func set_p2_shoulder_global_position(pos: Vector2) -> void:
	p_2_shoulder.global_position = pos
	p_2_shoulder_marker_2d.global_position = pos

func set_shoulders_global_positions(p1_pos: Vector2, p2_pos: Vector2) -> void:
	set_p1_shoulder_global_position(p1_pos)
	set_p2_shoulder_global_position(p2_pos)

# Convenience: move shoulders using two players that expose get_shoulder_global_position()
func sync_shoulders_to_players(player1: Node, player2: Node) -> void:
	# This expects both players to implement:
	#   func get_shoulder_global_position() -> Vector2
	# (like you added to Player2)
	if player1 != null and player1.has_method("get_shoulder_global_position"):
		set_p1_shoulder_global_position(player1.call("get_shoulder_global_position") as Vector2)
	if player2 != null and player2.has_method("get_shoulder_global_position"):
		set_p2_shoulder_global_position(player2.call("get_shoulder_global_position") as Vector2)
