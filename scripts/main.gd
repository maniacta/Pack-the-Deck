class_name Main
extends Node

## Main game entry point

# UI references
@onready var _start_button: Button = $StartButton
@onready var _test_button: Button = $TestButton


func _ready() -> void:
	print("Pack the Deck - Starting...")
	
	# Connect button signals
	if _start_button:
		_start_button.pressed.connect(_on_start_button_pressed)
	if _test_button:
		_test_button.pressed.connect(_on_test_button_pressed)


## Start the game - enter battle scene
func _on_start_button_pressed() -> void:
	print("Starting game - entering battle scene...")
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


## Run tests for development verification
func _on_test_button_pressed() -> void:
	_run_tests()


func _run_tests() -> void:
	print("\n========================================")
	print("Running All Tests...")
	print("========================================")
	TestCardData.run_all_tests()
	TestHandClassifier.run_all_tests()
	TestScoreCalculator.run_all_tests()
	TestStageConfig.run_all_tests()
	TestRuleModifier.run_all_tests()
	print("========================================\n")