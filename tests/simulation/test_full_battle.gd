class_name TestFullBattle
extends RefCounted

## 端到端战斗模拟测试 —— 使用 BattleSimulator 运行完整战斗。
## 覆盖: 关卡1/2/3 完整通关、装备效果、Boss 规则。


## 创建关卡配置
static func _create_stage(
	target: int = 150,
	turns: int = 4,
	blind: BlindType.Type = BlindType.Type.SMALL_BLIND,
	boss_rule: StageConfig.BossRule = StageConfig.BossRule.NONE,
	boss_param: Dictionary = {}
) -> StageConfig:
	var s := StageConfig.new()
	s.stage_id = "test_stage"
	s.display_name = "测试关卡"
	s.base_target_score = target
	s.max_turns = turns
	s.blind_type = blind
	s.boss_rule = boss_rule
	s.boss_rule_param = boss_param
	s.base_reward = 10
	s.initial_hand_size = 10
	s.max_hand_size = 10
	s.max_selection_size = 5
	return s


## 执行所有测试
static func run_all_tests() -> bool:
	print("=== 正在运行端到端战斗模拟测试 ===")
	var all_passed := true

	all_passed = _test_battle_stage_1_easy() and all_passed
	all_passed = _test_battle_stage_3_boss() and all_passed
	all_passed = _test_battle_with_equipment() and all_passed
	all_passed = _test_defeat_scenario() and all_passed
	all_passed = _test_multiple_battles_different_seeds() and all_passed

	if all_passed:
		print("=== 所有端到端战斗模拟测试通过 ===")
	else:
		print("=== 部分端到端战斗模拟测试失败 ===")

	return all_passed


# ============================================================================
# 测试用例
# ============================================================================

static func _test_battle_stage_1_easy() -> bool:
	print("\n[测试] 关卡1完整战斗（简单）")
	var passed := true

	var config := _create_stage(150, 4, BlindType.Type.SMALL_BLIND)
	var sim := BattleSimulator.new()
	sim.setup(config, [], 42)

	var result := sim.run_full_battle()

	if not result["won"]:
		push_error("失败: 简单关卡应能通关，得分 %d / 目标 %d" % [result["score"], result["target"]])
		print(sim.get_summary())
		passed = false

	if result["turns_used"] > config.max_turns:
		push_error("失败: 回合数不应超过上限，实际 %d / %d" % [result["turns_used"], config.max_turns])
		passed = false

	if result["history"].size() == 0:
		push_error("失败: 应有出牌记录")
		passed = false

	if passed:
		print("  通过: 关卡1通关，得分 %d，%d 回合" % [result["score"], result["turns_used"]])
		print(sim.get_summary())

	return passed


static func _test_battle_stage_3_boss() -> bool:
	print("\n[测试] Boss 关卡战斗（花色排除）")
	var passed := true

	var config := _create_stage(
		300, 6, BlindType.Type.BOSS_BLIND,
		StageConfig.BossRule.SUIT_EXCLUDED,
		{"suit": CardData.Suit.DIAMONDS, "suit_name": "方块"}
	)

	var sim := BattleSimulator.new()
	sim.setup(config, [], 99)

	var result := sim.run_full_battle()

	# 验证游戏能完成（不崩溃），但不强制要求通关
	if result["history"].size() == 0:
		push_error("失败: 应有出牌记录（即使失败）")
		passed = false

	if result["score"] < 0:
		push_error("失败: 得分不应为负数")
		passed = false

	print("  Boss 关卡结果: %s, 得分 %d/%d, 回合 %d/%d" % [
		"通关" if result["won"] else "失败",
		result["score"], result["target"],
		result["turns_used"], result["max_turns"]
	])

	if passed:
		print("  通过: Boss 关卡战斗无崩溃")
	return passed


static func _test_battle_with_equipment() -> bool:
	print("\n[测试] 带装备的战斗")
	var passed := true

	# 加载完美镜片（顺子只需4张牌）
	var perfect_lens: EquipmentData = load("res://resources/equipment/perfect_lens.tres") as EquipmentData
	if not perfect_lens:
		push_error("失败: 无法加载 perfect_lens.tres")
		return false

	var config := _create_stage(150, 4, BlindType.Type.SMALL_BLIND)
	var sim := BattleSimulator.new()
	sim.setup(config, [perfect_lens], 42)

	# 验证规则被改写
	if sim.rule_modifier.get_straight_min_cards() != 4:
		push_error("失败: 装备完美镜片后顺子最小牌数应为 4，实际 %d" % sim.rule_modifier.get_straight_min_cards())
		passed = false

	var result := sim.run_full_battle()

	if result["history"].size() == 0:
		push_error("失败: 应有出牌记录")
		passed = false

	if result["score"] < 0:
		push_error("失败: 得分不应为负数")
		passed = false

	if passed:
		print("  通过: 装备战斗正常")
	return passed


static func _test_defeat_scenario() -> bool:
	print("\n[测试] 失败场景（不可能达成的目标）")
	var passed := true

	# 设置极高的目标分数，确保无法通关
	var config := _create_stage(50000, 3, BlindType.Type.SMALL_BLIND)
	var sim := BattleSimulator.new()
	sim.setup(config, [], 42)

	var result := sim.run_full_battle()

	# 应该失败
	if result["won"]:
		push_error("失败: 不可能目标下不应通关")
		passed = false

	if result["turns_used"] != config.max_turns:
		# 可能小于 max_turns（如果提前无法出牌），但不应超过
		if result["turns_used"] > config.max_turns:
			push_error("失败: 回合数不应超过上限")
			passed = false

	# 验证玩法历史记录正确
	for h: Dictionary in result["history"]:
		if not h.has("hand_type") or not h.has("score"):
			push_error("失败: 出牌记录缺少关键字段")
			passed = false
			break

	if passed:
		print("  通过: 失败场景正常，得分 %d，回合 %d" % [result["score"], result["turns_used"]])

	return passed


static func _test_multiple_battles_different_seeds() -> bool:
	print("\n[测试] 多场战斗不同种子")
	var passed := true

	var config := _create_stage(150, 4, BlindType.Type.SMALL_BLIND)

	for seed_val in range(3):
		var sim := BattleSimulator.new()
		sim.setup(config, [], 100 + seed_val)

		var result := sim.run_full_battle()

		# 每场战斗不应崩溃
		if result["history"].size() == 0:
			push_error("失败: 种子 %d 无出牌记录" % seed_val)
			passed = false

		if result["score"] < 0:
			push_error("失败: 种子 %d 得分为负" % seed_val)
			passed = false

	if passed:
		print("  通过: 3 场战斗不同种子均正常")
	return passed
