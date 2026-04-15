class_name TestStageManager
extends RefCounted

## Test suite for StageManager class - validates stage progression and boss rules.

## Run all tests
static func run_all_tests() -> bool:
	print("\n========================================")
	print("StageManager 测试套件")
	print("========================================")
	
	var all_passed: bool = true
	
	# Test StageManager creation
	all_passed = _test_stage_manager_creation() and all_passed
	
	# Test stage loading
	all_passed = _test_stage_loading() and all_passed
	
	# Test stage progression
	all_passed = _test_stage_progression() and all_passed
	
	# Test gold management
	all_passed = _test_gold_management() and all_passed
	
	# Test equipment inventory
	all_passed = _test_equipment_inventory() and all_passed
	
	print("========================================")
	if all_passed:
		print("✓ StageManager 所有测试通过")
	else:
		print("✗ StageManager 测试失败")
	print("========================================\n")
	
	return all_passed


## Test StageManager creation
static func _test_stage_manager_creation() -> bool:
	print("\n[测试] StageManager 创建")
	
	var manager := StageManager.new()
	
	# Check initial state
	if manager.get_progress_state() != StageManager.ProgressState.NOT_STARTED:
		print("  ✗ 初始状态应为 NOT_STARTED")
		return false
	
	if manager.get_player_gold() != 0:
		print("  ✗ 初始金币应为 0")
		return false
	
	if manager.get_stages_completed() != 0:
		print("  ✗ 初始完成关卡数应为 0")
		return false
	
	print("  ✓ StageManager 创建测试通过")
	return true


## Test stage loading
static func _test_stage_loading() -> bool:
	print("\n[测试] 关卡加载")
	
	var manager := StageManager.new()
	
	# Start game (loads first stage)
	var first_stage: StageConfig = manager.start_game()
	
	if first_stage == null:
		print("  ✗ 无法加载第一关")
		return false
	
	if manager.get_progress_state() != StageManager.ProgressState.IN_PROGRESS:
		print("  ✗ 开始后状态应为 IN_PROGRESS")
		return false
	
	if manager.get_current_stage_index() != 0:
		print("  ✗ 当前关卡索引应为 0")
		return false
	
	# Check stage list
	var stages: Array[String] = manager.get_stage_list()
	if stages.size() < 1:
		print("  ✗ 关卡列表应有至少 1 个关卡")
		return false
	
	print("  ✓ 关卡加载测试通过")
	return true


## Test stage progression
static func _test_stage_progression() -> bool:
	print("\n[测试] 关卡进度")
	
	var manager := StageManager.new()
	manager.start_game()
	
	# Complete first stage
	var reward: int = 10  # Default reward for stage_1
	var next_stage: StageConfig = manager.complete_stage(150, reward)
	
	# Check progress after first stage
	if manager.get_stages_completed() != 1:
		print("  ✗ 完成关卡数应为 1")
		return false
	
	if manager.get_player_gold() != reward:
		print("  ✗ 金币应为 %d (获得奖励)" % reward)
		return false
	
	if manager.get_total_score() != 150:
		print("  ✗ 总得分应为 150")
		return false
	
	# Check if there's next stage
	if manager.has_next_stage():
		if next_stage == null:
			print("  ✗ 应返回下一关配置")
			return false
		
		if manager.get_current_stage_index() != 1:
			print("  ✗ 当前关卡索引应为 1")
			return false
	
	print("  ✓ 关卡进度测试通过")
	return true


## Test gold management
static func _test_gold_management() -> bool:
	print("\n[测试] 金币管理")
	
	var manager := StageManager.new()
	
	# Add gold
	manager.add_gold(50)
	if manager.get_player_gold() != 50:
		print("  ✗ 金币应为 50")
		return false
	
	# Spend gold successfully
	var success: bool = manager.spend_gold(30)
	if not success:
		print("  ✗ 应成功花费金币")
		return false
	
	if manager.get_player_gold() != 20:
		print("  ✗ 花费后金币应为 20")
		return false
	
	# Try spending more than available
	success = manager.spend_gold(100)
	if success:
		print("  ✗ 金币不足时应返回失败")
		return false
	
	if manager.get_player_gold() != 20:
		print("  ✗ 失败后金币应保持 20")
		return false
	
	print("  ✓ 金币管理测试通过")
	return true


## Test equipment inventory
static func _test_equipment_inventory() -> bool:
	print("\n[测试] 装备库存管理")
	
	var manager := StageManager.new()
	
	# Create test equipment
	var test_equipment := EquipmentData.new()
	test_equipment.display_name = "测试装备"
	
	# Add to inventory
	manager.add_equipment(test_equipment)
	
	var inventory: Array[EquipmentData] = manager.get_equipment_inventory()
	if inventory.size() != 1:
		print("  ✗ 库存应有 1 个装备")
		return false
	
	# Equip the item
	var equip_success: bool = manager.equip_item(test_equipment)
	if not equip_success:
		print("  ✗ 应成功装备")
		return false
	
	inventory = manager.get_equipment_inventory()
	if inventory.size() != 0:
		print("  ✗ 装备后库存应为空")
		return false
	
	var equipped: Array[EquipmentData] = manager.get_equipped_items()
	if equipped.size() != 1:
		print("  ✗ 已装备列表应有 1 个装备")
		return false
	
	# Unequip back to inventory
	var unequip_success: bool = manager.unequip_item(test_equipment)
	if not unequip_success:
		print("  ✗ 应成功卸下装备")
		return false
	
	inventory = manager.get_equipment_inventory()
	if inventory.size() != 1:
		print("  ✗ 卸下后库存应有 1 个装备")
		return false
	
	print("  ✓ 装备库存管理测试通过")
	return true


## Test progress reset
static func _test_progress_reset() -> bool:
	print("\n[测试] 进度重置")
	
	var manager := StageManager.new()
	manager.start_game()
	manager.add_gold(100)
	manager.complete_stage(150, 10)
	
	# Reset progress
	manager.reset_progress()
	
	if manager.get_current_stage_index() != 0:
		print("  ✗ 重置后关卡索引应为 0")
		return false
	
	# Gold should persist (for retry)
	if manager.get_player_gold() != 110:
		print("  ✗ 重置后金币应保留 (110)")
		return false
	
	# Full reset
	manager.full_reset()
	
	if manager.get_player_gold() != 0:
		print("  ✗ 完全重置后金币应为 0")
		return false
	
	print("  ✓ 进度重置测试通过")
	return true