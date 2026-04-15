class_name TestBossRules
extends RefCounted

## Test suite for Boss rules functionality - validates boss rule effects on scoring.

## Run all tests
static func run_all_tests() -> bool:
	print("\n========================================")
	print("Boss 规则测试套件")
	print("========================================")
	
	var all_passed: bool = true
	
	# Test StageConfig boss rules
	all_passed = _test_stage_config_boss_rules() and all_passed
	
	# Test suit exclusion rule
	all_passed = _test_suit_exclusion_rule() and all_passed
	
	# Test hand type exclusion rule
	all_passed = _test_hand_type_exclusion_rule() and all_passed
	
	# Test play limit rule
	all_passed = _test_play_limit_rule() and all_passed
	
	# Test card limit rule
	all_passed = _test_card_limit_rule() and all_passed
	
	print("========================================")
	if all_passed:
		print("✓ Boss 规则所有测试通过")
	else:
		print("✗ Boss 规则测试失败")
	print("========================================\n")
	
	return all_passed


## Test StageConfig boss rule properties
static func _test_stage_config_boss_rules() -> bool:
	print("\n[测试] StageConfig Boss 规则配置")
	
	# Create boss stage with suit exclusion
	var stage := StageConfig.new()
	stage.stage_id = "boss_test_1"
	stage.display_name = "Boss 测试关"
	stage.base_target_score = 500
	stage.max_turns = 4
	stage.blind_type = BlindType.Type.BOSS_BLIND
	stage.boss_rule = StageConfig.BossRule.SUIT_EXCLUDED
	stage.boss_rule_param = {"suit": CardData.Suit.DIAMONDS, "suit_name": "方块"}
	stage.base_reward = 25
	
	# Validate boss rule detection
	if not stage.has_boss_rule():
		print("  ✗ has_boss_rule() 应返回 true")
		return false
	
	# Check description
	var desc: String = stage.get_boss_rule_description()
	if not desc.contains("方块"):
		print("  ✗ Boss 规则描述应包含 '方块'")
		return false
	
	# Check target score (boss blind = ×3)
	var target: int = stage.get_target_score()
	if target != 500 * 3:
		print("  ✗ Boss 目标分数应为 %d (500×3)" % (500 * 3))
		return false
	
	# Check reward (boss blind = ×3)
	var reward: int = stage.get_reward()
	if reward != 25 * 3:
		print("  ✗ Boss 奖励应为 %d (25×3)" % (25 * 3))
		return false
	
	print("  ✓ StageConfig Boss 规则配置测试通过")
	return true


## Test suit exclusion rule (DIAMONDS excluded)
static func _test_suit_exclusion_rule() -> bool:
	print("\n[测试] 花色排除规则")
	
	# Create cards with mixed suits
	var cards: Array[CardData] = []
	
	# Add diamonds (should be excluded)
	var diamond_5 := CardData.new()
	diamond_5.suit = CardData.Suit.DIAMONDS
	diamond_5.rank = 5  # 5 points
	cards.append(diamond_5)
	
	# Add hearts (should count)
	var heart_5 := CardData.new()
	heart_5.suit = CardData.Suit.HEARTS
	heart_5.rank = 5  # 5 points
	cards.append(heart_5)
	
	# Add spades (should count)
	var spade_k := CardData.new()
	spade_k.suit = CardData.Suit.SPADES
	spade_k.rank = 13  # K = 10 points
	cards.append(spade_k)
	
	# Calculate score excluding diamonds
	var excluded_suit: int = CardData.Suit.DIAMONDS
	var score: int = 0
	for card: CardData in cards:
		if card.suit != excluded_suit:
			score += card.get_base_score()
	
	# Should be: 5 (heart) + 10 (spade K) = 15
	if score != 15:
		print("  ✗ 排除方块后得分应为 15，实际: %d" % score)
		return false
	
	print("  ✓ 花色排除规则测试通过")
	return true


## Test hand type exclusion rule
static func _test_hand_type_exclusion_rule() -> bool:
	print("\n[测试] 牌型排除规则")
	
	# Create boss stage that excludes straight
	var stage := StageConfig.new()
	stage.blind_type = BlindType.Type.BOSS_BLIND
	stage.boss_rule = StageConfig.BossRule.HAND_TYPE_EXCLUDED
	stage.boss_rule_param = {"hand_type": HandType.Type.STRAIGHT, "hand_name": "顺子"}
	
	# Validate exclusion setting
	if stage.boss_rule != StageConfig.BossRule.HAND_TYPE_EXCLUDED:
		print("  ✗ Boss 规则应为 HAND_TYPE_EXCLUDED")
		return false
	
	var excluded_type: int = stage.boss_rule_param.get("hand_type", HandType.Type.HIGH_CARD)
	if excluded_type != HandType.Type.STRAIGHT:
		print("  ✗ 排除牌型应为顺子")
		return false
	
	# Check description
	var desc: String = stage.get_boss_rule_description()
	if not desc.contains("顺子"):
		print("  ✗ Boss 规则描述应包含 '顺子'")
		return false
	
	print("  ✓ 牌型排除规则测试通过")
	return true


## Test play limit rule
static func _test_play_limit_rule() -> bool:
	print("\n[测试] 出牌次数限制规则")
	
	# Create boss stage with play limit
	var stage := StageConfig.new()
	stage.blind_type = BlindType.Type.BOSS_BLIND
	stage.boss_rule = StageConfig.BossRule.PLAY_LIMIT
	stage.boss_rule_param = {"limit": 2}
	
	# Validate limit setting
	var limit: int = stage.boss_rule_param.get("limit", 3)
	if limit != 2:
		print("  ✗ 出牌限制应为 2")
		return false
	
	# Check description
	var desc: String = stage.get_boss_rule_description()
	if not desc.contains("2"):
		print("  ✗ Boss 规则描述应包含限制数字")
		return false
	
	# Simulate play count check (matches BattleController logic)
	# Check BEFORE playing: can_play = plays_this_turn < limit
	var plays_this_turn: int = 0
	
	# First play check (0 < 2) - should allow
	var can_play: bool = plays_this_turn < limit
	if not can_play:
		print("  ✗ 第一次出牌应允许 (plays=0 < limit=2)")
		return false
	
	# After first play
	plays_this_turn += 1
	
	# Second play check (1 < 2) - should allow
	can_play = plays_this_turn < limit
	if not can_play:
		print("  ✗ 第二次出牌应允许 (plays=1 < limit=2)")
		return false
	
	# After second play
	plays_this_turn += 1
	
	# Third play check (2 < 2) - should NOT allow
	can_play = plays_this_turn < limit
	if can_play:
		print("  ✗ 第三次出牌应禁止 (plays=2 >= limit=2)")
		return false
	
	print("  ✓ 出牌次数限制规则测试通过")
	return true


## Test card limit rule (hand size limit)
static func _test_card_limit_rule() -> bool:
	print("\n[测试] 手牌上限规则")
	
	# Create boss stage with card limit
	var stage := StageConfig.new()
	stage.blind_type = BlindType.Type.BOSS_BLIND
	stage.boss_rule = StageConfig.BossRule.CARD_LIMIT
	stage.boss_rule_param = {"limit": 5}
	
	# Validate limit setting
	var limit: int = stage.boss_rule_param.get("limit", 8)
	if limit != 5:
		print("  ✗ 手牌上限应为 5")
		return false
	
	# Check description
	var desc: String = stage.get_boss_rule_description()
	if not desc.contains("5"):
		print("  ✗ Boss 规则描述应包含限制数字")
		return false
	
	# Simulate hand size check
	var hand_size: int = 8
	var cards_to_discard: int = 0
	
	if hand_size > limit:
		cards_to_discard = hand_size - limit
	
	if cards_to_discard != 3:
		print("  ✗ 应丢弃 3 张牌 (8-5)")
		return false
	
	print("  ✓ 手牌上限规则测试通过")
	return true


## Test full description output
static func _test_full_description() -> bool:
	print("\n[测试] 关卡完整描述")
	
	var stage := StageConfig.new()
	stage.stage_id = "boss_final"
	stage.display_name = "最终 Boss"
	stage.base_target_score = 500
	stage.max_turns = 4
	stage.blind_type = BlindType.Type.BOSS_BLIND
	stage.boss_rule = StageConfig.BossRule.SUIT_EXCLUDED
	stage.boss_rule_param = {"suit": CardData.Suit.HEARTS, "suit_name": "红心"}
	stage.base_reward = 75
	
	var full_desc: String = stage.get_full_description()
	
	# Check all parts present
	if not full_desc.contains("最终 Boss"):
		print("  ✗ 完整描述应包含关卡名称")
		return false
	
	if not full_desc.contains("1500"):  # 500 × 3
		print("  ✗ 完整描述应包含目标分数 1500")
		return false
	
	if not full_desc.contains("红心"):
		print("  ✗ 完整描述应包含 Boss 规则")
		return false
	
	if not full_desc.contains("225"):  # 75 × 3
		print("  ✗ 完整描述应包含奖励金币 225")
		return false
	
	print("  ✓ 关卡完整描述测试通过")
	return true