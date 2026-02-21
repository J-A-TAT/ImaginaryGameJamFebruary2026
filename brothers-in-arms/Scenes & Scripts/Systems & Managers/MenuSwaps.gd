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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
