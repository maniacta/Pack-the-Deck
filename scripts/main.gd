class_name Main
extends Node

## Main game entry point


func _ready() -> void:
	print("Pack the Deck - Starting...")
	
	# Run card data tests on startup (for development)
	# TODO: Remove this in production
	_run_tests()


func _run_tests() -> void:
	print("\n========================================")
	print("Running CardData Tests...")
	print("========================================")
	TestCardData.run_all_tests()
	print("========================================\n")