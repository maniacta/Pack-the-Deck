class_name TestHandManager
extends RefCounted

## 手牌管理器单元测试 —— 手牌添加/移除、选牌状态、容量限制。
## 覆盖: 添加/移除手牌、切换选中、上限检查、清除、信号。


static func _create_card(rank: CardData.Rank, suit: CardData.Suit = CardData.Suit.SPADES) -> CardData:
	var card := CardData.new()
	card.rank = rank
	card.suit = suit
	return card


## 执行所有测试
static func run_all_tests() -> bool:
	print("=== 正在运行 HandManager 测试 ===")
	var all_passed := true

	all_passed = _test_add_hand() and all_passed
	all_passed = _test_hand_full() and all_passed
	all_passed = _test_remove_hand() and all_passed
	all_passed = _test_toggle_selection() and all_passed
	all_passed = _test_selection_full() and all_passed
	all_passed = _test_deselect_card() and all_passed
	all_passed = _test_clear_selection() and all_passed
	all_passed = _test_clear_all() and all_passed
	all_passed = _test_set_capacity() and all_passed
	all_passed = _test_null_card_rejected() and all_passed

	if all_passed:
		print("=== 所有 HandManager 测试通过 ===")
	else:
		print("=== 部分 HandManager 测试失败 ===")

	return all_passed


static func _test_add_hand() -> bool:
	print("\n[测试] 添加手牌")
	var passed := true
	var hm := HandManager.new()

	var cards: Array[CardData] = [
		_create_card(CardData.Rank.ACE),
		_create_card(CardData.Rank.KING),
		_create_card(CardData.Rank.QUEEN)
	]
	hm.add_to_hand(cards)

	if hm.get_hand_size() != 3:
		push_error("失败: 手牌应为 3 张，实际 %d" % hm.get_hand_size())
		passed = false

	if not hm.has_selection() == false:
		# has_selection should be false since nothing selected
		if hm.has_selection():
			push_error("失败: 不应有选中的牌")
			passed = false

	if passed:
		print("  通过: 添加手牌正常")
	return passed


static func _test_hand_full() -> bool:
	print("\n[测试] 手牌上限")
	var passed := true
	var hm := HandManager.new()
	hm.max_hand_size = 5

	# 添加 5 张
	var cards: Array[CardData] = []
	for i in range(5):
		cards.append(_create_card(CardData.Rank.TWO + i as CardData.Rank))
	hm.add_to_hand(cards)

	if hm.get_hand_size() != 5:
		push_error("失败: 手牌应为 5 张")
		passed = false

	if not hm.is_hand_full():
		push_error("失败: 手牌应为已满状态")
		passed = false

	# 尝试添加第 6 张
	var extra: Array[CardData] = [_create_card(CardData.Rank.ACE)]
	hm.add_to_hand(extra)

	if hm.get_hand_size() != 5:
		push_error("失败: 手牌不应超过 5 张，实际 %d" % hm.get_hand_size())
		passed = false

	if passed:
		print("  通过: 手牌上限正常")
	return passed


static func _test_remove_hand() -> bool:
	print("\n[测试] 移除手牌")
	var passed := true
	var hm := HandManager.new()

	var card1 := _create_card(CardData.Rank.ACE)
	var card2 := _create_card(CardData.Rank.KING)
	hm.add_to_hand([card1, card2])

	hm.remove_from_hand([card1])
	if hm.get_hand_size() != 1:
		push_error("失败: 移除后应为 1 张，实际 %d" % hm.get_hand_size())
		passed = false

	# 移除不存在的牌不应崩溃
	hm.remove_from_hand([_create_card(CardData.Rank.QUEEN)])
	if hm.get_hand_size() != 1:
		push_error("失败: 移除不存在的牌不应影响手牌数")
		passed = false

	if passed:
		print("  通过: 移除手牌正常")
	return passed


static func _test_toggle_selection() -> bool:
	print("\n[测试] 切换选中")
	var passed := true
	var hm := HandManager.new()

	var card1 := _create_card(CardData.Rank.ACE)
	var card2 := _create_card(CardData.Rank.KING)
	hm.add_to_hand([card1, card2])

	# 选中 card1
	var changed := hm.toggle_selection(card1)
	if not changed:
		push_error("失败: 选中应返回 true")
		passed = false
	if not hm.is_selected(card1):
		push_error("失败: card1 应被选中")
		passed = false
	if hm.get_selection_size() != 1:
		push_error("失败: 选中数应为 1，实际 %d" % hm.get_selection_size())
		passed = false

	# 选中 card2
	changed = hm.toggle_selection(card2)
	if not changed:
		push_error("失败: 第二次选中应返回 true")
		passed = false
	if hm.get_selection_size() != 2:
		push_error("失败: 选中数应为 2，实际 %d" % hm.get_selection_size())
		passed = false

	if passed:
		print("  通过: 切换选中正常")
	return passed


static func _test_selection_full() -> bool:
	print("\n[测试] 选牌上限")
	var passed := true
	var hm := HandManager.new()
	hm.max_selection_size = 3

	# 添加 5 张手牌
	var cards: Array[CardData] = []
	for i in range(5):
		cards.append(_create_card(CardData.Rank.TWO + i as CardData.Rank))
	hm.add_to_hand(cards)

	# 选中 3 张
	hm.toggle_selection(cards[0])
	hm.toggle_selection(cards[1])
	hm.toggle_selection(cards[2])

	if not hm.is_selection_full():
		push_error("失败: 选牌应为已满")
		passed = false

	# 尝试选第 4 张
	var changed := hm.toggle_selection(cards[3])
	if changed:
		push_error("失败: 不应能选中第 4 张牌")
		passed = false

	if hm.get_selection_size() != 3:
		push_error("失败: 选牌数应保持 3，实际 %d" % hm.get_selection_size())
		passed = false

	if passed:
		print("  通过: 选牌上限正常")
	return passed


static func _test_deselect_card() -> bool:
	print("\n[测试] 取消选中")
	var passed := true
	var hm := HandManager.new()

	var card := _create_card(CardData.Rank.ACE)
	hm.add_to_hand([card])

	# 先选中
	hm.toggle_selection(card)
	if not hm.is_selected(card):
		push_error("失败: 选中后应为选中状态")
		passed = false

	# 取消选中
	var changed := hm.toggle_selection(card)
	if not changed:
		push_error("失败: 取消选中应返回 true")
		passed = false
	if hm.is_selected(card):
		push_error("失败: 取消后不应选中")
		passed = false
	if hm.get_selection_size() != 0:
		push_error("失败: 选中数应为 0，实际 %d" % hm.get_selection_size())
		passed = false

	if passed:
		print("  通过: 取消选中正常")
	return passed


static func _test_clear_selection() -> bool:
	print("\n[测试] 清除选中")
	var passed := true
	var hm := HandManager.new()

	var cards: Array[CardData] = [
		_create_card(CardData.Rank.ACE),
		_create_card(CardData.Rank.KING)
	]
	hm.add_to_hand(cards)
	hm.toggle_selection(cards[0])
	hm.toggle_selection(cards[1])

	hm.clear_selection()
	if hm.get_selection_size() != 0:
		push_error("失败: 清除后选中数应为 0")
		passed = false
	if hm.has_selection():
		push_error("失败: 清除后不应有选中")
		passed = false

	# 手牌不应受影响
	if hm.get_hand_size() != 2:
		push_error("失败: 清除选中不应影响手牌数")
		passed = false

	if passed:
		print("  通过: 清除选中正常")
	return passed


static func _test_clear_all() -> bool:
	print("\n[测试] 全部清除")
	var passed := true
	var hm := HandManager.new()

	var cards: Array[CardData] = [
		_create_card(CardData.Rank.ACE),
		_create_card(CardData.Rank.KING)
	]
	hm.add_to_hand(cards)
	hm.toggle_selection(cards[0])

	hm.clear_all()
	if hm.get_hand_size() != 0:
		push_error("失败: 清除后手牌应为 0")
		passed = false
	if hm.get_selection_size() != 0:
		push_error("失败: 清除后选中应为 0")
		passed = false

	if passed:
		print("  通过: 全部清除正常")
	return passed


static func _test_set_capacity() -> bool:
	print("\n[测试] 容量设置")
	var passed := true
	var hm := HandManager.new()

	hm.set_capacity(8, 5)
	if hm.max_hand_size != 8:
		push_error("失败: 手牌容量应为 8")
		passed = false
	if hm.max_selection_size != 5:
		push_error("失败: 选牌容量应为 5")
		passed = false

	if passed:
		print("  通过: 容量设置正常")
	return passed


static func _test_null_card_rejected() -> bool:
	print("\n[测试] 空卡牌拒绝")
	var passed := true
	var hm := HandManager.new()

	# 不应因空卡牌而崩溃
	hm.add_to_hand([])
	if hm.get_hand_size() != 0:
		push_error("失败: 添加空数组不应改变手牌")
		passed = false

	var changed := hm.toggle_selection(null)
	if changed:
		push_error("失败: 不应能选中 null 卡牌")
		passed = false

	hm.remove_from_hand([])
	# 不应崩溃

	if passed:
		print("  通过: 空卡牌拒绝正常")
	return passed
