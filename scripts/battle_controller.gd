class_name BattleController
extends Node

## Battle scene controller - manages the complete battle flow.
## Handles deck, hand, selection, play, scoring, and victory/defeat.

## Game state enum
enum GameState {
	INIT,           ## Initializing the stage
	PLAYER_TURN,    ## Player is selecting and playing cards
	VICTORY,        ## Player reached target score
	DEFEAT,         ## Turns exhausted without reaching target
}

## Preload the card display scene
const CardDisplayScene = preload("res://scenes/card_display.tscn")

## Current game state
var _current_state: GameState = GameState.INIT

## Current stage configuration
var stage_config: StageConfig = null

## The deck of cards
var _deck: Deck = null

## Cards in player's hand (max 8 by default)
var _hand: Array[CardData] = []

## Currently selected cards (max 5)
var _selected_cards: Array[CardData] = []

## Cumulative score for this stage
var _current_score: int = 0

## Remaining turns/rounds
var _remaining_turns: int = 0

## Card display nodes currently in hand area
var _hand_card_displays: Array[CardDisplay] = []

## Card display nodes in play area (for preview)
var _play_card_displays: Array[CardDisplay] = []

# UI Node references
@onready var _info_panel: HBoxContainer = $BattleUI/InfoPanel
@onready var _stage_label: Label = $BattleUI/InfoPanel/StageLabel
@onready var _target_score_label: Label = $BattleUI/InfoPanel/TargetScoreLabel
@onready var _current_score_label: Label = $BattleUI/InfoPanel/CurrentScoreLabel
@onready var _remaining_turns_label: Label = $BattleUI/InfoPanel/RemainingTurnsLabel
@onready var _blind_type_label: Label = $BattleUI/InfoPanel/BlindTypeLabel

@onready var _game_area: VBoxContainer = $BattleUI/GameArea
@onready var _play_zone: Panel = $BattleUI/GameArea/PlayZone
@onready var _selected_cards_container: HBoxContainer = $BattleUI/GameArea/PlayZone/SelectedCardsContainer
@onready var _hand_type_label: Label = $BattleUI/GameArea/PlayZone/HandTypeLabel
@onready var _score_preview_label: Label = $BattleUI/GameArea/PlayZone/ScorePreviewLabel

@onready var _hand_area: ScrollContainer = $BattleUI/GameArea/HandArea
@onready var _hand_container: HBoxContainer = $BattleUI/GameArea/HandArea/HandContainer

@onready var _action_bar: HBoxContainer = $BattleUI/ActionBar
@onready var _play_button: Button = $BattleUI/ActionBar/PlayButton
@onready var _discard_button: Button = $BattleUI/ActionBar/DiscardButton
@onready var _reset_button: Button = $BattleUI/ActionBar/ResetButton
@onready var _status_label: Label = $BattleUI/ActionBar/StatusLabel

@onready var _result_panel: Panel = $BattleUI/ResultPanel
@onready var _result_label: Label = $BattleUI/ResultPanel/ResultLabel
@onready var _final_score_label: Label = $BattleUI/ResultPanel/FinalScoreLabel


func _ready() -> void:
	# Initialize UI button connections
	_play_button.pressed.connect(_on_play_button_pressed)
	_discard_button.pressed.connect(_on_discard_button_pressed)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	
	# Hide result panel initially
	_result_panel.visible = false
	
	# Load default stage (stage_1)
	var default_stage: StageConfig = load("res://resources/stages/stage_1.tres") as StageConfig
	if default_stage:
		setup_stage(default_stage)
	else:
		push_error("Failed to load default stage")
		_status_label.text = "错误：无法加载关卡"


## Setup the battle with a stage configuration
func setup_stage(config: StageConfig) -> void:
	if not config or not config.is_valid():
		push_error("Invalid stage configuration")
		return
	
	stage_config = config
	_current_state = GameState.INIT
	
	# Initialize game state
	_current_score = 0
	_remaining_turns = config.max_turns
	
	# Initialize deck
	_deck = Deck.new()
	_deck.shuffle()
	
	# Clear existing hand and selection
	_hand.clear()
	_selected_cards.clear()
	
	# Clear UI
	_clear_hand_display()
	_clear_play_display()
	
	# Draw initial hand
	draw_initial_hand()
	
	# Update all UI displays
	update_info_display()
	update_selection_display()
	update_button_states()
	
	# Enter player turn state
	_current_state = GameState.PLAYER_TURN
	_status_label.text = "选择卡牌出牌"
	
	print("Stage setup complete: %s" % config.display_name)


## Draw the initial hand (8 cards by default)
func draw_initial_hand() -> void:
	var initial_count: int = stage_config.initial_hand_size
	_hand = _deck.draw_cards(initial_count)
	update_hand_display()
	print("Drawn initial hand: %d cards" % _hand.size())


## Draw additional cards to fill hand
func draw_cards_to_fill(count: int) -> void:
	if _deck.is_empty():
		push_warning("Deck is empty, cannot draw more cards")
		return
	
	var cards_to_draw: int = min(count, _deck.get_remaining_count())
	var new_cards: Array[CardData] = _deck.draw_cards(cards_to_draw)
	_hand.append_array(new_cards)
	update_hand_display()
	print("Drawn %d new cards, hand size: %d" % [cards_to_draw, _hand.size()])


## Update the hand display area
func update_hand_display() -> void:
	_clear_hand_display()
	
	for card: CardData in _hand:
		var card_display: CardDisplay = CardDisplayScene.instantiate() as CardDisplay
		card_display.setup(card)
		card_display.card_clicked.connect(_on_card_clicked)
		
		# Update selection visual based on current state
		card_display.is_selected = card in _selected_cards
		
		_hand_container.add_child(card_display)
		_hand_card_displays.append(card_display)


## Clear all card displays from hand area
func _clear_hand_display() -> void:
	for card_display: CardDisplay in _hand_card_displays:
		if card_display and is_instance_valid(card_display):
			# Disconnect signal before freeing
			if card_display.card_clicked.is_connected(_on_card_clicked):
				card_display.card_clicked.disconnect(_on_card_clicked)
			card_display.queue_free()
	_hand_card_displays.clear()


## Clear all card displays from play area
func _clear_play_display() -> void:
	for card_display: CardDisplay in _play_card_displays:
		if card_display and is_instance_valid(card_display):
			card_display.queue_free()
	_play_card_displays.clear()


## Handle card click from hand
func _on_card_clicked(card: CardData) -> void:
	if _current_state != GameState.PLAYER_TURN:
		return
	
	toggle_card_selection(card)


## Toggle a card's selection state
func toggle_card_selection(card: CardData) -> void:
	if card in _selected_cards:
		# Deselect
		_selected_cards.erase(card)
	else:
		# Select if under limit
		if _selected_cards.size() < stage_config.max_selection_size:
			_selected_cards.append(card)
		else:
			# Already at max selection, show hint
			_status_label.text = "最多选择 %d 张牌" % stage_config.max_selection_size
			return
	
	# Update visual state for all hand cards
	for card_display: CardDisplay in _hand_card_displays:
		card_display.is_selected = card_display.card_data in _selected_cards
	
	# Update play area preview
	update_selection_display()
	update_button_states()


## Update the play area display (selected cards and preview)
func update_selection_display() -> void:
	_clear_play_display()
	
	if _selected_cards.is_empty():
		_hand_type_label.text = "选择卡牌出牌"
		_score_preview_label.text = ""
		_status_label.text = "点击卡牌选择"
		return
	
	# Show selected cards in play area
	for card: CardData in _selected_cards:
		var card_display: CardDisplay = CardDisplayScene.instantiate() as CardDisplay
		card_display.setup(card)
		card_display.is_selectable = false  # Play area cards are not clickable
		_selected_cards_container.add_child(card_display)
		_play_card_displays.append(card_display)
	
	# Evaluate hand type
	var hand_result: HandType.HandResult = HandClassifier.evaluate(_selected_cards)
	
	# Calculate score
	var score: int = ScoreCalculator.calculate_score(hand_result, stage_config.blind_type)
	
	# Update labels
	if hand_result.is_valid:
		_hand_type_label.text = hand_result.get_display_name_cn()
		_score_preview_label.text = "预计得分: %d" % score
	else:
		_hand_type_label.text = "高牌"
		_score_preview_label.text = "预计得分: %d" % score
	
	_status_label.text = "%s - %d 分" % [hand_result.get_display_name_cn(), score]


## Update the info panel display
func update_info_display() -> void:
	if not stage_config:
		return
	
	_stage_label.text = stage_config.display_name
	_target_score_label.text = "目标: %d" % stage_config.get_target_score()
	_current_score_label.text = "得分: %d" % _current_score
	_remaining_turns_label.text = "回合: %d" % _remaining_turns
	_blind_type_label.text = BlindType.get_display_name_cn(stage_config.blind_type)


## Update button enabled/disabled states
func update_button_states() -> void:
	# Play button: enabled when 1-5 cards selected and in PLAYER_TURN state
	var can_play: bool = _current_state == GameState.PLAYER_TURN and \
	                     not _selected_cards.is_empty() and \
	                     _selected_cards.size() <= stage_config.max_selection_size
	_play_button.disabled = not can_play
	
	# Discard button: enabled when cards selected and in PLAYER_TURN state
	var can_discard: bool = _current_state == GameState.PLAYER_TURN and \
	                        not _selected_cards.is_empty()
	_discard_button.disabled = not can_discard
	
	# Reset button: always enabled (for retry)
	_reset_button.disabled = false


## Handle play button click
func _on_play_button_pressed() -> void:
	if _current_state != GameState.PLAYER_TURN:
		return
	
	if _selected_cards.is_empty():
		_status_label.text = "请先选择卡牌"
		return
	
	play_cards()


## Play the selected cards
func play_cards() -> void:
	# Evaluate hand type
	var hand_result: HandType.HandResult = HandClassifier.evaluate(_selected_cards)
	
	# Calculate score
	var score: int = ScoreCalculator.calculate_score(hand_result, stage_config.blind_type)
	
	# Update cumulative score
	_current_score += score
	
	# Decrease turns
	_remaining_turns -= 1
	
	# Print play result
	print("Played %s for %d points (total: %d/%d)" % [
		hand_result.get_display_name_cn(), score, _current_score, stage_config.get_target_score()
	])
	
	# Remove played cards from hand
	for card: CardData in _selected_cards:
		_hand.erase(card)
		_deck.discard(card)
	
	# Clear selection
	_selected_cards.clear()
	
	# Draw new cards to fill hand
	var cards_played: int = stage_config.max_selection_size  # Rough estimate
	draw_cards_to_fill(cards_played)
	
	# Update displays
	update_info_display()
	update_selection_display()
	update_hand_display()
	update_button_states()
	
	# Check victory/defeat
	check_game_result()


## Handle discard button click
func _on_discard_button_pressed() -> void:
	if _current_state != GameState.PLAYER_TURN:
		return
	
	if _selected_cards.is_empty():
		_status_label.text = "请先选择卡牌"
		return
	
	discard_cards()


## Discard selected cards without scoring
func discard_cards() -> void:
	print("Discarded %d cards" % _selected_cards.size())
	
	# Remove cards from hand and add to discard pile
	for card: CardData in _selected_cards:
		_hand.erase(card)
		_deck.discard(card)
	
	# Clear selection
	_selected_cards.clear()
	
	# Draw new cards
	draw_cards_to_fill(stage_config.max_selection_size)
	
	# Update displays
	update_selection_display()
	update_hand_display()
	update_button_states()
	
	_status_label.text = "已弃牌，补充新卡牌"


## Check for victory or defeat
func check_game_result() -> void:
	var target: int = stage_config.get_target_score()
	
	if _current_score >= target:
		# Victory!
		show_victory()
	elif _remaining_turns <= 0:
		# Defeat - turns exhausted
		show_defeat()
	else:
		# Continue playing
		_status_label.text = "继续选择卡牌"


## Show victory screen
func show_victory() -> void:
	_current_state = GameState.VICTORY
	
	_result_panel.visible = true
	_result_label.text = "过关！"
	_result_label.add_theme_color_override("font_color", Color("#4ade80"))
	_final_score_label.text = "最终得分: %d / %d" % [_current_score, stage_config.get_target_score()]
	
	_status_label.text = "恭喜过关！点击重置再次挑战"
	
	# Disable play and discard buttons
	_play_button.disabled = true
	_discard_button.disabled = true
	
	print("VICTORY! Score: %d / Target: %d" % [_current_score, stage_config.get_target_score()])


## Show defeat screen
func show_defeat() -> void:
	_current_state = GameState.DEFEAT
	
	_result_panel.visible = true
	_result_label.text = "失败！"
	_result_label.add_theme_color_override("font_color", Color("#f87171"))
	_final_score_label.text = "最终得分: %d / %d" % [_current_score, stage_config.get_target_score()]
	
	_status_label.text = "回合耗尽。点击重置重新挑战"
	
	# Disable play and discard buttons
	_play_button.disabled = true
	_discard_button.disabled = true
	
	print("DEFEAT! Score: %d / Target: %d" % [_current_score, stage_config.get_target_score()])


## Handle reset button click
func _on_reset_button_pressed() -> void:
	reset_stage()


## Reset the current stage
func reset_stage() -> void:
	# Hide result panel
	_result_panel.visible = false
	
	# Re-setup with the same stage config
	if stage_config:
		setup_stage(stage_config)
	else:
		var default_stage: StageConfig = load("res://resources/stages/stage_1.tres") as StageConfig
		if default_stage:
			setup_stage(default_stage)