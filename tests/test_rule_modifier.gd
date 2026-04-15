class_name TestRuleModifier
extends RefCounted

## Test runner for RuleModifier class.
## Verifies rule rewriting system works correctly with equipment.

## Run all tests
static func run_all_tests() -> bool:
	print("=== Running RuleModifier Tests ===")
	var all_passed := true
	
	all_passed = _test_rule_modifier_creation() and all_passed
	all_passed = _test_straight_min_cards() and all_passed
	all_passed = _test_hand_type_multiplier() and all_passed
	all_passed = _test_equipment_integration() and all_passed
	all_passed = _test_4_card_straight() and all_passed
	all_passed = _test_effect_trigger() and all_passed
	
	if all_passed:
		print("=== All RuleModifier tests PASSED ===")
	else:
		print("=== Some RuleModifier tests FAILED ===")
	
	return all_passed


# ============================================================================
# Helper: Create cards easily
# ============================================================================

## Create a card with specified rank and suit
static func _create_card(rank: CardData.Rank, suit: CardData.Suit) -> CardData:
	var card := CardData.new()
	card.rank = rank
	card.suit = suit
	return card


## Create an array of cards from rank/suit pairs
static func _create_cards(rank_suits: Array) -> Array[CardData]:
	var cards: Array[CardData] = []
	for pair: Array in rank_suits:
		cards.append(_create_card(pair[0], pair[1]))
	return cards


# ============================================================================
# Rule Modifier Tests
# ============================================================================

## Test RuleModifier creation and defaults
static func _test_rule_modifier_creation() -> bool:
	print("\n[TEST] RuleModifier Creation")
	var passed := true
	
	var modifier := RuleModifier.new()
	
	# Default values
	if modifier.get_straight_min_cards() != 5:
		push_error("FAIL: Default straight_min should be 5, got %d" % modifier.get_straight_min_cards())
		passed = false
	
	if modifier.get_flush_min_cards() != 5:
		push_error("FAIL: Default flush_min should be 5, got %d" % modifier.get_flush_min_cards())
		passed = false
	
	if modifier.has_active_rules():
		push_error("FAIL: New modifier should have no active rules")
		passed = false
	
	if passed:
		print("  PASS: RuleModifier creation works correctly")
	return passed


## Test straight minimum cards modification
static func _test_straight_min_cards() -> bool:
	print("\n[TEST] Straight Minimum Cards")
	var passed := true
	
	var modifier := RuleModifier.new()
	
	# Add rule for 4-card straight
	var entry := RuleModifier.RuleEntry.new(
		RuleModifier.ModifyType.STRAIGHT_MIN_CARDS,
		4,
		10,
		null
	)
	modifier.add_rule(entry)
	
	if modifier.get_straight_min_cards() != 4:
		push_error("FAIL: Modified straight_min should be 4, got %d" % modifier.get_straight_min_cards())
		passed = false
	
	if not modifier.has_active_rules():
		push_error("FAIL: Modifier should have active rules after adding")
		passed = false
	
	if modifier.get_rule_count() != 1:
		push_error("FAIL: Rule count should be 1, got %d" % modifier.get_rule_count())
		passed = false
	
	# Test clearing rules
	modifier.clear_rules()
	if modifier.has_active_rules():
		push_error("FAIL: Modifier should have no rules after clearing")
		passed = false
	
	if modifier.get_straight_min_cards() != 5:
		push_error("FAIL: Cleared modifier should return to default 5")
		passed = false
	
	if passed:
		print("  PASS: Straight minimum cards modification works correctly")
	return passed


## Test hand type multiplier modification
static func _test_hand_type_multiplier() -> bool:
	print("\n[TEST] Hand Type Multiplier")
	var passed := true
	
	var modifier := RuleModifier.new()
	
	# Base multiplier for ONE_PAIR is 2
	if modifier.get_hand_type_multiplier(HandType.Type.ONE_PAIR) != 2:
		push_error("FAIL: Default ONE_PAIR multiplier should be 2")
		passed = false
	
	# Add rule to double pair multiplier
	var entry := RuleModifier.RuleEntry.new(
		RuleModifier.ModifyType.HAND_TYPE_MULTIPLIER,
		2.0,
		5,
		null
	)
	entry.target_hand_type = HandType.Type.ONE_PAIR
	modifier.add_rule(entry)
	
	# Multiplier should now be 2 * 2 = 4
	if modifier.get_hand_type_multiplier(HandType.Type.ONE_PAIR) != 4:
		push_error("FAIL: Modified ONE_PAIR multiplier should be 4, got %d" % modifier.get_hand_type_multiplier(HandType.Type.ONE_PAIR))
		passed = false
	
	# Other hand types should remain unchanged
	if modifier.get_hand_type_multiplier(HandType.Type.STRAIGHT) != 30:
		push_error("FAIL: STRAIGHT multiplier should still be 30")
		passed = false
	
	if passed:
		print("  PASS: Hand type multiplier modification works correctly")
	return passed


## Test equipment integration
static func _test_equipment_integration() -> bool:
	print("\n[TEST] Equipment Integration")
	var passed := true
	
	var modifier := RuleModifier.new()
	
	# Load perfect_lens equipment
	var perfect_lens: EquipmentData = load("res://resources/equipment/perfect_lens.tres") as EquipmentData
	if not perfect_lens:
		push_error("FAIL: Could not load perfect_lens.tres")
		return false
	
	modifier.add_equipment_rules(perfect_lens)
	
	# Should have added a rule for straight_min_cards = 4
	if modifier.get_straight_min_cards() != 4:
		push_error("FAIL: perfect_lens should set straight_min to 4, got %d" % modifier.get_straight_min_cards())
		passed = false
	
	if not modifier.has_active_rules():
		push_error("FAIL: Modifier should have rules after adding equipment")
		passed = false
	
	# Test removing equipment rules
	modifier.remove_equipment_rules(perfect_lens)
	
	if modifier.has_active_rules():
		push_error("FAIL: Modifier should have no rules after removing equipment")
		passed = false
	
	if modifier.get_straight_min_cards() != 5:
		push_error("FAIL: straight_min should return to 5 after removing equipment")
		passed = false
	
	if passed:
		print("  PASS: Equipment integration works correctly")
	return passed


## Test 4-card straight detection with modifier
static func _test_4_card_straight() -> bool:
	print("\n[TEST] 4-Card Straight Detection")
	var passed := true
	
	# Create 4 consecutive cards: 3, 4, 5, 6
	var four_cards := _create_cards([
		[CardData.Rank.THREE, CardData.Suit.SPADES],
		[CardData.Rank.FOUR, CardData.Suit.HEARTS],
		[CardData.Rank.FIVE, CardData.Suit.DIAMONDS],
		[CardData.Rank.SIX, CardData.Suit.CLUBS]
	])
	
	# Without modifier, should not be straight
	var no_modifier_result := HandClassifier.evaluate(four_cards)
	if no_modifier_result.hand_type == HandType.Type.STRAIGHT:
		push_error("FAIL: 4 cards without modifier should NOT be STRAIGHT")
		passed = false
	
	# With modifier (straight_min = 4), should be straight
	var modifier := RuleModifier.new()
	var entry := RuleModifier.RuleEntry.new(
		RuleModifier.ModifyType.STRAIGHT_MIN_CARDS,
		4,
		10,
		null
	)
	modifier.add_rule(entry)
	
	var with_modifier_result := HandClassifier.evaluate_with_modifiers(four_cards, modifier)
	if with_modifier_result.hand_type != HandType.Type.STRAIGHT:
		push_error("FAIL: 4 cards with modifier should be STRAIGHT, got %s" % HandType.get_display_name_cn(with_modifier_result.hand_type))
		passed = false
	
	if with_modifier_result.multiplier != 30:
		push_error("FAIL: Modified straight should still have multiplier 30, got %d" % with_modifier_result.multiplier)
		passed = false
	
	if passed:
		print("  PASS: 4-card straight detection with modifier works correctly")
	return passed


## Test EffectTrigger system
static func _test_effect_trigger() -> bool:
	print("\n[TEST] EffectTrigger System")
	var passed := true
	
	# Create equipment manager
	var manager := EquipmentManager.new()
	var trigger := EffectTrigger.new(manager)
	
	# Load test equipment
	var lucky_coin: EquipmentData = load("res://resources/equipment/lucky_coin.tres") as EquipmentData
	if not lucky_coin:
		push_error("FAIL: Could not load lucky_coin.tres")
		return false
	
	# Add to inventory and equip
	manager.add_to_inventory(lucky_coin)
	var placed: bool = manager.place_equipment(lucky_coin, Vector2i(0, 0))
	
	if not placed:
		push_error("FAIL: Could not place lucky_coin")
		passed = false
	
	# Check rule modifier
	var rule_modifier: RuleModifier = trigger.get_rule_modifier()
	if rule_modifier == null:
		push_error("FAIL: EffectTrigger should have rule_modifier")
		passed = false
	
	# Trigger turn start effects
	var results: Array[EffectTrigger.EffectResult] = trigger.trigger_turn_start(1, 0)
	
	# lucky_coin should give gold_per_turn
	var found_gold_effect: bool = false
	for result: EffectTrigger.EffectResult in results:
		if result.gold_change > 0:
			found_gold_effect = true
	
	if not found_gold_effect:
		push_error("FAIL: lucky_coin should give gold at turn start")
		passed = false
	
	# Get score modifiers
	var modifiers: Dictionary = trigger.get_score_modifiers()
	if modifiers.is_empty():
		# This is expected for lucky_coin (resource type, not score type)
		print("  INFO: lucky_coin is resource type, no score modifiers expected")
	
	if passed:
		print("  PASS: EffectTrigger system works correctly")
	return passed