class_name TestGameManager
extends RefCounted

## 游戏状态机单元测试 —— 状态转换、信号、防护逻辑。
## 覆盖: 初始状态、状态转换、重复状态防护、结束判定、游戏流程。


## 执行所有测试
static func run_all_tests() -> bool:
	print("=== 正在运行 GameManager 测试 ===")
	var all_passed := true

	all_passed = _test_initial_state() and all_passed
	all_passed = _test_start_game() and all_passed
	all_passed = _test_enter_shop() and all_passed
	all_passed = _test_same_state_no_reentry() and all_passed
	all_passed = _test_game_over() and all_passed
	all_passed = _test_stage_cleared_last() and all_passed
	all_passed = _test_stage_cleared_not_last() and all_passed
	all_passed = _test_can_play_cards() and all_passed
	all_passed = _test_full_game_cycle() and all_passed
	all_passed = _test_state_queries() and all_passed
	all_passed = _test_get_state_name_cn() and all_passed

	if all_passed:
		print("=== 所有 GameManager 测试通过 ===")
	else:
		print("=== 部分 GameManager 测试失败 ===")

	return all_passed


static func _test_initial_state() -> bool:
	print("\n[测试] 初始状态")
	var passed := true
	var gm := GameManager.new()

	if gm.current_state != GameManager.GameState.TITLE:
		push_error("失败: 初始状态应为 TITLE")
		passed = false
	if gm.can_play_cards():
		push_error("失败: TITLE 状态不应可出牌")
		passed = false
	if gm.is_game_ended():
		push_error("失败: 初始不应为结束状态")
		passed = false

	if passed:
		print("  通过: 初始状态正常")
	return passed


static func _test_start_game() -> bool:
	print("\n[测试] 开始游戏")
	var passed := true
	var gm := GameManager.new()

	var state_changed := false
	gm.state_changed.connect(func(_old, _new): state_changed = true)

	gm.start_game()

	if gm.current_state != GameManager.GameState.BATTLE:
		push_error("失败: 开始游戏后应进入 BATTLE 状态")
		passed = false
	if not gm.is_in_battle():
		push_error("失败: is_in_battle 应返回 true")
		passed = false
	if not gm.can_play_cards():
		push_error("失败: BATTLE 状态应可出牌")
		passed = false
	if not state_changed:
		push_error("失败: 应发出 state_changed 信号")
		passed = false

	if passed:
		print("  通过: 开始游戏正常")
	return passed


static func _test_enter_shop() -> bool:
	print("\n[测试] 进入商店")
	var passed := true
	var gm := GameManager.new()
	gm.start_game()

	var state_changed := false
	gm.state_changed.connect(func(_old, _new): state_changed = true)

	gm.enter_shop()

	if gm.current_state != GameManager.GameState.SHOP:
		push_error("失败: 应进入 SHOP 状态")
		passed = false
	if not gm.is_in_shop():
		push_error("失败: is_in_shop 应返回 true")
		passed = false
	if gm.can_play_cards():
		push_error("失败: SHOP 状态不应可出牌")
		passed = false

	# 从商店返回战斗
	gm.enter_battle()
	if gm.current_state != GameManager.GameState.BATTLE:
		push_error("失败: 应返回 BATTLE 状态")
		passed = false

	if passed:
		print("  通过: 商店转换正常")
	return passed


static func _test_same_state_no_reentry() -> bool:
	print("\n[测试] 重复状态不触发")
	var passed := true
	var gm := GameManager.new()
	gm.start_game()  # TITLE → BATTLE

	var change_count := 0
	gm.state_changed.connect(func(_old, _new): change_count += 1)

	# 尝试再次进入 BATTLE（相同状态）
	gm.change_state(GameManager.GameState.BATTLE)

	if change_count != 0:
		push_error("失败: 重复状态不应触发信号，实际触发 %d 次" % change_count)
		passed = false
	if gm.current_state != GameManager.GameState.BATTLE:
		push_error("失败: 状态应保持 BATTLE")
		passed = false

	if passed:
		print("  通过: 重复状态防护正常")
	return passed


static func _test_game_over() -> bool:
	print("\n[测试] 游戏失败")
	var passed := true
	var gm := GameManager.new()
	gm.start_game()

	gm.on_game_lost()

	if gm.current_state != GameManager.GameState.GAME_OVER:
		push_error("失败: 应进入 GAME_OVER 状态")
		passed = false
	if not gm.is_game_ended():
		push_error("失败: is_game_ended 应返回 true")
		passed = false
	if gm.is_game_completed():
		push_error("失败: 失败不应是通关")
		passed = false

	if passed:
		print("  通过: 游戏失败正常")
	return passed


static func _test_stage_cleared_last() -> bool:
	print("\n[测试] 最后关卡通关")
	var passed := true
	var gm := GameManager.new()
	gm.start_game()

	gm.on_stage_cleared(3, 3, true)  # 3/3，最后关卡

	if gm.current_state != GameManager.GameState.VICTORY:
		push_error("失败: 最后关卡通关应进入 VICTORY，实际 %s" % GameManager.get_state_name_cn(gm.current_state))
		passed = false
	if not gm.is_game_completed():
		push_error("失败: is_game_completed 应返回 true")
		passed = false

	if passed:
		print("  通过: 通关判定正常")
	return passed


static func _test_stage_cleared_not_last() -> bool:
	print("\n[测试] 非最后关卡通关")
	var passed := true
	var gm := GameManager.new()
	gm.start_game()

	gm.on_stage_cleared(1, 3, false)  # 1/3，不是最后

	if gm.current_state == GameManager.GameState.VICTORY:
		push_error("失败: 非最后关卡不应进入 VICTORY")
		passed = false
	if gm.is_game_completed():
		push_error("失败: 非最后关卡 is_game_completed 应返回 false")
		passed = false

	# 状态应保持 BATTLE（signal emitted but state unchanged）
	if gm.current_state != GameManager.GameState.BATTLE:
		push_error("失败: 非最后关卡状态应保持 BATTLE，实际 %s" % GameManager.get_state_name_cn(gm.current_state))
		passed = false

	if passed:
		print("  通过: 非最后关卡通关正常")
	return passed


static func _test_can_play_cards() -> bool:
	print("\n[测试] 出牌权限")
	var passed := true
	var gm := GameManager.new()

	# TITLE
	if gm.can_play_cards():
		push_error("失败: TITLE 不应可出牌")
		passed = false

	# BATTLE
	gm.start_game()
	if not gm.can_play_cards():
		push_error("失败: BATTLE 应可出牌")
		passed = false

	# SHOP
	gm.enter_shop()
	if gm.can_play_cards():
		push_error("失败: SHOP 不应可出牌")
		passed = false

	# GAME_OVER
	gm.on_game_lost()
	if gm.can_play_cards():
		push_error("失败: GAME_OVER 不应可出牌")
		passed = false

	if passed:
		print("  通过: 出牌权限正常")
	return passed


static func _test_full_game_cycle() -> bool:
	print("\n[测试] 完整游戏循环")
	var passed := true
	var gm := GameManager.new()

	var state_sequence: Array[GameManager.GameState] = []
	gm.state_changed.connect(func(_old, new: GameManager.GameState): state_sequence.append(new))

	# 完整流程: TITLE → BATTLE → SHOP → BATTLE → VICTORY
	gm.start_game()                                # → BATTLE
	gm.enter_shop()                                # → SHOP
	gm.enter_battle()                              # → BATTLE (下一关)
	gm.on_stage_cleared(3, 3, true)               # → VICTORY

	if gm.current_state != GameManager.GameState.VICTORY:
		push_error("失败: 最终状态应为 VICTORY")
		passed = false

	# 验证状态序列
	var expected := [
		GameManager.GameState.BATTLE,
		GameManager.GameState.SHOP,
		GameManager.GameState.BATTLE,
		GameManager.GameState.VICTORY
	]
	if state_sequence != expected:
		push_error("失败: 状态序列不匹配")
		push_error("  期望: %s" % expected)
		push_error("  实际: %s" % state_sequence)
		passed = false

	if passed:
		print("  通过: 完整游戏循环正常")
	return passed


static func _test_state_queries() -> bool:
	print("\n[测试] 状态查询")
	var passed := true
	var gm := GameManager.new()

	gm.start_game()
	if not gm.is_in_state(GameManager.GameState.BATTLE):
		push_error("失败: is_in_state(BATTLE) 应为 true")
		passed = false
	if gm.is_in_state(GameManager.GameState.TITLE):
		push_error("失败: is_in_state(TITLE) 应为 false")
		passed = false

	if gm.get_current_state_name() != "战斗":
		push_error("失败: 状态名应为 '战斗'，实际 '%s'" % gm.get_current_state_name())
		passed = false

	if passed:
		print("  通过: 状态查询正常")
	return passed


static func _test_get_state_name_cn() -> bool:
	print("\n[测试] 状态中文名")
	var passed := true

	if GameManager.get_state_name_cn(GameManager.GameState.TITLE) != "标题":
		push_error("失败: TITLE 中文名应为 '标题'")
		passed = false
	if GameManager.get_state_name_cn(GameManager.GameState.BATTLE) != "战斗":
		push_error("失败: BATTLE 中文名应为 '战斗'")
		passed = false
	if GameManager.get_state_name_cn(GameManager.GameState.SHOP) != "商店":
		push_error("失败: SHOP 中文名应为 '商店'")
		passed = false
	if GameManager.get_state_name_cn(GameManager.GameState.GAME_OVER) != "游戏结束":
		push_error("失败: GAME_OVER 中文名应为 '游戏结束'")
		passed = false
	if GameManager.get_state_name_cn(GameManager.GameState.VICTORY) != "胜利":
		push_error("失败: VICTORY 中文名应为 '胜利'")
		passed = false

	if passed:
		print("  通过: 状态中文名正常")
	return passed
