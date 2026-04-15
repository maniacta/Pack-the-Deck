class_name TestScoreCalculator
extends RefCounted

## Test runner for ScoreCalculator and BlindType classes.
## Verifies score calculation with blind multipliers 正常工作.

## Run all tests
static func run_all_tests() -> bool:
	print("=== 正在运行 ScoreCalculator 测试 ===")
	var all_passed := true
	
	all_passed = _test_blind_type_multipliers() and all_passed
	all_passed = _test_base_score_calculation() and all_passed
	all_passed = _test_blind_score_calculation() and all_passed
	all_passed = _test_victory_check() and all_passed
	all_passed = _test_reward_calculation() and all_passed
	all_passed = _test_score_with_modifiers() and all_passed
	all_passed = _test_score_breakdown() and all_passed
	all_passed = _test_display_format() and all_passed
	
	if all_passed:
		print("=== 所有 ScoreCalculator 测试通过 ===")
	else:
		print("=== 部分 ScoreCalculator 测试失败 ===")
	
	return all_passed


# ============================================================================
# Helper: Create cards and hand results
# ============================================================================

## Create a card with specified rank and suit
static func _create_card(rank: CardData.Rank, suit: CardData.Suit) -> CardData:
	var card := CardData.new()
	card.rank = rank
	card.suit = suit
	return card


## Create a hand result for testing
static func _create_hand_result(cards: Array[CardData]) -> HandType.HandResult:
	return HandClassifier.evaluate(cards)


# ============================================================================
# BlindType Tests
# ============================================================================

## Test blind type multipliers
static func _test_blind_type_multipliers() -> bool:
	print("\n[测试] 盲注类型倍率")
	var passed := true
	
	# Small blind: target ×1, reward ×1
	if BlindType.get_target_multiplier(BlindType.Type.SMALL_BLIND) != 1:
		push_error("失败: Small blind target multiplier should be 1")
		passed = false
	if BlindType.get_reward_multiplier(BlindType.Type.SMALL_BLIND) != 1:
		push_error("失败: Small blind reward multiplier should be 1")
		passed = false
	
	# Big blind: target ×2, reward ×2
	if BlindType.get_target_multiplier(BlindType.Type.BIG_BLIND) != 2:
		push_error("失败: Big blind target multiplier should be 2")
		passed = false
	if BlindType.get_reward_multiplier(BlindType.Type.BIG_BLIND) != 2:
		push_error("失败: Big blind reward multiplier should be 2")
		passed = false
	
	# Boss blind: target ×3, reward ×3
	if BlindType.get_target_multiplier(BlindType.Type.BOSS_BLIND) != 3:
		push_error("失败: Boss blind target multiplier should be 3")
		passed = false
	if BlindType.get_reward_multiplier(BlindType.Type.BOSS_BLIND) != 3:
		push_error("失败: Boss blind reward multiplier should be 3")
		passed = false
	
	# is_boss check
	if BlindType.is_boss(BlindType.Type.BOSS_BLIND) != true:
		push_error("失败: BOSS_BLIND should return true for is_boss()")
		passed = false
	if BlindType.is_boss(BlindType.Type.SMALL_BLIND) != false:
		push_error("失败: SMALL_BLIND should return false for is_boss()")
		passed = false
	
	# Display names
	if BlindType.get_display_name_cn(BlindType.Type.SMALL_BLIND) != "小盲注":
		push_error("失败: Small blind CN name should be '小盲注'")
		passed = false
	if BlindType.get_display_name_cn(BlindType.Type.BOSS_BLIND) != "Boss 盲注":
		push_error("失败: Boss blind CN name should be 'Boss 盲注'")
		passed = false
	
	if passed:
		print("  通过: Blind type multipliers work correctly")
	return passed


# ============================================================================
# ScoreCalculator Tests
# ============================================================================

## Test base score calculation (without blind multiplier)
static func _test_base_score_calculation() -> bool:
	print("\n[测试] 基础分数计算")
	var passed := true
	
	# Pair of 5s: base = 10, hand_mult = 2, total = 20
	var pair_cards: Array[CardData] = [
		_create_card(CardData.Rank.FIVE, CardData.Suit.SPADES),
		_create_card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var pair_result := _create_hand_result(pair_cards)
	
	if pair_result.base_score != 10:
		push_error("失败: Pair of 5s base score should be 10, got %d" % pair_result.base_score)
		passed = false
	if pair_result.multiplier != 2:
		push_error("失败: Pair multiplier should be 2, got %d" % pair_result.multiplier)
		passed = false
	if pair_result.get_total_score() != 20:
		push_error("失败: Pair total score should be 20, got %d" % pair_result.get_total_score())
		passed = false
	
	# Straight 2-6: base = 20, hand_mult = 30, total = 600
	var straight_cards: Array[CardData] = [
		_create_card(CardData.Rank.TWO, CardData.Suit.SPADES),
		_create_card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		_create_card(CardData.Rank.FOUR, CardData.Suit.DIAMONDS),
		_create_card(CardData.Rank.FIVE, CardData.Suit.CLUBS),
		_create_card(CardData.Rank.SIX, CardData.Suit.SPADES)
	]
	var straight_result := _create_hand_result(straight_cards)
	
	if straight_result.get_total_score() != 600:
		push_error("失败: Straight 2-6 total score should be 600, got %d" % straight_result.get_total_score())
		passed = false
	
	if passed:
		print("  通过: Base score calculation 正常工作")
	return passed


## Test score calculation with blind multiplier
static func _test_blind_score_calculation() -> bool:
	print("\n[测试] 盲注分数计算")
	var passed := true
	
	# Pair of 5s with SMALL blind: 20 × 1 = 20
	var pair_cards: Array[CardData] = [
		_create_card(CardData.Rank.FIVE, CardData.Suit.SPADES),
		_create_card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var pair_result := _create_hand_result(pair_cards)
	
	var small_score := ScoreCalculator.calculate_score(pair_result, BlindType.Type.SMALL_BLIND)
	if small_score != 20:
		push_error("失败: Pair with small blind should score 20, got %d" % small_score)
		passed = false
	
	# Pair of 5s with BIG blind: 20 × 2 = 40
	var big_score := ScoreCalculator.calculate_score(pair_result, BlindType.Type.BIG_BLIND)
	if big_score != 40:
		push_error("失败: Pair with big blind should score 40, got %d" % big_score)
		passed = false
	
	# Pair of 5s with BOSS blind: 20 × 3 = 60
	var boss_score := ScoreCalculator.calculate_score(pair_result, BlindType.Type.BOSS_BLIND)
	if boss_score != 60:
		push_error("失败: Pair with boss blind should score 60, got %d" % boss_score)
		passed = false
	
	# Straight 2-6 with BIG blind: 600 × 2 = 1200
	var straight_cards: Array[CardData] = [
		_create_card(CardData.Rank.TWO, CardData.Suit.SPADES),
		_create_card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		_create_card(CardData.Rank.FOUR, CardData.Suit.DIAMONDS),
		_create_card(CardData.Rank.FIVE, CardData.Suit.CLUBS),
		_create_card(CardData.Rank.SIX, CardData.Suit.SPADES)
	]
	var straight_result := _create_hand_result(straight_cards)
	
	var straight_big := ScoreCalculator.calculate_score(straight_result, BlindType.Type.BIG_BLIND)
	if straight_big != 1200:
		push_error("失败: Straight with big blind should score 1200, got %d" % straight_big)
		passed = false
	
	# Invalid hand should return 0
	var empty_result := HandType.HandResult.create_empty()
	var empty_score := ScoreCalculator.calculate_score(empty_result, BlindType.Type.SMALL_BLIND)
	if empty_score != 0:
		push_error("失败: Invalid hand should score 0, got %d" % empty_score)
		passed = false
	
	if passed:
		print("  通过: Blind score calculation 正常工作")
	return passed


## Test victory check
static func _test_victory_check() -> bool:
	print("\n[测试] 胜利检测")
	var passed := true
	
	# Exactly target score should pass
	if ScoreCalculator.check_victory(300, 300) != true:
		push_error("失败: Score 300 vs target 300 should pass")
		passed = false
	
	# Above target score should pass
	if ScoreCalculator.check_victory(350, 300) != true:
		push_error("失败: Score 350 vs target 300 should pass")
		passed = false
	
	# Below target score should NOT pass
	if ScoreCalculator.check_victory(240, 300) != false:
		push_error("失败: Score 240 vs target 300 should NOT pass")
		passed = false
	
	if passed:
		print("  通过: Victory check 正常工作")
	return passed


## Test reward calculation
static func _test_reward_calculation() -> bool:
	print("\n[测试] 奖励计算")
	var passed := true
	
	# Base reward 10 with small blind: 10 × 1 = 10
	var small_reward := ScoreCalculator.calculate_reward(BlindType.Type.SMALL_BLIND, 10)
	if small_reward != 10:
		push_error("失败: Small blind reward should be 10, got %d" % small_reward)
		passed = false
	
	# Base reward 10 with big blind: 10 × 2 = 20
	var big_reward := ScoreCalculator.calculate_reward(BlindType.Type.BIG_BLIND, 10)
	if big_reward != 20:
		push_error("失败: Big blind reward should be 20, got %d" % big_reward)
		passed = false
	
	# Base reward 10 with boss blind: 10 × 3 = 30
	var boss_reward := ScoreCalculator.calculate_reward(BlindType.Type.BOSS_BLIND, 10)
	if boss_reward != 30:
		push_error("失败: Boss blind reward should be 30, got %d" % boss_reward)
		passed = false
	
	if passed:
		print("  通过: Reward calculation 正常工作")
	return passed


## Test score calculation with equipment modifiers
static func _test_score_with_modifiers() -> bool:
	print("\n[测试] 装备倍率分数")
	var passed := true
	
	# Pair of 5s: base = 10, hand_mult = 2, blind_mult = 1
	var pair_cards: Array[CardData] = [
		_create_card(CardData.Rank.FIVE, CardData.Suit.SPADES),
		_create_card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var pair_result := _create_hand_result(pair_cards)
	
	# With score bonus +5: (10+5) × 2 × 1 = 30
	var with_bonus := ScoreCalculator.calculate_score_with_modifiers(
		pair_result, BlindType.Type.SMALL_BLIND, {"score_bonus": 5}
	)
	if with_bonus != 30:
		push_error("失败: Pair with +5 bonus should score 30, got %d" % with_bonus)
		passed = false
	
	# With multiplier bonus ×2: 10 × (2×2) × 1 = 40
	var with_mult := ScoreCalculator.calculate_score_with_modifiers(
		pair_result, BlindType.Type.SMALL_BLIND, {"multiplier_bonus": 2.0}
	)
	if with_mult != 40:
		push_error("失败: Pair with ×2 multiplier bonus should score 40, got %d" % with_mult)
		passed = false
	
	# With both: (10+5) × (2×2) × 1 = 60
	var with_both := ScoreCalculator.calculate_score_with_modifiers(
		pair_result, BlindType.Type.SMALL_BLIND, {"score_bonus": 5, "multiplier_bonus": 2.0}
	)
	if with_both != 60:
		push_error("失败: Pair with both bonuses should score 60, got %d" % with_both)
		passed = false
	
	if passed:
		print("  通过: Score with modifiers 正常工作")
	return passed


## Test ScoreBreakdown class
static func _test_score_breakdown() -> bool:
	print("\n[测试] 分数详情")
	var passed := true
	
	var pair_cards: Array[CardData] = [
		_create_card(CardData.Rank.FIVE, CardData.Suit.SPADES),
		_create_card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var pair_result := _create_hand_result(pair_cards)
	
	var breakdown := ScoreCalculator.ScoreBreakdown.new(pair_result, BlindType.Type.SMALL_BLIND)
	
	# Check initial breakdown values
	if breakdown.card_base_score != 10:
		push_error("失败: Breakdown card_base_score should be 10, got %d" % breakdown.card_base_score)
		passed = false
	if breakdown.hand_multiplier != 2:
		push_error("失败: Breakdown hand_multiplier should be 2, got %d" % breakdown.hand_multiplier)
		passed = false
	if breakdown.blind_multiplier != 1:
		push_error("失败: Breakdown blind_multiplier should be 1, got %d" % breakdown.blind_multiplier)
		passed = false
	if breakdown.final_score != 20:
		push_error("失败: Breakdown final_score should be 20, got %d" % breakdown.final_score)
		passed = false
	
	# Apply equipment bonus
	breakdown.apply_equipment_bonus(5, 2.0)
	
	# Check after modifiers: (10+5) × (2×2) × 1 = 60
	if breakdown.equipment_score_bonus != 5:
		push_error("失败: Equipment score bonus should be 5")
		passed = false
	if breakdown.equipment_multiplier_bonus != 2.0:
		push_error("失败: Equipment multiplier bonus should be 2.0")
		passed = false
	if breakdown.final_score != 60:
		push_error("失败: Breakdown final_score after bonus should be 60, got %d" % breakdown.final_score)
		passed = false
	
	# Display string
	var display := breakdown.get_display_string()
	if not display.contains("对子"):
		push_error("失败: Breakdown display should contain '对子'")
		passed = false
	if not display.contains("60"):
		push_error("失败: Breakdown display should contain final score '60'")
		passed = false
	
	if passed:
		print("  通过: Score breakdown 正常工作")
	return passed


## Test display format
static func _test_display_format() -> bool:
	print("\n[测试] 显示格式")
	var passed := true
	
	var pair_cards: Array[CardData] = [
		_create_card(CardData.Rank.FIVE, CardData.Suit.SPADES),
		_create_card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var pair_result := _create_hand_result(pair_cards)
	
	var display := ScoreCalculator.format_score_display(pair_result, BlindType.Type.SMALL_BLIND)
	
	# Should contain: hand type name, base score, multipliers, final score
	if not display.contains("对子"):
		push_error("失败: Display should contain hand type '对子'")
		passed = false
	if not display.contains("10"):
		push_error("失败: Display should contain base score '10'")
		passed = false
	if not display.contains("20 分"):
		push_error("失败: Display should contain final score '20 分'")
		passed = false
	
	# Invalid hand display
	var empty_result := HandType.HandResult.create_empty()
	var empty_display := ScoreCalculator.format_score_display(empty_result, BlindType.Type.SMALL_BLIND)
	if not empty_display.contains("无效"):
		push_error("失败: Empty display should contain '无效'")
		passed = false
	
	if passed:
		print("  通过: Display format 正常工作")
	return passed
