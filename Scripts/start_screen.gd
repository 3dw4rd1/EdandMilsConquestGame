extends Control

## Main Menu / Start Screen
## Simple screen with button to start a new game

@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
	# Load the main game scene
	get_tree().change_scene_to_file("res://Scenes/main_game_scene.tscn")
