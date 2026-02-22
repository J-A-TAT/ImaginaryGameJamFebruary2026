extends CanvasLayer

#
# Variables to add all screens in Control into the script to swap based on 
# user input from button interactions.
#
@onready var title_screen = $"Control/Title Screen"
@onready var pause_menu = $"Control/Pause Menu"
@onready var tutorial_screen = $"Control/Tutorial"
@onready var credits_screen = $"Control/Credits"
@onready var base_background = $"UIBackground"

@onready var StartGame = $"StartGame"
@onready var HowToPlay = $"HowToPlay"
@onready var GoToCredits = $"GoToCredits"
@onready var ResumeGameFromPause = $"ResumeGameFromPause"
@onready var BackToTitleFromPause = $"BackToTitleFromPause"
@onready var ResumeGameFromTutorial = $"ResumeGameFromTutorial"
@onready var BackToTitleFromTutorial = $"BackToTitleFromTutorial"
@onready var ResumeGameFromCredits = $"ResumeGameFromCredits"
@onready var BackToTitleFromCredits = $"BackToTitleFromCredits"
@onready var NextFrame = $"NextFrame"

# cinematic_frames to store all of the path files for the story frames.
var cinematic_frames = [
	#TODO Replace with all path files to each of the cutscenes
	#preload(""),
	#preload(""),
	#preload(""),
	#preload(""),
	#preload(""),
	#preload(""),
	#preload(""),
	#preload(""),
	#preload("")
]
var current_frame_number = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
# Center of Screen: X.1280/2, Y.720/2
	title_screen.position = Vector2(1280/2, 720/2)
	#pause_menu.position = Vector2(1280/2, 720/2)
	#tutorial_screen.position = Vector2(1280/2, 720/2)
	#credits_screen.position = Vector2(1280/2, 720/2)
func _on_StartGame_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_screen, "position", Vector2(1920, 0), 0.5)
	#TODO: Replace title_screen with the instance of the Game
	#tween.tween_property(title_screen, "position", Vector2(1280/2, 720/2), 0.5)

func _on_GoToCredits_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_screen, "position", Vector2(1920, 0), 0.5)
	tween.tween_property(credits_screen, "position", Vector2(1280/2, 720/2), 0.5)
	
func _on_HowToPlay_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_screen, "position", Vector2(1920, 0), 0.5)
	tween.tween_property(tutorial_screen, "position", Vector2(1280/2, 720/2), 0.5)

func _on_BackToTitleFromPause_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_menu, "position", Vector2(1920, 0), 0.5)
	tween.tween_property(title_screen, "position", Vector2(1280/2, 720/2), 0.5)

func _on_BackToTitleFromTutorial_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(tutorial_screen, "position", Vector2(1920, 0), 0.5)
	tween.tween_property(title_screen, "position", Vector2(1280/2, 720/2), 0.5)

func _on_BackToTitleFromCredits_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(credits_screen, "position", Vector2(1920, 0), 0.5)
	tween.tween_property(title_screen, "position", Vector2(1280/2, 720/2), 0.5)

func _on_ResumeGameFromPaused_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_menu, "position", Vector2(1920, 0), 0.5)
	#TODO: Replace title_screen with the instance of the Game
	#tween.tween_property(title_screen, "position", Vector2(1280/2, 720/2), 0.5)

func _on_ResumeGameFromTutorial_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(tutorial_screen, "position", Vector2(1920, 0), 0.5)
	#TODO: Replace title_screen with the instance of the Game
	#tween.tween_property(title_screen, "position", Vector2(1280/2, 720/2), 0.5)

func _on_ResumeGameFromCredits_pressed():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(credits_screen, "position", Vector2(1920, 0), 0.5)
	#TODO: Replace title_screen with the instance of the Game
	#tween.tween_property(title_screen, "position", Vector2(1280/2, 720/2), 0.5)

#func _on_GameToPause_pressed():
	#var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	#TODO: Replace credits_screen with the instance of the Game & uncomment function
	#tween.tween_property(credits_screen, "position", Vector2(1920, 0), 0.5)
	#tween.tween_property(pause_menu, "position", Vector2(1280/2, 720/2), 0.5)

func start_cinematic():
	current_frame_number = 0
	$CinematicPlayerBase.texture = cinematic_frames[current_frame_number]
	$CinematicPlayerBase.show()
	
func on_NextFrame_pressed():
	current_frame_number += 1
	if (current_frame_number < cinematic_frames.size()):
		var tween = create_tween()
		tween.tween_property($CinematicPlayerBase, "modulate:a", 0, 0.2)
		tween.tween_callback(func(): $CinematicPlayerBase.texture = cinematic_frames[current_frame_number])
		tween.tween_property($CinematicPlayerBase, "modulate:a", 1, 0.2)
	else:
		end_story()

func end_story():
	$CinematicPlayerBase.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
