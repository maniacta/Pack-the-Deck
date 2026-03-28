class_name TestHandClassifier
extends RefCounted

## Test runner for HandClassifier class.
## Verifies all poker hand type detection works correctly.

## Run all tests
static func run_all_tests() -> bool:
	print("=== Running HandClassifier Tests ===")
	var all_passed := true
	
	all_passed = _test_high_card() and all_passed
	all_passed = _test_one_pair() and all_passed
	all_passed = _test_two_pair() and all_passed
	all_passed = _test_three_of_a_kind() and all_passed
	all_passed = _test_straight() and all_passed
	all_passed = _test_straight_ace_low() and all_passed
	all_passed = _test_flush() and all_passed
	all_passed = _test_full_house() and all_passed
	all_passed = _test_four_of_a_kind() and all_passed
	all_passed = _test_straight_flush() and all_passed
	all_passed = _test_royal_flush() and all_passed
	all_passed = _test_edge_cases() and all_passed
	all_passed = _test_score_calculation() and all_passed
	
	if all_passed:
		print("=== All HandClassifier tests PASSED ===")
	else:
		print("=== Some HandClassifier tests FAILED ===")
	
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
# Hand Type Tests
# ============================================================================

## Test high card detection
static func _test_high_card() -> bool:
	print("\n[TEST] High Card Detection")
	var passed := true
	
	# Mixed cards, no hand type
	var cards := _create_cards([
		[CardData.Rank.THREE, CardData.Suit.SPADES],
		[CardData.Rank.SEVEN, CardData.Suit.HEARTS],
		[CardData.Rank.TEN, CardData.Suit.DIAMONDS],
		[CardData.Rank.KING, CardData.Suit.CLUBS],
		[CardData.Rank.ACE, CardData.Suit.SPADES]
	])
	
	var result := HandClassifier.evaluate(cards)
	if result.hand_type != HandType.Type.HIGH_CARD:
		push_error("FAIL: Should be HIGH_CARD, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 1:
		push_error("FAIL: High card multiplier should be 1, got %d" % result.multiplier)
		passed = false
	
	# Single card should also be high card
	var single_card: Array[CardData] = [_create_card(CardData.Rank.ACE, CardData.Suit.SPADES)]
	var single_result := HandClassifier.evaluate(single_card)
	if single_result.hand_type != HandType.Type.HIGH_CARD:
		push_error("FAIL: Single card should be HIGH_CARD")
		passed = false
	
	if passed:
		print("  PASS: High card detection works correctly")
	return passed


## Test one pair detection
static func _test_one_pair() -> bool:
	print("\n[TEST] One Pair Detection")
	var passed := true
	
	# Valid pair: two 5s
	var pair_cards := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.HEARTS]
	])
	
	var result := HandClassifier.evaluate(pair_cards)
	if result.hand_type != HandType.Type.ONE_PAIR:
		push_error("FAIL: [黑桃5, 红心5] should be ONE_PAIR, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 2:
		push_error("FAIL: Pair multiplier should be 2, got %d" % result.multiplier)
		passed = false
	
	# Invalid pair: different ranks
	var no_pair := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.SIX, CardData.Suit.HEARTS]
	])
	
	var no_pair_result := HandClassifier.evaluate(no_pair)
	if no_pair_result.hand_type == HandType.Type.ONE_PAIR:
		push_error("FAIL: [黑桃5, 红心6] should NOT be ONE_PAIR")
		passed = false
	
	# Invalid: three cards (not a pair)
	var three_same := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.HEARTS],
		[CardData.Rank.FIVE, CardData.Suit.DIAMONDS]
	])
	
	var three_result := HandClassifier.evaluate(three_same)
	if three_result.hand_type == HandType.Type.ONE_PAIR:
		push_error("FAIL: [黑桃5, 红心5, 方块5] should NOT be ONE_PAIR (it's THREE_OF_A_KIND)")
		passed = false
	
	# Invalid: single card
	var single: Array[CardData] = [_create_card(CardData.Rank.FIVE, CardData.Suit.SPADES)]
	var single_result := HandClassifier.evaluate(single)
	if single_result.hand_type == HandType.Type.ONE_PAIR:
		push_error("FAIL: Single card should NOT be ONE_PAIR")
		passed = false
	
	if passed:
		print("  PASS: One pair detection works correctly")
	return passed


## Test two pair detection
static func _test_two_pair() -> bool:
	print("\n[TEST] Two Pair Detection")
	var passed := true
	
	# Valid two pair: 3s and 7s
	var two_pair_cards := _create_cards([
		[CardData.Rank.THREE, CardData.Suit.SPADES],
		[CardData.Rank.THREE, CardData.Suit.HEARTS],
		[CardData.Rank.SEVEN, CardData.Suit.DIAMONDS],
		[CardData.Rank.SEVEN, CardData.Suit.CLUBS]
	])
	
	var result := HandClassifier.evaluate(two_pair_cards)
	if result.hand_type != HandType.Type.TWO_PAIR:
		push_error("FAIL: [黑桃3, 红心3, 方块7, 梅花7] should be TWO_PAIR, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 3:
		push_error("FAIL: Two pair multiplier should be 3, got %d" % result.multiplier)
		passed = false
	
	# Invalid: three of same rank + one different
	var not_two_pair := _create_cards([
		[CardData.Rank.THREE, CardData.Suit.SPADES],
		[CardData.Rank.THREE, CardData.Suit.HEARTS],
		[CardData.Rank.THREE, CardData.Suit.DIAMONDS],
		[CardData.Rank.SEVEN, CardData.Suit.CLUBS]
	])
	
	var not_result := HandClassifier.evaluate(not_two_pair)
	if not_result.hand_type == HandType.Type.TWO_PAIR:
		push_error("FAIL: [黑桃3, 红心3, 方块3, 梅花7] should NOT be TWO_PAIR")
		passed = false
	
	# Invalid: only one pair
	var one_pair_only := _create_cards([
		[CardData.Rank.THREE, CardData.Suit.SPADES],
		[CardData.Rank.THREE, CardData.Suit.HEARTS],
		[CardData.Rank.SEVEN, CardData.Suit.DIAMONDS],
		[CardData.Rank.EIGHT, CardData.Suit.CLUBS]
	])
	
	var one_result := HandClassifier.evaluate(one_pair_only)
	if one_result.hand_type == HandType.Type.TWO_PAIR:
		push_error("FAIL: [黑桃3, 红心3, 方块7, 梅花8] should NOT be TWO_PAIR")
		passed = false
	
	if passed:
		print("  PASS: Two pair detection works correctly")
	return passed


## Test three of a kind detection
static func _test_three_of_a_kind() -> bool:
	print("\n[TEST] Three of a Kind Detection")
	var passed := true
	
	# Valid three of a kind: three 9s
	var three_cards := _create_cards([
		[CardData.Rank.NINE, CardData.Suit.SPADES],
		[CardData.Rank.NINE, CardData.Suit.HEARTS],
		[CardData.Rank.NINE, CardData.Suit.DIAMONDS]
	])
	
	var result := HandClassifier.evaluate(three_cards)
	if result.hand_type != HandType.Type.THREE_OF_A_KIND:
		push_error("FAIL: [黑桃9, 红心9, 方块9] should be THREE_OF_A_KIND, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 4:
		push_error("FAIL: Three of a kind multiplier should be 4, got %d" % result.multiplier)
		passed = false
	
	# Invalid: two cards same rank + one different
	var not_three := _create_cards([
		[CardData.Rank.NINE, CardData.Suit.SPADES],
		[CardData.Rank.NINE, CardData.Suit.HEARTS],
		[CardData.Rank.EIGHT, CardData.Suit.DIAMONDS]
	])
	
	var not_result := HandClassifier.evaluate(not_three)
	if not_result.hand_type == HandType.Type.THREE_OF_A_KIND:
		push_error("FAIL: [黑桃9, 红心9, 方块8] should NOT be THREE_OF_A_KIND")
		passed = false
	
	if passed:
		print("  PASS: Three of a kind detection works correctly")
	return passed


## Test straight detection (regular)
static func _test_straight() -> bool:
	print("\n[TEST] Straight Detection (Regular)")
	var passed := true
	
	# Regular straight: 2-3-4-5-6
	var straight_cards := _create_cards([
		[CardData.Rank.TWO, CardData.Suit.SPADES],
		[CardData.Rank.THREE, CardData.Suit.HEARTS],
		[CardData.Rank.FOUR, CardData.Suit.DIAMONDS],
		[CardData.Rank.FIVE, CardData.Suit.CLUBS],
		[CardData.Rank.SIX, CardData.Suit.SPADES]
	])
	
	var result := HandClassifier.evaluate(straight_cards)
	if result.hand_type != HandType.Type.STRAIGHT:
		push_error("FAIL: [2, 3, 4, 5, 6] should be STRAIGHT, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 30:
		push_error("FAIL: Straight multiplier should be 30, got %d" % result.multiplier)
		passed = false
	
	# High straight: 10-J-Q-K-A
	var high_straight := _create_cards([
		[CardData.Rank.TEN, CardData.Suit.SPADES],
		[CardData.Rank.JACK, CardData.Suit.HEARTS],
		[CardData.Rank.QUEEN, CardData.Suit.DIAMONDS],
		[CardData.Rank.KING, CardData.Suit.CLUBS],
		[CardData.Rank.ACE, CardData.Suit.SPADES]
	])
	
	var high_result := HandClassifier.evaluate(high_straight)
	if high_result.hand_type != HandType.Type.STRAIGHT:
		push_error("FAIL: [10, J, Q, K, A] should be STRAIGHT, got %s" % HandType.get_display_name_cn(high_result.hand_type))
		passed = false
	
	# Invalid straight: gap in sequence
	var not_straight := _create_cards([
		[CardData.Rank.TWO, CardData.Suit.SPADES],
		[CardData.Rank.THREE, CardData.Suit.HEARTS],
		[CardData.Rank.FOUR, CardData.Suit.DIAMONDS],
		[CardData.Rank.FIVE, CardData.Suit.CLUBS],
		[CardData.Rank.SEVEN, CardData.Suit.SPADES]
	])
	
	var not_result := HandClassifier.evaluate(not_straight)
	if not_result.hand_type == HandType.Type.STRAIGHT:
		push_error("FAIL: [2, 3, 4, 5, 7] should NOT be STRAIGHT")
		passed = false
	
	if passed:
		print("  PASS: Straight detection works correctly")
	return passed


## Test straight detection (Ace as low: A-2-3-4-5)
static func _test_straight_ace_low() -> bool:
	print("\n[TEST] Straight Detection (Ace Low)")
	var passed := true
	
	# Ace-low straight: A-2-3-4-5
	var ace_low := _create_cards([
		[CardData.Rank.ACE, CardData.Suit.SPADES],
		[CardData.Rank.TWO, CardData.Suit.HEARTS],
		[CardData.Rank.THREE, CardData.Suit.DIAMONDS],
		[CardData.Rank.FOUR, CardData.Suit.CLUBS],
		[CardData.Rank.FIVE, CardData.Suit.SPADES]
	])
	
	var result := HandClassifier.evaluate(ace_low)
	if result.hand_type != HandType.Type.STRAIGHT:
		push_error("FAIL: [A, 2, 3, 4, 5] should be STRAIGHT (Ace as low), got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	
	# Invalid: J-Q-K-A-2 (Ace cannot be both 14 and 1)
	var invalid_wrap := _create_cards([
		[CardData.Rank.JACK, CardData.Suit.SPADES],
		[CardData.Rank.QUEEN, CardData.Suit.HEARTS],
		[CardData.Rank.KING, CardData.Suit.DIAMONDS],
		[CardData.Rank.ACE, CardData.Suit.CLUBS],
		[CardData.Rank.TWO, CardData.Suit.SPADES]
	])
	
	var invalid_result := HandClassifier.evaluate(invalid_wrap)
	if invalid_result.hand_type == HandType.Type.STRAIGHT:
		push_error("FAIL: [J, Q, K, A, 2] should NOT be STRAIGHT")
		passed = false
	
	if passed:
		print("  PASS: Ace-low straight detection works correctly")
	return passed


## Test flush detection
static func _test_flush() -> bool:
	print("\n[TEST] Flush Detection")
	var passed := true
	
	# Valid flush: 5 spades
	var flush_cards := _create_cards([
		[CardData.Rank.TWO, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.SEVEN, CardData.Suit.SPADES],
		[CardData.Rank.TEN, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.SPADES]
	])
	
	var result := HandClassifier.evaluate(flush_cards)
	if result.hand_type != HandType.Type.FLUSH:
		push_error("FAIL: 5 spades should be FLUSH, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 35:
		push_error("FAIL: Flush multiplier should be 35, got %d" % result.multiplier)
		passed = false
	
	# Invalid: mixed suits
	var not_flush := _create_cards([
		[CardData.Rank.TWO, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.SEVEN, CardData.Suit.SPADES],
		[CardData.Rank.TEN, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.HEARTS]
	])
	
	var not_result := HandClassifier.evaluate(not_flush)
	if not_result.hand_type == HandType.Type.FLUSH:
		push_error("FAIL: 4 spades + 1 heart should NOT be FLUSH")
		passed = false
	
	if passed:
		print("  PASS: Flush detection works correctly")
	return passed


## Test full house detection
static func _test_full_house() -> bool:
	print("\n[TEST] Full House Detection")
	var passed := true
	
	# Valid full house: K-K-K-5-5
	var full_house := _create_cards([
		[CardData.Rank.KING, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.HEARTS],
		[CardData.Rank.KING, CardData.Suit.DIAMONDS],
		[CardData.Rank.FIVE, CardData.Suit.CLUBS],
		[CardData.Rank.FIVE, CardData.Suit.SPADES]
	])
	
	var result := HandClassifier.evaluate(full_house)
	if result.hand_type != HandType.Type.FULL_HOUSE:
		push_error("FAIL: [K, K, K, 5, 5] should be FULL_HOUSE, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 40:
		push_error("FAIL: Full house multiplier should be 40, got %d" % result.multiplier)
		passed = false
	
	# Valid: three in front, pair in back: 5-5-5-K-K
	var reverse_full := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.HEARTS],
		[CardData.Rank.FIVE, CardData.Suit.DIAMONDS],
		[CardData.Rank.KING, CardData.Suit.CLUBS],
		[CardData.Rank.KING, CardData.Suit.SPADES]
	])
	
	var reverse_result := HandClassifier.evaluate(reverse_full)
	if reverse_result.hand_type != HandType.Type.FULL_HOUSE:
		push_error("FAIL: [5, 5, 5, K, K] should be FULL_HOUSE")
		passed = false
	
	# Invalid: four of a kind + one
	var not_full := _create_cards([
		[CardData.Rank.KING, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.HEARTS],
		[CardData.Rank.KING, CardData.Suit.DIAMONDS],
		[CardData.Rank.KING, CardData.Suit.CLUBS],
		[CardData.Rank.FIVE, CardData.Suit.SPADES]
	])
	
	var not_result := HandClassifier.evaluate(not_full)
	if not_result.hand_type == HandType.Type.FULL_HOUSE:
		push_error("FAIL: [K, K, K, K, 5] should NOT be FULL_HOUSE")
		passed = false
	
	# Invalid: no three of a kind
	var no_three := _create_cards([
		[CardData.Rank.KING, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.HEARTS],
		[CardData.Rank.FIVE, CardData.Suit.DIAMONDS],
		[CardData.Rank.FIVE, CardData.Suit.CLUBS],
		[CardData.Rank.THREE, CardData.Suit.SPADES]
	])
	
	var no_three_result := HandClassifier.evaluate(no_three)
	if no_three_result.hand_type == HandType.Type.FULL_HOUSE:
		push_error("FAIL: [K, K, 5, 5, 3] should NOT be FULL_HOUSE")
		passed = false
	
	if passed:
		print("  PASS: Full house detection works correctly")
	return passed


## Test four of a kind detection
static func _test_four_of_a_kind() -> bool:
	print("\n[TEST] Four of a Kind Detection")
	var passed := true
	
	# Valid four of a kind: four Qs
	var four_cards := _create_cards([
		[CardData.Rank.QUEEN, CardData.Suit.SPADES],
		[CardData.Rank.QUEEN, CardData.Suit.HEARTS],
		[CardData.Rank.QUEEN, CardData.Suit.DIAMONDS],
		[CardData.Rank.QUEEN, CardData.Suit.CLUBS]
	])
	
	var result := HandClassifier.evaluate(four_cards)
	if result.hand_type != HandType.Type.FOUR_OF_A_KIND:
		push_error("FAIL: [黑桃Q, 红心Q, 方块Q, 梅花Q] should be FOUR_OF_A_KIND, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 60:
		push_error("FAIL: Four of a kind multiplier should be 60, got %d" % result.multiplier)
		passed = false
	
	# Invalid: three + one different
	var not_four := _create_cards([
		[CardData.Rank.QUEEN, CardData.Suit.SPADES],
		[CardData.Rank.QUEEN, CardData.Suit.HEARTS],
		[CardData.Rank.QUEEN, CardData.Suit.DIAMONDS],
		[CardData.Rank.KING, CardData.Suit.CLUBS]
	])
	
	var not_result := HandClassifier.evaluate(not_four)
	if not_result.hand_type == HandType.Type.FOUR_OF_A_KIND:
		push_error("FAIL: [黑桃Q, 红心Q, 方块Q, 梅花K] should NOT be FOUR_OF_A_KIND")
		passed = false
	
	if passed:
		print("  PASS: Four of a kind detection works correctly")
	return passed


## Test straight flush detection
static func _test_straight_flush() -> bool:
	print("\n[TEST] Straight Flush Detection")
	var passed := true
	
	# Valid straight flush: 9-10-J-Q-K all hearts
	var straight_flush := _create_cards([
		[CardData.Rank.NINE, CardData.Suit.HEARTS],
		[CardData.Rank.TEN, CardData.Suit.HEARTS],
		[CardData.Rank.JACK, CardData.Suit.HEARTS],
		[CardData.Rank.QUEEN, CardData.Suit.HEARTS],
		[CardData.Rank.KING, CardData.Suit.HEARTS]
	])
	
	var result := HandClassifier.evaluate(straight_flush)
	if result.hand_type != HandType.Type.STRAIGHT_FLUSH:
		push_error("FAIL: [红心9, 红心10, 红心J, 红心Q, 红心K] should be STRAIGHT_FLUSH, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 80:
		push_error("FAIL: Straight flush multiplier should be 80, got %d" % result.multiplier)
		passed = false
	
	# Invalid: straight but not flush (mixed suits)
	var not_sf := _create_cards([
		[CardData.Rank.TEN, CardData.Suit.SPADES],
		[CardData.Rank.JACK, CardData.Suit.HEARTS],
		[CardData.Rank.QUEEN, CardData.Suit.DIAMONDS],
		[CardData.Rank.KING, CardData.Suit.CLUBS],
		[CardData.Rank.ACE, CardData.Suit.SPADES]
	])
	
	var not_result := HandClassifier.evaluate(not_sf)
	if not_result.hand_type == HandType.Type.STRAIGHT_FLUSH:
		push_error("FAIL: [黑桃10, 红心J, 方块Q, 梅花K, 黑桃A] should NOT be STRAIGHT_FLUSH")
		passed = false
	
	if passed:
		print("  PASS: Straight flush detection works correctly")
	return passed


## Test royal flush detection
static func _test_royal_flush() -> bool:
	print("\n[TEST] Royal Flush Detection")
	var passed := true
	
	# Valid royal flush: 10-J-Q-K-A all spades
	var royal_flush := _create_cards([
		[CardData.Rank.TEN, CardData.Suit.SPADES],
		[CardData.Rank.JACK, CardData.Suit.SPADES],
		[CardData.Rank.QUEEN, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.SPADES],
		[CardData.Rank.ACE, CardData.Suit.SPADES]
	])
	
	var result := HandClassifier.evaluate(royal_flush)
	if result.hand_type != HandType.Type.ROYAL_FLUSH:
		push_error("FAIL: [黑桃10, 黑桃J, 黑桃Q, 黑桃K, 黑桃A] should be ROYAL_FLUSH, got %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 100:
		push_error("FAIL: Royal flush multiplier should be 100, got %d" % result.multiplier)
		passed = false
	
	# Invalid: 9-10-J-Q-K (not royal)
	var not_royal := _create_cards([
		[CardData.Rank.NINE, CardData.Suit.SPADES],
		[CardData.Rank.TEN, CardData.Suit.SPADES],
		[CardData.Rank.JACK, CardData.Suit.SPADES],
		[CardData.Rank.QUEEN, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.SPADES]
	])
	
	var not_royal_result := HandClassifier.evaluate(not_royal)
	if not_royal_result.hand_type == HandType.Type.ROYAL_FLUSH:
		push_error("FAIL: [9, 10, J, Q, K] same suit should be STRAIGHT_FLUSH, not ROYAL_FLUSH")
		passed = false
	if not_royal_result.hand_type != HandType.Type.STRAIGHT_FLUSH:
		push_error("FAIL: [9, 10, J, Q, K] same suit should be STRAIGHT_FLUSH")
		passed = false
	
	if passed:
		print("  PASS: Royal flush detection works correctly")
	return passed


## Test edge cases
static func _test_edge_cases() -> bool:
	print("\n[TEST] Edge Cases")
	var passed := true
	
	# Empty cards
	var empty: Array[CardData] = []
	var empty_result := HandClassifier.evaluate(empty)
	if empty_result.is_valid:
		push_error("FAIL: Empty cards should return invalid result")
		passed = false
	
	# Single card
	var single: Array[CardData] = [_create_card(CardData.Rank.ACE, CardData.Suit.SPADES)]
	var single_result := HandClassifier.evaluate(single)
	if single_result.hand_type != HandType.Type.HIGH_CARD:
		push_error("FAIL: Single card should be HIGH_CARD")
		passed = false
	
	# Less than 5 cards should not be straight/flush/full house
	var four_cards := _create_cards([
		[CardData.Rank.TWO, CardData.Suit.SPADES],
		[CardData.Rank.THREE, CardData.Suit.SPADES],
		[CardData.Rank.FOUR, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.SPADES]
	])
	
	var four_result := HandClassifier.evaluate(four_cards)
	if four_result.hand_type == HandType.Type.STRAIGHT:
		push_error("FAIL: 4 cards cannot be STRAIGHT")
		passed = false
	if four_result.hand_type == HandType.Type.FLUSH:
		push_error("FAIL: 4 cards cannot be FLUSH")
		passed = false
	
	if passed:
		print("  PASS: Edge cases handled correctly")
	return passed


## Test score calculation
static func _test_score_calculation() -> bool:
	print("\n[TEST] Score Calculation")
	var passed := true
	
	# Pair of 5s: base score = 5 + 5 = 10, multiplier = 2, total = 20
	var pair := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.HEARTS]
	])
	
	var pair_result := HandClassifier.evaluate(pair)
	if pair_result.base_score != 10:
		push_error("FAIL: Pair of 5s base score should be 10, got %d" % pair_result.base_score)
		passed = false
	if pair_result.get_total_score() != 20:
		push_error("FAIL: Pair of 5s total score should be 20, got %d" % pair_result.get_total_score())
		passed = false
	
	# Straight 2-6: base = 2+3+4+5+6 = 20, multiplier = 30, total = 600
	var straight := _create_cards([
		[CardData.Rank.TWO, CardData.Suit.SPADES],
		[CardData.Rank.THREE, CardData.Suit.HEARTS],
		[CardData.Rank.FOUR, CardData.Suit.DIAMONDS],
		[CardData.Rank.FIVE, CardData.Suit.CLUBS],
		[CardData.Rank.SIX, CardData.Suit.SPADES]
	])
	
	var straight_result := HandClassifier.evaluate(straight)
	if straight_result.base_score != 20:
		push_error("FAIL: Straight 2-6 base score should be 20, got %d" % straight_result.base_score)
		passed = false
	if straight_result.get_total_score() != 600:
		push_error("FAIL: Straight 2-6 total score should be 600, got %d" % straight_result.get_total_score())
		passed = false
	
	# Four of a kind Ks: base = 10+10+10+10 = 40, multiplier = 60, total = 2400
	var four_k := _create_cards([
		[CardData.Rank.KING, CardData.Suit.SPADES],
		[CardData.Rank.KING, CardData.Suit.HEARTS],
		[CardData.Rank.KING, CardData.Suit.DIAMONDS],
		[CardData.Rank.KING, CardData.Suit.CLUBS]
	])
	
	var four_result := HandClassifier.evaluate(four_k)
	if four_result.base_score != 40:
		push_error("FAIL: Four Ks base score should be 40, got %d" % four_result.base_score)
		passed = false
	if four_result.get_total_score() != 2400:
		push_error("FAIL: Four Ks total score should be 2400, got %d" % four_result.get_total_score())
		passed = false
	
	if passed:
		print("  PASS: Score calculation works correctly")
	return passed