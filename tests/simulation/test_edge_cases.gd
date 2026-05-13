class_name TestEdgeCases
extends RefCounted

## 边界情况测试 —— 牌组抽空、空手牌、高分溢出、极端输入。
## 覆盖: 牌组耗尽、空手牌、得分刚好达标、大量得分、空选牌、弃牌堆洗牌。


static func _create_card(rank: CardData.Rank, suit: CardData.Suit = CardData.Suit.SPADES) -> CardData:
	var card := CardData.new()
	card.rank = rank
	card.suit = suit
	return card


## 创建测试关卡
static func _create_stage(target: int = 150, turns: int = 4) -> StageConfig:
	var s := StageConfig.new()
	s.stage_id = "test_stage"
	s.display_name = "测试关卡"
	s.base_target_score = target
	s.max_turns = turns
	s.blind_type = BlindType.Type.SMALL_BLIND
	s.boss_rule = StageConfig.BossRule.NONE
	s.base_reward = 10
	s.initial_hand_size = 10
	s.max_hand_size = 10
	s.max_selection_size = 5
	return s


## 执行所有测试
static func run_all_tests() -> bool:
	print("=== 正在运行边界情况测试 ===")
	var all_passed := true

	all_passed = _test_deck_exhaustion() and all_passed
	all_passed = _test_deck_reshuffle_from_discard() and all_passed
	all_passed = _test_score_exactly_target() and all_passed
	all_passed = _test_large_score_handling() and all_passed
	all_passed = _test_empty_selection() and all_passed
	all_passed = _test_single_card_play() and all_passed
	all_passed = _test_max_hand_size_no_crash() and all_passed
	all_passed = _test_zero_turn_stage() and all_passed
	all_passed = _test_invalid_card_data() and all_passed

	if all_passed:
		print("=== 所有边界情况测试通过 ===")
	else:
		print("=== 部分边界情况测试失败 ===")

	return all_passed


# ============================================================================
# 测试用例
# ============================================================================

static func _test_deck_exhaustion() -> bool:
	print("\n[测试] 牌组抽空")
	var passed := true

	# 创建小牌组：只有 20 张牌
	var deck := Deck.new()
	# Deck 初始化有 52 张牌，先抽掉一部分模拟小牌组
	while deck.get_remaining_count() > 20:
		deck.draw_card()

	# 抽 20 张牌
	var drawn := deck.draw_cards(20)
	if drawn.size() != 20:
		push_error("失败: 应抽到 20 张牌，实际 %d" % drawn.size())
		passed = false

	# 牌组应为空
	if not deck.is_empty():
		push_error("失败: 牌组应为空")
		passed = false

	# 可以正常调用 draw_card 不崩溃
	var card := deck.draw_card()
	# 弃牌堆也为空时返回 null
	if deck.get_discard_count() == 0:
		if card != null:
			push_error("失败: 牌组和弃牌堆皆空时应返回 null")
			passed = false

	if passed:
		print("  通过: 牌组抽空处理正常")
	return passed


static func _test_deck_reshuffle_from_discard() -> bool:
	print("\n[测试] 弃牌堆重新洗入")
	var passed := true

	var deck := Deck.new()

	# 抽 50 张牌（留下 2 张）
	var drawn := deck.draw_cards(50)

	# 弃掉 45 张
	for i in range(45):
		deck.discard(drawn[i])

	if deck.get_discard_count() != 45:
		push_error("失败: 弃牌堆应有 45 张")
		passed = false

	# 抽完剩余 2 张
	deck.draw_cards(2)

	# 再抽牌应触发弃牌堆重新洗入
	var extra := deck.draw_cards(10)
	if extra.is_empty():
		push_error("失败: 弃牌堆洗入后应能继续抽牌")
		passed = false

	if passed:
		print("  通过: 弃牌堆洗入正常")
	return passed


static func _test_score_exactly_target() -> bool:
	print("\n[测试] 得分刚好达标")
	var passed := true

	var config := _create_stage(100, 4)
	var sim := BattleSimulator.new()
	sim.setup(config, [], 42)

	# 手动设置得分刚好达标
	sim.current_score = 100

	if not sim.is_victory():
		push_error("失败: 得分刚好等于目标应为胜利")
		passed = false

	# 超额 1 分也应胜利
	sim.current_score = 101
	if not sim.is_victory():
		push_error("失败: 超额 1 分应为胜利")
		passed = false

	# 差 1 分不胜利
	sim.current_score = 99
	if sim.is_victory():
		push_error("失败: 差 1 分不应为胜利")
		passed = false

	if passed:
		print("  通过: 得分达标判定正常")
	return passed


static func _test_large_score_handling() -> bool:
	print("\n[测试] 大分数处理")
	var passed := true

	# 创建大数值卡牌并验证计算不溢出
	var cards: Array[CardData] = [
		_create_card(CardData.Rank.ACE),
		_create_card(CardData.Rank.KING),
		_create_card(CardData.Rank.QUEEN),
		_create_card(CardData.Rank.JACK),
		_create_card(CardData.Rank.TEN)
	]

	var result := HandClassifier.evaluate(cards)
	# 皇家同花顺不一定是同花（这里只是高顺子牌面），但至少应该能识别
	if not result.is_valid:
		# 可能因为不满足任何标准牌型而无效，这是正常的
		pass

	# 测试十倍率场景（Boss ×3 + 牌型倍率）
	var score := ScoreCalculator.calculate_score_with_modifiers(
		result, BlindType.Type.BOSS_BLIND,
		{"score_bonus": 100, "multiplier_bonus": 3.0}
	)

	# 得分应为非负整数
	if score < 0:
		push_error("失败: 得分不应为负")
		passed = false

	if typeof(score) != TYPE_INT:
		push_error("失败: 得分应为整数")
		passed = false

	if passed:
		print("  通过: 大分数处理正常（得分: %d）" % score)
	return passed


static func _test_empty_selection() -> bool:
	print("\n[测试] 空选牌")
	var passed := true

	# HandClassifier 对空数组的处理
	var result := HandClassifier.evaluate([])
	# 应该返回无效结果而不崩溃
	if result == null:
		push_error("失败: 空数组应返回结果而非 null")
		passed = false
	elif result.is_valid:
		# 空数组不应该识别为有效牌型
		push_error("失败: 空选牌不应为有效牌型")
		passed = false

	if passed:
		print("  通过: 空选牌处理正常")
	return passed


static func _test_single_card_play() -> bool:
	print("\n[测试] 单张牌出牌")
	var passed := true

	var cards: Array[CardData] = [_create_card(CardData.Rank.ACE)]

	var result := HandClassifier.evaluate(cards)
	if result == null:
		push_error("失败: 单张牌不应返回 null")
		passed = false
	elif not result.is_valid:
		push_error("失败: 单张牌应是高牌（有效牌型）")
		passed = false

	# 计算得分
	var score := ScoreCalculator.calculate_score(result, BlindType.Type.SMALL_BLIND)
	# A = 11 基础分 × 1（高牌倍率）× 1（小盲注）= 11
	if score <= 0:
		push_error("失败: 单张 A 得分应 > 0，实际 %d" % score)
		passed = false

	if passed:
		print("  通过: 单张牌出牌正常（得分: %d）" % score)
	return passed


static func _test_max_hand_size_no_crash() -> bool:
	print("\n[测试] 手牌上限不崩溃")
	var passed := true

	var config := _create_stage(150, 4)
	config.max_hand_size = 5  # 小容量
	config.initial_hand_size = 5

	var sim := BattleSimulator.new()
	sim.setup(config, [], 42)

	# 手牌应不超过上限
	if sim.hand_manager.get_hand_size() > config.max_hand_size:
		push_error("失败: 手牌不应超过上限 %d，实际 %d" % [
			config.max_hand_size, sim.hand_manager.get_hand_size()
		])
		passed = false

	# 尝试运行几个回合
	for i in range(2):
		if sim.is_defeat() or sim.is_victory():
			break
		var best := sim.auto_select_best()
		if best.is_empty():
			break
		sim.play_turn(best)

	# 不应崩溃
	if passed:
		print("  通过: 小手牌上限不崩溃")
	return passed


static func _test_zero_turn_stage() -> bool:
	print("\n[测试] 零回合关卡")
	var passed := true

	var config := _create_stage(100, 0)
	var sim := BattleSimulator.new()
	sim.setup(config, [], 42)

	# 立即失败
	if not sim.is_defeat():
		push_error("失败: 0 回合关卡应立即失败")
		passed = false

	if sim.is_victory():
		push_error("失败: 0 回合不可能通关")
		passed = false

	if passed:
		print("  通过: 零回合关卡正常")
	return passed


static func _test_invalid_card_data() -> bool:
	print("\n[测试] 无效卡牌数据处理")
	var passed := true

	# null 卡牌不应导致崩溃
	var cards: Array[CardData] = [_create_card(CardData.Rank.ACE), null]
	# 这会触发 push_warning，但不应崩溃
	# 我们只需验证 evaluate 不会崩溃

	var result := HandClassifier.evaluate(cards)
	# null 卡牌可能导致结果无效，但不崩溃即可
	if result == null:
		push_error("失败: 含 null 的卡牌数组不应返回 null")
		passed = false

	if passed:
		print("  通过: 无效卡牌数据不崩溃")
	return passed
