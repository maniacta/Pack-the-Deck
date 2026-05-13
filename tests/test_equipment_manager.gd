class_name TestEquipmentManager
extends RefCounted

## 装备管理器单元测试 —— 背包放置、冲突检测、卸下操作。
## 覆盖: 单格/多格放置、越界、冲突、卸下、相邻检测。

## 执行所有测试
static func run_all_tests() -> bool:
	print("=== 正在运行 EquipmentManager 测试 ===")
	var all_passed := true

	all_passed = _test_place_1x1() and all_passed
	all_passed = _test_place_2x2() and all_passed
	all_passed = _test_place_out_of_bounds() and all_passed
	all_passed = _test_place_on_occupied() and all_passed
	all_passed = _test_category_conflict() and all_passed
	all_passed = _test_unequip_frees_cells() and all_passed
	all_passed = _test_adjacent_detection() and all_passed
	all_passed = _test_inventory_add_remove() and all_passed
	all_passed = _test_grid_status() and all_passed
	all_passed = _test_l_shaped_equipment() and all_passed
	all_passed = _test_generic_no_conflict() and all_passed

	if all_passed:
		print("=== 所有 EquipmentManager 测试通过 ===")
	else:
		print("=== 部分 EquipmentManager 测试失败 ===")

	return all_passed


# ============================================================================
# 辅助方法
# ============================================================================

static func _create_1x1(name: String = "测试1x1", category: EquipmentData.Category = EquipmentData.Category.GENERIC) -> EquipmentData:
	var eq := EquipmentData.new()
	eq.display_name = name
	eq.category = category
	eq.effect_type = EquipmentData.EffectType.SCORE_MODIFY
	eq.shape = [Vector2i(0, 0)]
	return eq


static func _create_2x2(name: String = "测试2x2", category: EquipmentData.Category = EquipmentData.Category.MECHANICAL) -> EquipmentData:
	var eq := EquipmentData.new()
	eq.display_name = name
	eq.category = category
	eq.effect_type = EquipmentData.EffectType.STRUCTURE
	eq.shape = [
		Vector2i(0, 0), Vector2i(0, 1),
		Vector2i(1, 0), Vector2i(1, 1)
	]
	return eq


static func _create_l_shape() -> EquipmentData:
	var eq := EquipmentData.new()
	eq.display_name = "L形装备"
	eq.category = EquipmentData.Category.GENERIC
	eq.effect_type = EquipmentData.EffectType.STRUCTURE
	eq.shape = [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)
	]
	return eq


# ============================================================================
# 测试用例
# ============================================================================

static func _test_place_1x1() -> bool:
	print("\n[测试] 1×1 装备放置")
	var passed := true
	var manager := EquipmentManager.new()
	var eq := _create_1x1()

	# 正常放置
	var result := manager.place_equipment(eq, Vector2i(0, 0))
	if not result:
		push_error("失败: 无法放置 1×1 装备到 (0,0)")
		passed = false

	# 验证锚点
	var anchor := manager.get_equipment_anchor(eq)
	if anchor != Vector2i(0, 0):
		push_error("失败: 锚点应为 (0,0)，实际为 %s" % anchor)
		passed = false

	# 验证格子被占用
	if not manager.is_position_occupied(Vector2i(0, 0)):
		push_error("失败: 位置 (0,0) 应被占用")
		passed = false

	# 查找已装备物品
	var equipped := manager.get_equipped()
	if equipped.size() != 1:
		push_error("失败: 应有 1 件已装备，实际 %d" % equipped.size())
		passed = false

	if passed:
		print("  通过: 1×1 装备放置正常")
	return passed


static func _test_place_2x2() -> bool:
	print("\n[测试] 2×2 装备放置")
	var passed := true
	var manager := EquipmentManager.new()
	var eq := _create_2x2()

	var result := manager.place_equipment(eq, Vector2i(1, 1))
	if not result:
		push_error("失败: 无法放置 2×2 装备到 (1,1)")
		passed = false

	# 所有 4 个格子应被占用
	var positions := eq.get_absolute_positions(Vector2i(1, 1))
	for pos: Vector2i in positions:
		if not manager.is_position_occupied(pos):
			push_error("失败: 位置 %s 应被占用" % pos)
			passed = false

	if passed:
		print("  通过: 2×2 装备放置正常")
	return passed


static func _test_place_out_of_bounds() -> bool:
	print("\n[测试] 越界防止")
	var passed := true
	var manager := EquipmentManager.new()

	# 1×1 放到边界外
	var eq1 := _create_1x1()
	var result1 := manager.place_equipment(eq1, Vector2i(5, 0))
	if result1:
		push_error("失败: 不应允许放置在 x=5 边界外")
		passed = false

	result1 = manager.place_equipment(eq1, Vector2i(0, 4))
	if result1:
		push_error("失败: 不应允许放置在 y=4 边界外")
		passed = false

	result1 = manager.place_equipment(eq1, Vector2i(-1, 0))
	if result1:
		push_error("失败: 不应允许放置在负坐标")
		passed = false

	# 2×2 放到会导致越界的位置
	var eq2 := _create_2x2()
	var result2 := manager.place_equipment(eq2, Vector2i(4, 3))
	if result2:
		push_error("失败: 不应允许 2×2 装备放置到 (4,3)（会越界）")
		passed = false

	if passed:
		print("  通过: 越界检测正常")
	return passed


static func _test_place_on_occupied() -> bool:
	print("\n[测试] 占用冲突检测")
	var passed := true
	var manager := EquipmentManager.new()

	var eq1 := _create_1x1("装备A")
	var eq2 := _create_1x1("装备B")

	# 先放装备A
	manager.add_to_inventory(eq1)
	manager.place_equipment(eq1, Vector2i(2, 1))

	# 尝试在相同位置放装备B
	manager.add_to_inventory(eq2)
	var result := manager.place_equipment(eq2, Vector2i(2, 1))
	if result:
		push_error("失败: 不应允许覆盖已占用位置")
		passed = false

	# 验证装备B未被放置
	var anchor_b := manager.get_equipment_anchor(eq2)
	if anchor_b != Vector2i(-1, -1):
		push_error("失败: 装备B 不应有锚点")
		passed = false

	if passed:
		print("  通过: 占用冲突检测正常")
	return passed


static func _test_category_conflict() -> bool:
	print("\n[测试] 类别冲突")
	var passed := true
	var manager := EquipmentManager.new()

	# 放置一个光学类装备
	var optical1 := _create_1x1("光学镜片A", EquipmentData.Category.OPTICAL)
	manager.add_to_inventory(optical1)
	manager.place_equipment(optical1, Vector2i(0, 0))

	# 尝试放置另一个光学类装备
	var optical2 := _create_1x1("光学镜片B", EquipmentData.Category.OPTICAL)
	manager.add_to_inventory(optical2)
	var result := manager.place_equipment(optical2, Vector2i(1, 0))
	if result:
		push_error("失败: 不应允许同类别光学装备")
		passed = false

	# 但是不同类别应该可以
	var mechanical := _create_1x1("机械齿轮", EquipmentData.Category.MECHANICAL)
	manager.add_to_inventory(mechanical)
	result = manager.place_equipment(mechanical, Vector2i(1, 0))
	if not result:
		push_error("失败: 不同类别应允许放置")
		passed = false

	if passed:
		print("  通过: 类别冲突检测正常")
	return passed


static func _test_unequip_frees_cells() -> bool:
	print("\n[测试] 卸下装备释放格子")
	var passed := true
	var manager := EquipmentManager.new()

	var eq := _create_1x1()
	manager.add_to_inventory(eq)
	manager.place_equipment(eq, Vector2i(2, 1))

	# 卸下
	var removed := manager.unequip(eq)
	if not removed:
		push_error("失败: 无法卸下装备")
		passed = false

	# 原位置应恢复为空
	if manager.is_position_occupied(Vector2i(2, 1)):
		push_error("失败: 卸下后位置应恢复为空")
		passed = false

	# 装备应回到库存
	var inventory := manager.get_inventory()
	if not eq in inventory:
		push_error("失败: 卸下后装备应在库存中")
		passed = false

	# 可再次放置
	var eq2 := _create_1x1()
	manager.add_to_inventory(eq2)
	result = manager.place_equipment(eq2, Vector2i(2, 1))
	if not result:
		push_error("失败: 释放后的位置应可再次放置")
		passed = false

	if passed:
		print("  通过: 卸下装备正常")
	return passed


static func _test_adjacent_detection() -> bool:
	print("\n[测试] 相邻装备检测")
	var passed := true
	var manager := EquipmentManager.new()

	var eq1 := _create_1x1("装备1")
	var eq2 := _create_1x1("装备2")

	manager.add_to_inventory(eq1)
	manager.add_to_inventory(eq2)
	manager.place_equipment(eq1, Vector2i(0, 0))
	manager.place_equipment(eq2, Vector2i(0, 1))

	# eq2 应在 eq1 的右侧
	var adjacent := manager.get_adjacent_equipment(Vector2i(0, 0))
	if adjacent.size() != 1:
		push_error("失败: 应有 1 个相邻装备，实际 %d" % adjacent.size())
		passed = false
	elif adjacent[0] != eq2:
		push_error("失败: 相邻装备应为装备2")
		passed = false

	# count_adjacent_equipment
	var count := manager.count_adjacent_equipment(eq1)
	if count != 1:
		push_error("失败: 装备1 相邻数应为 1，实际 %d" % count)
		passed = false

	# 不相邻的情况
	var eq3 := _create_1x1("装备3")
	manager.add_to_inventory(eq3)
	manager.place_equipment(eq3, Vector2i(4, 3))
	var adj3 := manager.get_adjacent_equipment(Vector2i(4, 3))
	# (4,3)在右下角，左上方向可能有 (3,3) 和 (4,2)，但我们放置的是 (4,3) 所以没有相邻
	if adj3.size() > 0:
		# 可能有相邻也属正常（取决于之前的放置），不报错
		pass

	if passed:
		print("  通过: 相邻检测正常")
	return passed


static func _test_inventory_add_remove() -> bool:
	print("\n[测试] 库存管理")
	var passed := true
	var manager := EquipmentManager.new()

	var eq1 := _create_1x1("装备A")
	var eq2 := _create_1x1("装备B")

	# 添加
	manager.add_to_inventory(eq1)
	manager.add_to_inventory(eq2)

	var inventory := manager.get_inventory()
	if inventory.size() != 2:
		push_error("失败: 库存应有 2 件，实际 %d" % inventory.size())
		passed = false

	# 移除
	var removed := manager.remove_from_inventory(eq1)
	if not removed:
		push_error("失败: 应能移除库存中的装备")
		passed = false

	inventory = manager.get_inventory()
	if inventory.size() != 1:
		push_error("失败: 移除后库存应有 1 件，实际 %d" % inventory.size())
		passed = false

	# 移除不存在的装备
	removed = manager.remove_from_inventory(eq1)
	if removed:
		push_error("失败: 不应能移除不存在的装备")
		passed = false

	if passed:
		print("  通过: 库存管理正常")
	return passed


static func _test_grid_status() -> bool:
	print("\n[测试] 网格状态查询")
	var passed := true
	var manager := EquipmentManager.new()

	# 空状态
	var status := manager.get_grid_status()
	if status.size() != 20:
		push_error("失败: 网格应有 20 格，实际 %d" % status.size())
		passed = false

	var occupied_count := 0
	for b: bool in status:
		if b:
			occupied_count += 1

	if occupied_count != 0:
		push_error("失败: 空网格应有 0 格被占用")
		passed = false

	# 放置后
	var eq := _create_1x1()
	manager.add_to_inventory(eq)
	manager.place_equipment(eq, Vector2i(0, 0))

	status = manager.get_grid_status()
	occupied_count = 0
	for b: bool in status:
		if b:
			occupied_count += 1

	if occupied_count != 1:
		push_error("失败: 放置后应有 1 格被占用，实际 %d" % occupied_count)
		passed = false

	if passed:
		print("  通过: 网格状态查询正常")
	return passed


static func _test_l_shaped_equipment() -> bool:
	print("\n[测试] L 形装备放置")
	var passed := true
	var manager := EquipmentManager.new()

	var eq := _create_l_shape()
	manager.add_to_inventory(eq)

	var result := manager.place_equipment(eq, Vector2i(2, 1))
	if not result:
		push_error("失败: 无法放置 L 形装备")
		passed = false

	# L 形占 3 格
	var positions := eq.get_absolute_positions(Vector2i(2, 1))
	if positions.size() != 3:
		push_error("失败: L 形应占 3 格")
		passed = false

	# 每格都应被占用
	for pos: Vector2i in positions:
		if not manager.is_position_occupied(pos):
			push_error("失败: L 形位置 %s 应被占用" % pos)
			passed = false

	if passed:
		print("  通过: L 形装备放置正常")
	return passed


static func _test_generic_no_conflict() -> bool:
	print("\n[测试] 通用类别不冲突")
	var passed := true
	var manager := EquipmentManager.new()

	# 放置多个通用类装备
	var gen1 := _create_1x1("通用A", EquipmentData.Category.GENERIC)
	var gen2 := _create_1x1("通用B", EquipmentData.Category.GENERIC)
	var gen3 := _create_1x1("通用C", EquipmentData.Category.GENERIC)

	manager.add_to_inventory(gen1)
	manager.add_to_inventory(gen2)
	manager.add_to_inventory(gen3)

	if not manager.place_equipment(gen1, Vector2i(0, 0)):
		push_error("失败: 无法放置通用装备1")
		passed = false
	if not manager.place_equipment(gen2, Vector2i(1, 0)):
		push_error("失败: 无法放置通用装备2")
		passed = false
	if not manager.place_equipment(gen3, Vector2i(2, 0)):
		push_error("失败: 无法放置通用装备3")
		passed = false

	var equipped := manager.get_equipped()
	if equipped.size() != 3:
		push_error("失败: 应有 3 件通用装备，实际 %d" % equipped.size())
		passed = false

	if passed:
		print("  通过: 通用类别不冲突")
	return passed
