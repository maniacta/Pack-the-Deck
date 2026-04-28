class_name BattleController
extends Node

## Battle scene controller - manages the complete battle flow.
## Handles deck, hand, selection, play, scoring, equipment effects, and victory/defeat.
## Now integrated with the equipment system for rule rewriting.

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

## Player gold (for shop and resource effects)
var _player_gold: int = 0

## Current turn number (for effect timing)
var _current_turn: int = 0

## Plays made in current turn (for Boss PLAY_LIMIT rule)
var _plays_this_turn: int = 0

## Equipment manager (handles backpack and equipped items)
var _equipment_manager: EquipmentManager = null

## Effect trigger system (handles equipment effect execution)
var _effect_trigger: EffectTrigger = null

## Stage manager (handles multi-stage progression)
var _stage_manager: StageManager = null

## Shop manager (handles shop generation and purchasing)
var _shop_manager: ShopManager = null

## Card display nodes currently in hand area
var _hand_card_displays: Array[CardDisplay] = []

## Card display nodes in play area (for preview)
var _play_card_displays: Array[CardDisplay] = []

# UI Node references
@onready var _info_panel: HBoxContainer = $"../BattleUI/InfoPanel"
@onready var _stage_label: Label = $"../BattleUI/InfoPanel/StageLabel"
@onready var _target_score_label: Label = $"../BattleUI/InfoPanel/TargetScoreLabel"
@onready var _current_score_label: Label = $"../BattleUI/InfoPanel/CurrentScoreLabel"
@onready var _remaining_turns_label: Label = $"../BattleUI/InfoPanel/RemainingTurnsLabel"
@onready var _blind_type_label: Label = $"../BattleUI/InfoPanel/BlindTypeLabel"

@onready var _game_area: VBoxContainer = $"../BattleUI/GameArea"
@onready var _play_zone: Panel = $"../BattleUI/GameArea/PlayZone"
@onready var _selected_cards_container: HBoxContainer = $"../BattleUI/GameArea/PlayZone/SelectedCardsContainer"
@onready var _hand_type_label: Label = $"../BattleUI/GameArea/PlayZone/HandTypeLabel"
@onready var _score_preview_label: Label = $"../BattleUI/GameArea/PlayZone/ScorePreviewLabel"

@onready var _hand_area: ScrollContainer = $"../BattleUI/GameArea/HandArea"
@onready var _hand_container: HBoxContainer = $"../BattleUI/GameArea/HandArea/HandContainer"

@onready var _action_bar: HBoxContainer = $"../BattleUI/ActionBar"
@onready var _play_button: Button = $"../BattleUI/ActionBar/PlayButton"
@onready var _discard_button: Button = $"../BattleUI/ActionBar/DiscardButton"
@onready var _reset_button: Button = $"../BattleUI/ActionBar/ResetButton"
@onready var _status_label: Label = $"../BattleUI/ActionBar/StatusLabel"

@onready var _result_panel: Panel = $"../ResultPanel"
@onready var _result_label: Label = $"../ResultPanel/ResultLabel"
@onready var _score_info_label: Label = $"../ResultPanel/ScoreInfoLabel"
@onready var _reward_info_label: Label = $"../ResultPanel/RewardInfoLabel"
@onready var _gold_info_label: Label = $"../ResultPanel/GoldInfoLabel"
@onready var _next_stage_button: Button = $"../ResultPanel/ButtonContainer/NextStageButton"
@onready var _shop_button: Button = $"../ResultPanel/ButtonContainer/ShopButton"
@onready var _retry_button: Button = $"../ResultPanel/ButtonContainer/RetryButton"

@onready var _backpack_button: Button = $"../BattleUI/ActionBar/BackpackButton"
@onready var _backpack_panel: BackpackPanel = $"../BackpackPanel"

@onready var _shop_scene: ShopController = $"../ShopScene"


func _ready() -> void:
	# Initialize stage manager
	_stage_manager = StageManager.new()
	
	# Initialize shop manager
	_shop_manager = ShopManager.new()
	
	# Initialize UI button connections
	_play_button.pressed.connect(_on_play_button_pressed)
	_discard_button.pressed.connect(_on_discard_button_pressed)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	
	# Initialize result panel button connections
	_next_stage_button.pressed.connect(_on_next_stage_button_pressed)
	_shop_button.pressed.connect(_on_shop_button_pressed)
	_retry_button.pressed.connect(_on_retry_button_pressed)
	
	# Initialize backpack panel
	_backpack_button.pressed.connect(_on_backpack_button_pressed)
	_backpack_panel.equipment_place_requested.connect(_on_equipment_place_from_panel)
	_backpack_panel.equipment_remove_requested.connect(_on_equipment_remove_from_panel)
	_backpack_panel.panel_closed.connect(_on_backpack_panel_closed)
	
	# Initialize shop scene signals
	_shop_scene.purchase_requested.connect(_on_shop_purchase_requested)
	_shop_scene.refresh_requested.connect(_on_shop_refresh_requested)
	_shop_scene.shop_closed.connect(_on_shop_closed)
	_shop_scene.continue_requested.connect(_on_shop_continue_requested)
	
	# Hide result panel, backpack panel, and shop scene initially
	_result_panel.visible = false
	_backpack_panel.visible = false
	_shop_scene.visible = false
	
	# Start new game (load first stage)
	var first_stage: StageConfig = _stage_manager.start_game()
	if first_stage:
		setup_stage(first_stage)
	else:
		push_error("无法加载第一关")
		_status_label.text = "错误：无法加载关卡"


## Load stage from resource or create default programmatically
func _load_or_create_default_stage() -> StageConfig:
	# Try loading from resource file first
	var loaded: Resource = load("res://resources/stages/stage_1.tres")
	if loaded and loaded is StageConfig:
		return loaded as StageConfig
	
	# Fallback: create default stage programmatically
	push_warning("无法加载 stage_1.tres，正在程序化创建默认关卡")
	var stage := StageConfig.new()
	stage.stage_id = "stage_1"
	stage.display_name = "第一关 - 入门"
	stage.base_target_score = 100
	stage.max_turns = 3
	stage.blind_type = BlindType.Type.SMALL_BLIND
	stage.boss_rule = StageConfig.BossRule.NONE
	stage.base_reward = 10
	stage.initial_hand_size = 8
	stage.max_hand_size = 8
	stage.max_selection_size = 5
	return stage


## Setup the battle with a stage configuration
func setup_stage(config: StageConfig) -> void:
	if not config or not config.is_valid():
		push_error("无效的关卡配置")
		return
	
	stage_config = config
	_current_state = GameState.INIT
	
	# Initialize game state
	_current_score = 0
	_remaining_turns = config.max_turns
	_current_turn = 0
	_plays_this_turn = 0
	_player_gold = 0
	
	# Initialize deck
	_deck = Deck.new()
	_deck.shuffle()
	
	# Initialize equipment system
	_initialize_equipment_system()
	
	# Clear existing hand and selection
	_hand.clear()
	_selected_cards.clear()
	
	# Clear UI
	_clear_hand_display()
	_clear_play_display()
	
	# Draw initial hand
	draw_initial_hand()
	
	# Trigger turn start effects
	_trigger_turn_start_effects()
	
	# Update all UI displays
	update_info_display()
	update_selection_display()
	update_button_states()
	
	# Enter player turn state
	_current_state = GameState.PLAYER_TURN
	
	# Show initial status with gold and boss rule hint
	var status_parts: Array[String] = []
	if _stage_manager:
		status_parts.append("金币: %d" % _stage_manager.get_player_gold())
	status_parts.append("选择卡牌出牌")
	_status_label.text = " | ".join(status_parts)
	
	print("关卡设置完成: %s" % config.display_name)


## Initialize equipment system
func _initialize_equipment_system() -> void:
	# Create equipment manager
	if _equipment_manager == null:
		_equipment_manager = EquipmentManager.new()
	
	# Create effect trigger system
	var is_new_trigger: bool = _effect_trigger == null
	if is_new_trigger:
		_effect_trigger = EffectTrigger.new(_equipment_manager)
	else:
		_effect_trigger.set_equipment_manager(_equipment_manager)
	
	# Connect to effect triggers for UI updates (only for new instances)
	if is_new_trigger:
		_effect_trigger.effect_triggered.connect(_on_effect_triggered)
		_effect_trigger.rules_updated.connect(_on_rules_updated)
	
	# Clear existing equipment (fresh start)
	_equipment_manager.clear()
	
	# Add test equipment for demonstration (in real game, loaded from save/shop)
	_add_test_equipment()
	
	print("装备系统初始化完成")


## Add test equipment for demonstration
func _add_test_equipment() -> void:
	# Load the perfect_lens equipment (4-card straight rule)
	var perfect_lens: EquipmentData = load("res://resources/equipment/perfect_lens.tres") as EquipmentData
	if perfect_lens:
		_equipment_manager.add_to_inventory(perfect_lens)
		# Auto-equip for testing
		_equipment_manager.place_equipment(perfect_lens, Vector2i(0, 0))
		print("添加测试装备: %s" % perfect_lens.display_name)


## Handle effect triggered signal
func _on_effect_triggered(result: EffectTrigger.EffectResult) -> void:
	if result.message:
		print("效果触发: %s 来自 %s" % [result.message, result.source.display_name])
		_status_label.text = result.message


## Handle rules updated signal
func _on_rules_updated() -> void:
	# Update selection display to reflect new rules
	update_selection_display()
	print("规则已更新")


## Trigger turn start effects
func _trigger_turn_start_effects() -> void:
	if _effect_trigger:
		var results: Array[EffectTrigger.EffectResult] = _effect_trigger.trigger_turn_start(
			_current_turn, _player_gold
		)
		
		# Process effect results
		for result: EffectTrigger.EffectResult in results:
			if result.gold_change != 0:
				_player_gold += result.gold_change


## Draw the initial hand (8 cards by default)
func draw_initial_hand() -> void:
	var initial_count: int = stage_config.initial_hand_size
	_hand = _deck.draw_cards(initial_count)
	update_hand_display()
	print("抽取初始手牌: %d 张" % _hand.size())


## Draw additional cards to fill hand
func draw_cards_to_fill(count: int) -> void:
	if _deck.is_empty():
		push_warning("牌堆已空，无法抽取更多卡牌")
		return
	
	var cards_to_draw: int = min(count, _deck.get_remaining_count())
	var new_cards: Array[CardData] = _deck.draw_cards(cards_to_draw)
	_hand.append_array(new_cards)
	update_hand_display()
	print("抽取 %d 张新牌，手牌数量: %d" % [cards_to_draw, _hand.size()])


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
	
	# Evaluate hand type with rule modifier
	var rule_modifier: RuleModifier = null
	if _effect_trigger:
		rule_modifier = _effect_trigger.get_rule_modifier()
	
	var hand_result: HandType.HandResult = HandClassifier.evaluate_with_modifiers(
		_selected_cards, rule_modifier
	)
	
	# Calculate score with equipment modifiers
	var score: int = _calculate_score_with_equipment(hand_result)
	
	# Update labels
	if hand_result.is_valid:
		_hand_type_label.text = hand_result.get_display_name_cn()
		_score_preview_label.text = "预计得分: %d" % score
	else:
		_hand_type_label.text = "高牌"
		_score_preview_label.text = "预计得分: %d" % score
	
	_status_label.text = "%s - %d 分" % [hand_result.get_display_name_cn(), score]


## Calculate score with equipment modifiers and boss rules
func _calculate_score_with_equipment(hand_result: HandType.HandResult) -> int:
	if not hand_result.is_valid:
		return 0
	
	# Check boss rules first
	if _check_boss_rule_invalid(hand_result):
		return 0
	
	# Get score modifiers from effect trigger
	var modifiers: Dictionary = {}
	if _effect_trigger:
		modifiers = _effect_trigger.get_score_modifiers()
	
	# Calculate base score, applying suit exclusion if applicable
	var adjusted_base_score: int = hand_result.base_score
	if stage_config.has_boss_rule() and stage_config.boss_rule == StageConfig.BossRule.SUIT_EXCLUDED:
		adjusted_base_score = _calculate_score_excluding_suit(hand_result)
	
	# Apply equipment score bonus (additive)
	var score_bonus: int = modifiers.get("score_bonus", 0)
	adjusted_base_score += score_bonus
	
	# Apply equipment multiplier bonus (multiplicative)
	var multiplier_bonus: float = modifiers.get("multiplier_bonus", 1.0)
	var adjusted_multiplier: int = int(hand_result.multiplier * multiplier_bonus)
	
	# Apply blind multiplier
	var blind_multiplier: int = BlindType.get_target_multiplier(stage_config.blind_type)
	
	# Calculate final score: base × hand_mult × blind_mult
	return adjusted_base_score * adjusted_multiplier * blind_multiplier


## Check if boss rule invalidates this hand
func _check_boss_rule_invalid(hand_result: HandType.HandResult) -> bool:
	if not stage_config.has_boss_rule():
		return false
	
	match stage_config.boss_rule:
		StageConfig.BossRule.HAND_TYPE_EXCLUDED:
			var excluded_type: int = stage_config.boss_rule_param.get("hand_type", HandType.Type.HIGH_CARD)
			if hand_result.hand_type == excluded_type:
				_status_label.text = "Boss 规则: %s 不计分" % HandType.get_display_name_cn(excluded_type)
				return true
	
	return false


## Calculate base score excluding a specific suit (for SUIT_EXCLUDED boss rule)
func _calculate_score_excluding_suit(hand_result: HandType.HandResult) -> int:
	var excluded_suit: int = stage_config.boss_rule_param.get("suit", CardData.Suit.DIAMONDS)
	var score: int = 0
	
	for card: CardData in hand_result.cards:
		if card.suit != excluded_suit:
			score += card.get_base_score()
	
	return score


## Check if player can play cards this turn (for PLAY_LIMIT boss rule)
func _can_play_this_turn() -> bool:
	if not stage_config.has_boss_rule():
		return true
	
	if stage_config.boss_rule == StageConfig.BossRule.PLAY_LIMIT:
		var limit: int = stage_config.boss_rule_param.get("limit", 3)
		if _plays_this_turn >= limit:
			_status_label.text = "Boss 规则: 本回合已出牌 %d 次（上限 %d）" % [_plays_this_turn, limit]
			return false
	
	return true


## Check hand size limit (for CARD_LIMIT boss rule)
func _check_hand_size_limit() -> void:
	if not stage_config.has_boss_rule():
		return
	
	if stage_config.boss_rule == StageConfig.BossRule.CARD_LIMIT:
		var limit: int = stage_config.boss_rule_param.get("limit", 5)
		while _hand.size() > limit:
			# Remove excess cards (discard oldest or random)
			var excess_card: CardData = _hand.pop_back()
			_deck.discard(excess_card)
			print("Boss 规则: 手牌超限，丢弃 %s" % excess_card.get_id())


## Update the info panel display
func update_info_display() -> void:
	if not stage_config:
		return
	
	_stage_label.text = stage_config.display_name
	_target_score_label.text = "目标: %d" % stage_config.get_target_score()
	_current_score_label.text = "得分: %d" % _current_score
	_remaining_turns_label.text = "回合: %d" % _remaining_turns
	
	# Show blind type with boss rule if applicable
	var blind_text: String = BlindType.get_display_name_cn(stage_config.blind_type)
	if stage_config.has_boss_rule():
		blind_text += " (" + stage_config.get_boss_rule_description() + ")"
	_blind_type_label.text = blind_text


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
	# Check play limit for boss rule
	if not _can_play_this_turn():
		return
	
	# Evaluate hand type with rule modifier
	var rule_modifier: RuleModifier = null
	if _effect_trigger:
		rule_modifier = _effect_trigger.get_rule_modifier()
	
	var hand_result: HandType.HandResult = HandClassifier.evaluate_with_modifiers(
		_selected_cards, rule_modifier
	)
	
	# Trigger play effects
	_trigger_play_effects(_selected_cards)
	
	# Calculate score with equipment modifiers and boss rules
	var score: int = _calculate_score_with_equipment(hand_result)
	
	# Trigger score effects
	_trigger_score_effects(hand_result, score)
	
	# Update cumulative score
	_current_score += score
	
	# Decrease turns
	_remaining_turns -= 1
	_current_turn += 1
	_plays_this_turn += 1
	
	# Print play result
	print("出牌 %s 得分 %d (总分: %d/%d)" % [
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
	
	# Apply hand size limit if boss rule
	_check_hand_size_limit()
	
	# Trigger turn end effects
	_trigger_turn_end_effects()
	
	# Reset plays counter for next turn
	_plays_this_turn = 0
	
	# Update displays
	update_info_display()
	update_selection_display()
	update_hand_display()
	update_button_states()
	
	# Check victory/defeat
	check_game_result()


## Trigger play effects
func _trigger_play_effects(cards: Array[CardData]) -> void:
	if _effect_trigger:
		var results: Array[EffectTrigger.EffectResult] = _effect_trigger.trigger_play_effects(cards)
		for result: EffectTrigger.EffectResult in results:
			if result.message:
				print("出牌效果: %s" % result.message)


## Trigger score effects
func _trigger_score_effects(hand_result: HandType.HandResult, score: int) -> void:
	if _effect_trigger:
		var results: Array[EffectTrigger.EffectResult] = _effect_trigger.trigger_score_effects(
			hand_result, score, stage_config.blind_type
		)
		for result: EffectTrigger.EffectResult in results:
			if result.message:
				print("得分效果: %s" % result.message)


## Trigger turn end effects
func _trigger_turn_end_effects() -> void:
	if _effect_trigger:
		var results: Array[EffectTrigger.EffectResult] = _effect_trigger.trigger_turn_end(
			_current_turn, _player_gold
		)
		for result: EffectTrigger.EffectResult in results:
			if result.gold_change != 0:
				_player_gold += result.gold_change


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
	print("弃牌 %d 张" % _selected_cards.size())
	
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


## Show victory screen with result panel
func show_victory() -> void:
	_current_state = GameState.VICTORY
	
	# Calculate reward
	var reward: int = stage_config.get_reward()
	
	# Add gold through stage manager
	if _stage_manager:
		_stage_manager.add_gold(reward)
		_player_gold = _stage_manager.get_player_gold()
	
	# Show result panel
	_result_panel.visible = true
	_result_label.text = "过关！"
	_result_label.add_theme_color_override("font_color", Color("#4ade80"))
	
	# Update score info
	_score_info_label.text = "得分: %d / %d" % [_current_score, stage_config.get_target_score()]
	
	# Update reward info
	_reward_info_label.text = "奖励: +%d 金币" % reward
	
	# Update gold info
	_gold_info_label.text = "当前金币: %d" % _player_gold
	
	# Update buttons based on game state
	var has_next: bool = _stage_manager and _stage_manager.has_next_stage()
	_next_stage_button.visible = has_next
	_next_stage_button.disabled = not has_next
	
	if has_next:
		_next_stage_button.text = "下一关"
	else:
		_next_stage_button.text = "完成"
		_next_stage_button.visible = false
	
	# Shop button (available after victory)
	_shop_button.disabled = false
	_shop_button.text = "商店"
	
	# Retry button always available
	_retry_button.disabled = false
	_retry_button.text = "重试本关"
	
	# Disable play and discard buttons
	_play_button.disabled = true
	_discard_button.disabled = true
	
	# Update status
	_status_label.text = "过关！获得 %d 金币" % reward
	
	print("胜利！得分: %d / 目标: %d, 奖励: %d 金币, 累计金币: %d" % [
		_current_score, stage_config.get_target_score(), reward, _player_gold
	])


## Handle next stage button click
func _on_next_stage_button_pressed() -> void:
	if _current_state != GameState.VICTORY:
		return
	
	advance_to_next_stage()


## Handle shop button click - open shop scene
func _on_shop_button_pressed() -> void:
	# Generate shop if needed
	if _shop_manager.shop_config == null:
		_shop_manager.generate_shop()
	
	# Get current gold for shop
	var gold: int = _stage_manager.get_player_gold() if _stage_manager else 0
	
	# Open shop
	_shop_scene.open_shop(gold, _shop_manager, _stage_manager)
	_result_panel.visible = false


## Handle backpack button click - toggle backpack panel
func _on_backpack_button_pressed() -> void:
	if _current_state != GameState.PLAYER_TURN:
		_status_label.text = "只能在玩家回合中打开背包"
		return
	
	if _backpack_panel.visible:
		# 面板已打开，关闭它
		_backpack_panel.close_panel()
	else:
		# 打开背包面板
		var gold: int = _stage_manager.get_player_gold() if _stage_manager else 0
		_backpack_panel.equipment_manager = _equipment_manager
		_backpack_panel.open_panel(gold, _stage_manager)
		_backpack_button.disabled = true
		_play_button.disabled = true
		_discard_button.disabled = true
		_reset_button.disabled = true
		_status_label.text = "背包已打开 - 管理你的装备"


## Handle backpack panel closed
func _on_backpack_panel_closed() -> void:
	_backpack_button.disabled = false
	update_button_states()
	update_info_display()
	update_selection_display()


## Handle equipment placement from backpack panel
func _on_equipment_place_from_panel(equipment: EquipmentData, position: Vector2i) -> void:
	if not _equipment_manager:
		return
	
	if _equipment_manager.place_equipment(equipment, position):
		# 规则修改器会通过 EquipmentManager 信号自动更新
		_status_label.text = "已装备: %s" % equipment.display_name
		_backpack_panel.set_status_message("已装备: %s" % equipment.display_name)
	else:
		_status_label.text = "无法放置装备到该位置"
		_backpack_panel.set_status_message("无法放置: 位置冲突或越界")


## Handle equipment removal from backpack panel
func _on_equipment_remove_from_panel(equipment: EquipmentData) -> void:
	if not _equipment_manager:
		return
	
	if _equipment_manager.unequip(equipment):
		# 规则修改器会通过 EquipmentManager 信号自动更新
		_status_label.text = "已卸下: %s" % equipment.display_name
		_backpack_panel.set_status_message("已卸下: %s" % equipment.display_name)
	else:
		_status_label.text = "无法卸下装备"


# ============================================================================
# Shop System Handlers
# ============================================================================

## Handle shop purchase request
func _on_shop_purchase_requested(item: ShopItem) -> void:
	if not _shop_manager or not _stage_manager:
		return
	
	var gold: int = _stage_manager.get_player_gold()
	
	# 检查是否可以购买
	if not item.can_purchase(gold):
		_status_label.text = "金币不足或物品已售出"
		return
	
	# 扣除金币
	if not _stage_manager.spend_gold(item.price):
		_status_label.text = "扣款失败"
		return
	gold = _stage_manager.get_player_gold()
	
	# 标记已售出
	item.mark_as_sold()
	
	# 添加装备到库存
	var equipment: EquipmentData = item.equipment
	if equipment:
		_equipment_manager.add_to_inventory(equipment)
		_status_label.text = "购买了: %s (%d 金币)" % [equipment.display_name, item.price]
	
	# 更新商店显示
	_shop_scene.player_gold = gold
	_shop_scene.update_after_purchase()
	
	print("购买: %s, 剩余金币: %d" % [equipment.display_name if equipment else "未知", gold])


## Handle shop refresh request
func _on_shop_refresh_requested() -> void:
	if not _shop_manager or not _stage_manager:
		return
	
	var gold: int = _stage_manager.get_player_gold()
	var config: ShopConfig = _shop_manager.shop_config
	
	if not config:
		return
	
	var cost: int = config.get_refresh_cost()
	
	# 检查金币是否足够（免费刷新不需要检查）
	if cost > 0 and not _stage_manager.spend_gold(cost):
		_status_label.text = "金币不足，无法刷新（需要 %d）" % cost
		return
	
	# 刷新商店
	_shop_manager.perform_refresh()
	gold = _stage_manager.get_player_gold()
	
	# 更新商店显示
	_shop_scene.player_gold = gold
	_shop_scene.update_after_refresh()
	
	if cost > 0:
		_status_label.text = "刷新商店，花费 %d 金币" % cost
	else:
		_status_label.text = "免费刷新商店"


## Handle shop closed (return to result panel)
func _on_shop_closed() -> void:
	# Return to result panel
	_result_panel.visible = true
	_status_label.text = "商店已关闭"


## Handle shop continue (proceed to next stage)
func _on_shop_continue_requested() -> void:
	if _current_state != GameState.VICTORY:
		return
	
	# Close shop
	_shop_scene.visible = false
	if _shop_manager:
		_shop_manager.close_shop()
	
	# Advance to next stage (or show victory if complete)
	if _stage_manager and _stage_manager.has_next_stage():
		advance_to_next_stage()
	elif _stage_manager and _stage_manager.is_completed():
		_status_label.text = "恭喜通关！所有关卡已完成"
	else:
		# No next stage, just reset
		_result_panel.visible = true


## Handle retry button click from result panel
func _on_retry_button_pressed() -> void:
	# Hide result panel
	_result_panel.visible = false
	
	# Re-setup current stage (retry)
	if stage_config:
		_plays_this_turn = 0
		setup_stage(stage_config)
	else:
		if _stage_manager:
			var current_stage: StageConfig = _stage_manager.load_current_stage()
			if current_stage:
				setup_stage(current_stage)


## Show defeat screen with result panel
func show_defeat() -> void:
	_current_state = GameState.DEFEAT
	
	_result_panel.visible = true
	_result_label.text = "失败！"
	_result_label.add_theme_color_override("font_color", Color("#f87171"))
	
	# Update score info
	_score_info_label.text = "得分: %d / %d (回合耗尽)" % [
		_current_score, stage_config.get_target_score()
	]
	
	# No reward on defeat
	_reward_info_label.text = "未获得奖励"
	_gold_info_label.text = "当前金币: %d" % _player_gold
	
	# No next stage button on defeat
	_next_stage_button.visible = false
	_next_stage_button.disabled = true
	
	# Shop button disabled on defeat (no shopping after losing)
	_shop_button.disabled = true
	_shop_button.text = "商店"
	
	# Retry button available
	_retry_button.disabled = false
	_retry_button.text = "重新挑战"
	
	# Disable play and discard buttons
	_play_button.disabled = true
	_discard_button.disabled = true
	
	_status_label.text = "回合耗尽，请重新挑战"
	
	print("失败！得分: %d / 目标: %d" % [_current_score, stage_config.get_target_score()])


## Handle reset button click
func _on_reset_button_pressed() -> void:
	reset_stage()


## Reset the current stage (only retry, not advance)
func reset_stage() -> void:
	# Hide result panel
	_result_panel.visible = false
	
	# Always retry current stage (not advance)
	if stage_config:
		_plays_this_turn = 0
		setup_stage(stage_config)
	else:
		# Fallback to current stage from manager
		if _stage_manager:
			var current_stage: StageConfig = _stage_manager.load_current_stage()
			if current_stage:
				setup_stage(current_stage)


## Advance to the next stage (called from result panel button)
func advance_to_next_stage() -> void:
	if not _stage_manager or not _stage_manager.has_next_stage():
		push_warning("没有下一关")
		return
	
	# Hide result panel
	_result_panel.visible = false
	
	# Complete current stage in manager (already added gold in show_victory)
	var reward: int = stage_config.get_reward()
	_stage_manager.complete_stage(_current_score, reward)
	
	# Load and setup next stage
	var next_stage: StageConfig = _stage_manager.load_current_stage()
	if next_stage:
		_plays_this_turn = 0
		setup_stage(next_stage)
		print("进入下一关: %s" % next_stage.display_name)
	else:
		push_error("无法加载下一关")
		_status_label.text = "错误：无法加载下一关"


## Check if all stages are completed (game victory)
func is_game_completed() -> bool:
	return _stage_manager and _stage_manager.is_completed()


# ============================================================================
# Equipment System Public Methods
# ============================================================================

## Get the equipment manager
func get_equipment_manager() -> EquipmentManager:
	return _equipment_manager


## Get the effect trigger system
func get_effect_trigger() -> EffectTrigger:
	return _effect_trigger


## Get the current rule modifier
func get_rule_modifier() -> RuleModifier:
	if _effect_trigger:
		return _effect_trigger.get_rule_modifier()
	return null


## Get player gold
func get_player_gold() -> int:
	return _player_gold


## Add gold to player
func add_gold(amount: int) -> void:
	_player_gold += amount


## Get active rules summary
func get_rules_summary() -> String:
	if _effect_trigger:
		return _effect_trigger.get_rules_summary()
	return "无规则改写"


## Check if any rules are active
func has_active_rules() -> bool:
	if _effect_trigger:
		return _effect_trigger.has_active_rules()
	return false


## Get equipped items count
func get_equipped_count() -> int:
	if _equipment_manager:
		return _equipment_manager.get_equipped().size()
	return 0


## Add equipment from external source (e.g., shop)
func add_equipment_to_inventory(equipment: EquipmentData) -> bool:
	if not _equipment_manager or not equipment:
		return false
	
	_equipment_manager.add_to_inventory(equipment)
	return true


## Place equipment in backpack
func place_equipment(equipment: EquipmentData, position: Vector2i) -> bool:
	if not _equipment_manager:
		return false
	
	return _equipment_manager.place_equipment(equipment, position)
