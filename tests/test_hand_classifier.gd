class_name TestHandClassifier
extends RefCounted

## Test runner for HandClassifier class.
## Verifies all poker hand type detection 正常工作.

## Run all tests
static func run_all_tests() -> bool:
	print("=== 正在运行 HandClassifier 测试 ===")
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
		print("=== 所有 HandClassifier 测试通过 ===")
	else:
		print("=== 部分 HandClassifier 测试失败 ===")
	
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
	print("\n[测试] 高牌检测")
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
		push_error("失败: 应为 HIGH_CARD, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 1:
		push_error("失败: High card multiplier 应为 1, 实际得 %d" % result.multiplier)
		passed = false
	
	# Single card should also be high card
	var single_card: Array[CardData] = [_create_card(CardData.Rank.ACE, CardData.Suit.SPADES)]
	var single_result := HandClassifier.evaluate(single_card)
	if single_result.hand_type != HandType.Type.HIGH_CARD:
		push_error("失败: Single card 应为 HIGH_CARD")
		passed = false
	
	if passed:
		print("  通过: 高牌检测正常工作")
	return passed


## Test one pair detection
static func _test_one_pair() -> bool:
	print("\n[测试] 一对检测")
	var passed := true
	
	# Valid pair: two 5s
	var pair_cards := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.HEARTS]
	])
	
	var result := HandClassifier.evaluate(pair_cards)
	if result.hand_type != HandType.Type.ONE_PAIR:
		push_error("失败: [黑桃5, 红心5] 应为 ONE_PAIR, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 2:
		push_error("失败: Pair multiplier 应为 2, 实际得 %d" % result.multiplier)
		passed = false
	
	# Invalid pair: different ranks
	var no_pair := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.SIX, CardData.Suit.HEARTS]
	])
	
	var no_pair_result := HandClassifier.evaluate(no_pair)
	if no_pair_result.hand_type == HandType.Type.ONE_PAIR:
		push_error("失败: [黑桃5, 红心6] 不应为 ONE_PAIR")
		passed = false
	
	# Invalid: three cards (not a pair)
	var three_same := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.HEARTS],
		[CardData.Rank.FIVE, CardData.Suit.DIAMONDS]
	])
	
	var three_result := HandClassifier.evaluate(three_same)
	if three_result.hand_type == HandType.Type.ONE_PAIR:
		push_error("失败: [黑桃5, 红心5, 方块5] 不应为 ONE_PAIR (it's THREE_OF_A_KIND)")
		passed = false
	
	# Invalid: single card
	var single: Array[CardData] = [_create_card(CardData.Rank.FIVE, CardData.Suit.SPADES)]
	var single_result := HandClassifier.evaluate(single)
	if single_result.hand_type == HandType.Type.ONE_PAIR:
		push_error("失败: Single card 不应为 ONE_PAIR")
		passed = false
	
	if passed:
		print("  通过: One pair 正常工作")
	return passed


## Test two pair detection
static func _test_two_pair() -> bool:
	print("\n[测试] 两对检测")
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
		push_error("失败: [黑桃3, 红心3, 方块7, 梅花7] 应为 TWO_PAIR, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 3:
		push_error("失败: Two pair multiplier 应为 3, 实际得 %d" % result.multiplier)
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
		push_error("失败: [黑桃3, 红心3, 方块3, 梅花7] 不应为 TWO_PAIR")
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
		push_error("失败: [黑桃3, 红心3, 方块7, 梅花8] 不应为 TWO_PAIR")
		passed = false
	
	if passed:
		print("  通过: Two pair 正常工作")
	return passed


## Test three of a kind detection
static func _test_three_of_a_kind() -> bool:
	print("\n[测试] 三张检测")
	var passed := true
	
	# Valid three of a kind: three 9s
	var three_cards := _create_cards([
		[CardData.Rank.NINE, CardData.Suit.SPADES],
		[CardData.Rank.NINE, CardData.Suit.HEARTS],
		[CardData.Rank.NINE, CardData.Suit.DIAMONDS]
	])
	
	var result := HandClassifier.evaluate(three_cards)
	if result.hand_type != HandType.Type.THREE_OF_A_KIND:
		push_error("失败: [黑桃9, 红心9, 方块9] 应为 THREE_OF_A_KIND, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 4:
		push_error("失败: Three of a kind multiplier 应为 4, 实际得 %d" % result.multiplier)
		passed = false
	
	# Invalid: two cards same rank + one different
	var not_three := _create_cards([
		[CardData.Rank.NINE, CardData.Suit.SPADES],
		[CardData.Rank.NINE, CardData.Suit.HEARTS],
		[CardData.Rank.EIGHT, CardData.Suit.DIAMONDS]
	])
	
	var not_result := HandClassifier.evaluate(not_three)
	if not_result.hand_type == HandType.Type.THREE_OF_A_KIND:
		push_error("失败: [黑桃9, 红心9, 方块8] 不应为 THREE_OF_A_KIND")
		passed = false
	
	if passed:
		print("  通过: Three of a kind 正常工作")
	return passed


## Test straight detection (regular)
static func _test_straight() -> bool:
	print("\n[测试] 顺子检测（普通）")
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
		push_error("失败: [2, 3, 4, 5, 6] 应为 STRAIGHT, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 30:
		push_error("失败: Straight multiplier 应为 30, 实际得 %d" % result.multiplier)
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
		push_error("失败: [10, J, Q, K, A] 应为 STRAIGHT, 实际得 %s" % HandType.get_display_name_cn(high_result.hand_type))
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
		push_error("失败: [2, 3, 4, 5, 7] 不应为 STRAIGHT")
		passed = false
	
	if passed:
		print("  通过: Straight 正常工作")
	return passed


## Test straight detection (Ace as low: A-2-3-4-5)
static func _test_straight_ace_low() -> bool:
	print("\n[测试] 顺子检测（A 作低牌）")
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
		push_error("失败: [A, 2, 3, 4, 5] 应为 STRAIGHT (Ace as low), 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
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
		push_error("失败: [J, Q, K, A, 2] 不应为 STRAIGHT")
		passed = false
	
	if passed:
		print("  通过: Ace-low straight 正常工作")
	return passed


## Test flush detection
static func _test_flush() -> bool:
	print("\n[测试] 同花检测")
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
		push_error("失败: 5 spades 应为 FLUSH, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 35:
		push_error("失败: Flush multiplier 应为 35, 实际得 %d" % result.multiplier)
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
		push_error("失败: 4 spades + 1 heart 不应为 FLUSH")
		passed = false
	
	if passed:
		print("  通过: Flush 正常工作")
	return passed


## Test full house detection
static func _test_full_house() -> bool:
	print("\n[测试] 葫芦检测")
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
		push_error("失败: [K, K, K, 5, 5] 应为 FULL_HOUSE, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 40:
		push_error("失败: Full house multiplier 应为 40, 实际得 %d" % result.multiplier)
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
		push_error("失败: [5, 5, 5, K, K] 应为 FULL_HOUSE")
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
		push_error("失败: [K, K, K, K, 5] 不应为 FULL_HOUSE")
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
		push_error("失败: [K, K, 5, 5, 3] 不应为 FULL_HOUSE")
		passed = false
	
	if passed:
		print("  通过: Full house 正常工作")
	return passed


## Test four of a kind detection
static func _test_four_of_a_kind() -> bool:
	print("\n[测试] 四张检测")
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
		push_error("失败: [黑桃Q, 红心Q, 方块Q, 梅花Q] 应为 FOUR_OF_A_KIND, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 60:
		push_error("失败: Four of a kind multiplier 应为 60, 实际得 %d" % result.multiplier)
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
		push_error("失败: [黑桃Q, 红心Q, 方块Q, 梅花K] 不应为 FOUR_OF_A_KIND")
		passed = false
	
	if passed:
		print("  通过: Four of a kind 正常工作")
	return passed


## Test straight flush detection
static func _test_straight_flush() -> bool:
	print("\n[测试] 同花顺检测")
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
		push_error("失败: [红心9, 红心10, 红心J, 红心Q, 红心K] 应为 STRAIGHT_FLUSH, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 80:
		push_error("失败: Straight flush multiplier 应为 80, 实际得 %d" % result.multiplier)
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
		push_error("失败: [黑桃10, 红心J, 方块Q, 梅花K, 黑桃A] 不应为 STRAIGHT_FLUSH")
		passed = false
	
	if passed:
		print("  通过: Straight flush 正常工作")
	return passed


## Test royal flush detection
static func _test_royal_flush() -> bool:
	print("\n[测试] 皇家同花顺检测")
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
		push_error("失败: [黑桃10, 黑桃J, 黑桃Q, 黑桃K, 黑桃A] 应为 ROYAL_FLUSH, 实际得 %s" % HandType.get_display_name_cn(result.hand_type))
		passed = false
	if result.multiplier != 100:
		push_error("失败: Royal flush multiplier 应为 100, 实际得 %d" % result.multiplier)
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
		push_error("失败: [9, 10, J, Q, K] same suit 应为 STRAIGHT_FLUSH, not ROYAL_FLUSH")
		passed = false
	if not_royal_result.hand_type != HandType.Type.STRAIGHT_FLUSH:
		push_error("失败: [9, 10, J, Q, K] same suit 应为 STRAIGHT_FLUSH")
		passed = false
	
	if passed:
		print("  通过: Royal flush 正常工作")
	return passed


## Test edge cases
static func _test_edge_cases() -> bool:
	print("\n[测试] 边界情况")
	var passed := true
	
	# Empty cards
	var empty: Array[CardData] = []
	var empty_result := HandClassifier.evaluate(empty)
	if empty_result.is_valid:
		push_error("失败: Empty cards should return invalid result")
		passed = false
	
	# Single card
	var single: Array[CardData] = [_create_card(CardData.Rank.ACE, CardData.Suit.SPADES)]
	var single_result := HandClassifier.evaluate(single)
	if single_result.hand_type != HandType.Type.HIGH_CARD:
		push_error("失败: Single card 应为 HIGH_CARD")
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
		push_error("失败: 4 cards cannot be STRAIGHT")
		passed = false
	if four_result.hand_type == HandType.Type.FLUSH:
		push_error("失败: 4 cards cannot be FLUSH")
		passed = false
	
	if passed:
		print("  通过: Edge cases handled correctly")
	return passed


## Test score calculation
static func _test_score_calculation() -> bool:
	print("\n[测试] 分数计算")
	var passed := true
	
	# Pair of 5s: base score = 5 + 5 = 10, multiplier = 2, total = 20
	var pair := _create_cards([
		[CardData.Rank.FIVE, CardData.Suit.SPADES],
		[CardData.Rank.FIVE, CardData.Suit.HEARTS]
	])
	
	var pair_result := HandClassifier.evaluate(pair)
	if pair_result.base_score != 10:
		push_error("失败: Pair of 5s base score 应为 10, 实际得 %d" % pair_result.base_score)
		passed = false
	if pair_result.get_total_score() != 20:
		push_error("失败: Pair of 5s total score 应为 20, 实际得 %d" % pair_result.get_total_score())
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
		push_error("失败: Straight 2-6 base score 应为 20, 实际得 %d" % straight_result.base_score)
		passed = false
	if straight_result.get_total_score() != 600:
		push_error("失败: Straight 2-6 total score 应为 600, 实际得 %d" % straight_result.get_total_score())
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
		push_error("失败: Four Ks base score 应为 40, 实际得 %d" % four_result.base_score)
		passed = false
	if four_result.get_total_score() != 2400:
		push_error("失败: Four Ks total score 应为 2400, 实际得 %d" % four_result.get_total_score())
		passed = false
	
	if passed:
		print("  通过: 分数计算正常")
	return passed