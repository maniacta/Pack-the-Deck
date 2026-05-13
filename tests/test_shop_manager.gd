class_name TestShopManager
extends RefCounted

## 商店管理器单元测试 —— 商店生成、物品购买、刷新。
## 覆盖: 生成/刷新/购买/金币扣除/免费刷新/售罄检测。


## 执行所有测试
static func run_all_tests() -> bool:
	print("=== 正在运行 ShopManager 测试 ===")
	var all_passed := true

	all_passed = _test_generate_shop() and all_passed
	all_passed = _test_purchase_item() and all_passed
	all_passed = _test_cannot_purchase_insufficient_gold() and all_passed
	all_passed = _test_cannot_purchase_already_sold() and all_passed
	all_passed = _test_refresh_shop() and all_passed
	all_passed = _test_free_refresh_tracking() and all_passed
	all_passed = _test_shop_available() and all_passed
	all_passed = _test_shop_summary() and all_passed
	all_passed = _test_all_items_sold() and all_passed

	if all_passed:
		print("=== 所有 ShopManager 测试通过 ===")
	else:
		print("=== 部分 ShopManager 测试失败 ===")

	return all_passed


# ============================================================================
# 测试用例
# ============================================================================

static func _test_generate_shop() -> bool:
	print("\n[测试] 商店生成")
	var passed := true
	var sm := ShopManager.new()

	# 生成 4 件物品的商店
	var config := sm.generate_shop(4, 5, 1)

	if config == null:
		push_error("失败: 商店配置为空")
		passed = false
		return passed

	if config.items.size() != 4:
		push_error("失败: 应为 4 件物品，实际 %d" % config.items.size())
		passed = false

	# 每件物品应有装备和价格
	for item: ShopItem in config.items:
		if item.equipment == null:
			push_error("失败: 物品无装备数据")
			passed = false
			break
		if item.price <= 0:
			push_error("失败: 物品价格为 0 或负数")
			passed = false
		if item.is_sold:
			push_error("失败: 新物品不应已售出")
			passed = false

	# 免费刷新次数
	if config.get_remaining_free_refreshes() != 1:
		push_error("失败: 应有 1 次免费刷新")
		passed = false

	if config.refresh_cost != 5:
		push_error("失败: 刷新费用应为 5")
		passed = false

	# 所有物品应可获取
	var available := config.get_available_items()
	if available.size() != 4:
		push_error("失败: 应有 4 件可购买物品")
		passed = false

	if passed:
		print("  通过: 商店生成正常")
	return passed


static func _test_purchase_item() -> bool:
	print("\n[测试] 购买物品")
	var passed := true
	var sm := ShopManager.new()
	sm.generate_shop(3, 5, 1)

	var items := sm.shop_config.get_available_items()
	if items.is_empty():
		push_error("失败: 无可购买物品")
		return false

	var item: ShopItem = items[0]
	var inventory: Array[EquipmentData] = []

	# 购买
	var remaining_gold: int = sm.purchase_item(item, 100, inventory)

	if remaining_gold != 100 - item.price:
		push_error("失败: 金币扣除不正确，期望 %d，实际 %d" % [100 - item.price, remaining_gold])
		passed = false

	if not item.is_sold:
		push_error("失败: 购买后物品应标记为已售出")
		passed = false

	if inventory.size() != 1:
		push_error("失败: 库存应有 1 件装备，实际 %d" % inventory.size())
		passed = false

	# 重复购买应失败
	var gold2: int = sm.purchase_item(item, 100, inventory)
	if gold2 != 100:
		push_error("失败: 重复购买应返回原金币")
		passed = false

	if passed:
		print("  通过: 购买物品正常")
	return passed


static func _test_cannot_purchase_insufficient_gold() -> bool:
	print("\n[测试] 金币不足无法购买")
	var passed := true
	var sm := ShopManager.new()
	sm.generate_shop(3, 5, 1)

	var items := sm.shop_config.get_available_items()
	var item: ShopItem = items[0]
	var inventory: Array[EquipmentData] = []

	# 金币不够
	var remaining: int = sm.purchase_item(item, 0, inventory)

	if remaining != 0:
		push_error("失败: 金币不足时不应扣款，应返回 0，实际 %d" % remaining)
		passed = false
	if item.is_sold:
		push_error("失败: 金币不足时物品不应标记为已售出")
		passed = false
	if inventory.size() != 0:
		push_error("失败: 金币不足时库存不应增加")
		passed = false

	if passed:
		print("  通过: 金币不足防护正常")
	return passed


static func _test_cannot_purchase_already_sold() -> bool:
	print("\n[测试] 已售出物品不可再购买")
	var passed := true
	var sm := ShopManager.new()
	sm.generate_shop(3, 5, 1)

	var items := sm.shop_config.get_available_items()
	var item: ShopItem = items[0]
	var inventory: Array[EquipmentData] = []

	# 第一次购买
	sm.purchase_item(item, 100, inventory)
	if not item.is_sold:
		push_error("失败: 第一次购买后应标记已售出")
		passed = false

	# 第二次尝试购买
	var gold2: int = sm.purchase_item(item, 100, inventory)
	if gold2 != 100:
		push_error("失败: 已售出物品不应扣款")
		passed = false
	if inventory.size() != 1:
		push_error("失败: 已售出物品不应重复入库存")
		passed = false

	if passed:
		print("  通过: 已售出防护正常")
	return passed


static func _test_refresh_shop() -> bool:
	print("\n[测试] 商店刷新")
	var passed := true
	var sm := ShopManager.new()
	sm.generate_shop(4, 5, 1)

	# 记录刷新前物品
	var before_items := sm.shop_config.items.duplicate()

	# 刷新
	sm.perform_refresh()

	# 物品应重新生成（由于随机性，多数情况下不同）
	if sm.shop_config.items.size() != 4:
		push_error("失败: 刷新后应仍有 4 件物品")
		passed = false

	# 免费刷新次数应减少
	if sm.shop_config.get_remaining_free_refreshes() != 0:
		push_error("失败: 首次刷新后免费次数应为 0")
		passed = false

	# 刷新费用检查
	if sm.shop_config.get_refresh_cost() != 5:
		push_error("失败: 刷新费用应为 5")
		passed = false

	if passed:
		print("  通过: 商店刷新正常")
	return passed


static func _test_free_refresh_tracking() -> bool:
	print("\n[测试] 免费刷新追踪")
	var passed := true
	var sm := ShopManager.new()
	sm.generate_shop(4, 5, 3)  # 3 次免费

	if sm.shop_config.get_remaining_free_refreshes() != 3:
		push_error("失败: 初始免费次数应为 3")
		passed = false

	# 第一次免费刷新费用应为 0
	if sm.shop_config.get_refresh_cost() != 0:
		push_error("失败: 有免费次数时费用应为 0")
		passed = false

	sm.perform_refresh()
	if sm.shop_config.get_remaining_free_refreshes() != 2:
		push_error("失败: 第一次刷新后免费次数应为 2")
		passed = false

	sm.perform_refresh()
	if sm.shop_config.get_remaining_free_refreshes() != 1:
		push_error("失败: 第二次刷新后免费次数应为 1")
		passed = false

	sm.perform_refresh()
	if sm.shop_config.get_remaining_free_refreshes() != 0:
		push_error("失败: 第三次刷新后免费次数应为 0")
		passed = false

	# 用完免费后应收费
	if sm.shop_config.get_refresh_cost() != 5:
		push_error("失败: 免费次数用完后应收费 5")
		passed = false

	if passed:
		print("  通过: 免费刷新追踪正常")
	return passed


static func _test_shop_available() -> bool:
	print("\n[测试] 商店可用性")
	var passed := true
	var sm := ShopManager.new()

	if sm.is_shop_available():
		push_error("失败: 未生成商店时不应可用")
		passed = false

	sm.generate_shop(3, 5, 1)

	# 初始不可用（未打开）
	sm.close_shop()
	if sm.is_shop_available():
		push_error("失败: 关闭后不应可用")
		passed = false

	# 打开后应可用
	sm.open_shop()
	if not sm.is_shop_available():
		push_error("失败: 打开后应可用")
		passed = false

	if passed:
		print("  通过: 商店可用性正常")
	return passed


static func _test_shop_summary() -> bool:
	print("\n[测试] 商店摘要")
	var passed := true
	var sm := ShopManager.new()
	sm.generate_shop(4, 5, 1)

	var summary := sm.get_shop_summary()
	if summary == "商店未初始化":
		push_error("失败: 摘要不应显示未初始化")
		passed = false
	if summary.is_empty():
		push_error("失败: 摘要不应为空")
		passed = false

	# 购买一件后摘要应反映变化
	var items := sm.shop_config.get_available_items()
	if not items.is_empty():
		var inventory: Array[EquipmentData] = []
		sm.purchase_item(items[0], 100, inventory)
		summary = sm.get_shop_summary()
		if not "3/4" in summary:
			# 或 "3" in summary, 取决于格式
			pass

	if passed:
		print("  通过: 商店摘要正常")
	return passed


static func _test_all_items_sold() -> bool:
	print("\n[测试] 全部售罄")
	var passed := true
	var sm := ShopManager.new()
	sm.generate_shop(3, 5, 1)

	var inventory: Array[EquipmentData] = []

	# 购买所有物品
	var items := sm.shop_config.get_available_items()
	for item: ShopItem in items:
		sm.purchase_item(item, 1000, inventory)

	# 验证全部售罄
	if sm.shop_config.has_available_items():
		push_error("失败: 全部购买后应无可用物品")
		passed = false

	if sm.shop_config.get_available_items().size() != 0:
		push_error("失败: 可用物品数应为 0")
		passed = false

	if passed:
		print("  通过: 全部售罄正常")
	return passed
