class_name TestTurnManager
extends RefCounted

## 回合管理器单元测试 —— 回合计数、出牌次数限制、Boss 规则。
## 覆盖: setup/record_play/Boss PLAY_LIMIT/CARD_LIMIT/回合耗尽/信号。


## 创建测试关卡配置
static func _create_stage_config(
	turns: int = 4,
	blind_type: BlindType.Type = BlindType.Type.SMALL_BLIND,
	boss_rule: StageConfig.BossRule = StageConfig.BossRule.NONE,
	boss_param: Dictionary = {}
) -> StageConfig:
	var s := StageConfig.new()
	s.stage_id = "test_stage"
	s.display_name = "测试关卡"
	s.base_target_score = 100
	s.max_turns = turns
	s.blind_type = blind_type
	s.boss_rule = boss_rule
	s.boss_rule_param = boss_param
	s.base_reward = 10
	return s


## 执行所有测试
static func run_all_tests() -> bool:
	print("=== 正在运行 TurnManager 测试 ===")
	var all_passed := true

	all_passed = _test_setup_default() and all_passed
	all_passed = _test_record_play() and all_passed
	all_passed = _test_turns_exhausted() and all_passed
	all_passed = _test_boss_play_limit() and all_passed
	all_passed = _test_boss_card_limit() and all_passed
	all_passed = _test_boss_no_rule() and all_passed
	all_passed = _test_start_new_turn() and all_passed
	all_passed = _test_can_play_without_remaining_turns() and all_passed

	if all_passed:
		print("=== 所有 TurnManager 测试通过 ===")
	else:
		print("=== 部分 TurnManager 测试失败 ===")

	return all_passed


static func _test_setup_default() -> bool:
	print("\n[测试] 默认设置")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(4)

	tm.setup(config)

	if tm.max_turns != 4:
		push_error("失败: max_turns 应为 4，实际 %d" % tm.max_turns)
		passed = false
	if tm.remaining_turns != 4:
		push_error("失败: remaining_turns 应为 4，实际 %d" % tm.remaining_turns)
		passed = false
	if tm.current_turn != 0:
		push_error("失败: current_turn 应为 0")
		passed = false
	if tm.has_play_limit():
		push_error("失败: 默认不应有出牌限制")
		passed = false
	if tm.has_hand_size_limit():
		push_error("失败: 默认不应有手牌限制")
		passed = false

	if passed:
		print("  通过: 默认设置正常")
	return passed


static func _test_record_play() -> bool:
	print("\n[测试] 出牌计数")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(3)
	tm.setup(config)

	# 第一次出牌
	tm.record_play()
	if tm.plays_this_turn != 1:
		push_error("失败: plays_this_turn 应为 1，实际 %d" % tm.plays_this_turn)
		passed = false
	if tm.remaining_turns != 2:
		push_error("失败: remaining_turns 应为 2，实际 %d" % tm.remaining_turns)
		passed = false
	if tm.has_remaining_turns() != true:
		push_error("失败: 应有剩余回合")
		passed = false

	# 第二次出牌
	tm.record_play()
	if tm.plays_this_turn != 2:
		push_error("失败: plays_this_turn 应为 2")
		passed = false
	if tm.remaining_turns != 1:
		push_error("失败: remaining_turns 应为 1")
		passed = false

	# 第三次出牌（最后一次）
	tm.record_play()
	if tm.remaining_turns != 0:
		push_error("失败: remaining_turns 应为 0")
		passed = false
	if not tm.is_turns_exhausted():
		push_error("失败: 回合应已耗尽")
		passed = false

	if passed:
		print("  通过: 出牌计数正常")
	return passed


static func _test_turns_exhausted() -> bool:
	print("\n[测试] 回合耗尽")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(1)
	tm.setup(config)

	if tm.is_turns_exhausted():
		push_error("失败: 初始不应耗尽")
		passed = false
	if not tm.can_play():
		push_error("失败: 初始应可出牌")
		passed = false

	tm.record_play()

	if not tm.is_turns_exhausted():
		push_error("失败: 1 回合后应耗尽")
		passed = false
	if tm.can_play():
		push_error("失败: 耗尽后不应可出牌")
		passed = false

	if passed:
		print("  通过: 回合耗尽检测正常")
	return passed


static func _test_boss_play_limit() -> bool:
	print("\n[测试] Boss 出牌次数限制")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(
		10,  # 足够多的回合
		BlindType.Type.BOSS_BLIND,
		StageConfig.BossRule.PLAY_LIMIT,
		{"limit": 2}
	)
	tm.setup(config)

	if not tm.has_play_limit():
		push_error("失败: 应检测到出牌限制")
		passed = false
	if tm.max_plays_per_turn != 2:
		push_error("失败: max_plays_per_turn 应为 2")
		passed = false

	# 前 2 次应可出牌
	if not tm.can_play():
		push_error("失败: 前 2 次出牌应可通过")
		passed = false

	tm.record_play()
	tm.plays_this_turn = 2  # 模拟已出 2 次

	if tm.can_play():
		push_error("失败: 达到上限后不应可出牌")
		passed = false

	# Boss 规则描述
	var desc := tm.get_boss_rule_description()
	if desc.is_empty():
		push_error("失败: 应有 Boss 规则描述")
		passed = false

	if passed:
		print("  通过: Boss 出牌限制正常")
	return passed


static func _test_boss_card_limit() -> bool:
	print("\n[测试] Boss 手牌上限")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(
		5,
		BlindType.Type.BOSS_BLIND,
		StageConfig.BossRule.CARD_LIMIT,
		{"limit": 5}
	)
	tm.setup(config)

	if not tm.has_hand_size_limit():
		push_error("失败: 应检测到手牌限制")
		passed = false
	if tm.get_hand_size_limit() != 5:
		push_error("失败: 手牌上限应为 5")
		passed = false

	var desc := tm.get_boss_rule_description()
	if desc.is_empty():
		push_error("失败: 应有 Boss 规则描述")
		passed = false

	if passed:
		print("  通过: Boss 手牌上限正常")
	return passed


static func _test_boss_no_rule() -> bool:
	print("\n[测试] 无 Boss 规则")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(4, BlindType.Type.SMALL_BLIND)
	tm.setup(config)

	if tm.has_play_limit():
		push_error("失败: 小盲注不应有出牌限制")
		passed = false
	if tm.has_hand_size_limit():
		push_error("失败: 小盲注不应有手牌限制")
		passed = false

	var desc := tm.get_boss_rule_description()
	if not desc.is_empty():
		push_error("失败: 无 Boss 规则时描述应为空")
		passed = false

	if passed:
		print("  通过: 无 Boss 规则正常")
	return passed


static func _test_start_new_turn() -> bool:
	print("\n[测试] 新回合开始")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(4)
	tm.setup(config)

	# 模拟出牌后开始新回合
	tm.plays_this_turn = 3
	tm.start_new_turn()

	if tm.current_turn != 1:
		push_error("失败: current_turn 应为 1，实际 %d" % tm.current_turn)
		passed = false
	if tm.plays_this_turn != 0:
		push_error("失败: plays_this_turn 应重置为 0")
		passed = false

	# 再开始一个回合
	tm.plays_this_turn = 2
	tm.start_new_turn()
	if tm.current_turn != 2:
		push_error("失败: current_turn 应为 2")
		passed = false

	if passed:
		print("  通过: 新回合开始正常")
	return passed


static func _test_can_play_without_remaining_turns() -> bool:
	print("\n[测试] 无剩余回合时不可出牌")
	var passed := true
	var tm := TurnManager.new()
	var config := _create_stage_config(0)  # 0 回合
	tm.setup(config)

	if tm.can_play():
		push_error("失败: 0 回合配置下不应可出牌")
		passed = false

	if passed:
		print("  通过: 无剩余回合检测正常")
	return passed
