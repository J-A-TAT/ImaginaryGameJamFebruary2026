extends Node2D
#----------
#COMPONENTS
#----------
@onready var animated_sprite_2d = $AnimatedSprite2D
#----------
#VARIABLES
#----------
@export var playOnStartup = true
#----------
#FUNCTIONS
#----------
func _ready():
	if playOnStartup:
		animated_sprite_2d.play()
#//This is to play the animated sprite on ready, wheteher it is visible or not.

func play_animation():
	animated_sprite_2d.play()
