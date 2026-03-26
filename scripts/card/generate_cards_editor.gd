@tool
extends EditorScript

## Editor script to generate all 52 standard playing cards.
## In Godot editor: File > Run (or Ctrl+Shift+X) to execute.


func _run() -> void:
	print("=== Generating Standard 52-Card Deck ===")
	var cards := DeckGenerator.generate_all_cards()
	print("=== Generation Complete: %d cards created ===" % cards.size())