class_name TestStageConfig
extends RefCounted

## Test runner for StageConfig class.
## Verifies stage configuration and boss rules work correctly.

## Run all tests
static func run_all_tests() -> bool:
	print("=== Running StageConfig Tests ===")
	var all_passed := true
	
	all_passed = _test_stage_creation() and all_passed
	all_passed = _test_target_score_calculation() and all_passed
	all_passed = _test_reward_calculation() and all_passed
	all_passed = _test_boss_rules() and all_passed
	all_passed = _test_stage_description() and all_passed
	all_passed = _test_stage_validation() and all_passed
	all_passed = _test_factory_method() and all_passed
	
	if all_passed:
		print("=== All StageConfig tests PASSED ===")
	else:
		print("=== Some StageConfig tests FAILED ===")
	
	return all_passed


# ============================================================================
# Stage Creation Tests
# ============================================================================

## Test basic stage creation
static func _test_stage_creation() -> bool:
	print("\n[TEST] Stage Creation")
	var passed := true
	
	var stage := StageConfig.new()
	stage.stage_id = "test_stage"
	stage.display_name = "测试关卡"
	stage.base_target_score = 100
	stage.max_turns = 3
	stage.blind_type = BlindType.Type.SMALL_BLIND
	
	if stage.stage_id != "test_stage":
		push_error("FAIL: Stage ID should be 'test_stage'")
		passed = false
	if stage.display_name != "测试关卡":
		push_error("FAIL: Stage name should be '测试关卡'")
		passed = false
	if stage.base_target_score != 100:
		push_error("FAIL: Base target score should be 100")
		passed = false
	if stage.max_turns != 3:
		push_error("FAIL: Max turns should be 3")
		passed = false
	
	if passed:
		print("  PASS: Stage creation works correctly")
	return passed


# ============================================================================
# Target Score Calculation Tests
# ============================================================================

## Test target score with blind multiplier
static func _test_target_score_calculation() -> bool:
	print("\n[TEST] Target Score Calculation")
	var passed := true
	
	# Small blind: 100 × 1 = 100
	var small_stage := StageConfig.new()
	small_stage.base_target_score = 100
	small_stage.blind_type = BlindType.Type.SMALL_BLIND
	
	if small_stage.get_target_score() != 100:
		push_error("FAIL: Small blind target should be 100, got %d" % small_stage.get_target_score())
		passed = false
	
	# Big blind: 100 × 2 = 200
	var big_stage := StageConfig.new()
	big_stage.base_target_score = 100
	big_stage.blind_type = BlindType.Type.BIG_BLIND
	
	if big_stage.get_target_score() != 200:
		push_error("FAIL: Big blind target should be 200, got %d" % big_stage.get_target_score())
		passed = false
	
	# Boss blind: 100 × 3 = 300
	var boss_stage := StageConfig.new()
	boss_stage.base_target_score = 100
	boss_stage.blind_type = BlindType.Type.BOSS_BLIND
	
	if boss_stage.get_target_score() != 300:
		push_error("FAIL: Boss blind target should be 300, got %d" % boss_stage.get_target_score())
		passed = false
	
	if passed:
		print("  PASS: Target score calculation works correctly")
	return passed


# ============================================================================
# Reward Calculation Tests
# ============================================================================

## Test reward with blind multiplier
static func _test_reward_calculation() -> bool:
	print("\n[TEST] Stage Reward Calculation")
	var passed := true
	
	# Small blind: 10 × 1 = 10
	var small_stage := StageConfig.new()
	small_stage.base_reward = 10
	small_stage.blind_type = BlindType.Type.SMALL_BLIND
	
	if small_stage.get_reward() != 10:
		push_error("FAIL: Small blind reward should be 10, got %d" % small_stage.get_reward())
		passed = false
	
	# Big blind: 10 × 2 = 20
	var big_stage := StageConfig.new()
	big_stage.base_reward = 10
	big_stage.blind_type = BlindType.Type.BIG_BLIND
	
	if big_stage.get_reward() != 20:
		push_error("FAIL: Big blind reward should be 20, got %d" % big_stage.get_reward())
		passed = false
	
	# Boss blind: 10 × 3 = 30
	var boss_stage := StageConfig.new()
	boss_stage.base_reward = 10
	boss_stage.blind_type = BlindType.Type.BOSS_BLIND
	
	if boss_stage.get_reward() != 30:
		push_error("FAIL: Boss blind reward should be 30, got %d" % boss_stage.get_reward())
		passed = false
	
	if passed:
		print("  PASS: Reward calculation works correctly")
	return passed


# ============================================================================
# Boss Rules Tests
# ============================================================================

## Test boss special rules
static func _test_boss_rules() -> bool:
	print("\n[TEST] Boss Special Rules")
	var passed := true
	
	# Stage without boss rule
	var normal_stage := StageConfig.new()
	normal_stage.blind_type = BlindType.Type.SMALL_BLIND
	normal_stage.boss_rule = StageConfig.BossRule.NONE
	
	if normal_stage.has_boss_rule() != false:
		push_error("FAIL: Normal stage should NOT have boss rule")
		passed = false
	
	# Boss stage with suit excluded rule
	var suit_stage := StageConfig.new()
	suit_stage.blind_type = BlindType.Type.BOSS_BLIND
	suit_stage.boss_rule = StageConfig.BossRule.SUIT_EXCLUDED
	suit_stage.boss_rule_param = {"suit_name": "方块"}
	
	if suit_stage.has_boss_rule() != true:
		push_error("FAIL: Boss stage with rule should have boss rule")
		passed = false
	
	var desc := suit_stage.get_boss_rule_description()
	if not desc.contains("方块"):
		push_error("FAIL: Boss rule description should contain '方块'")
		passed = false
	if not desc.contains("不计分"):
		push_error("FAIL: Boss rule description should contain '不计分'")
		passed = false
	
	# Boss stage with hand type excluded
	var hand_stage := StageConfig.new()
	hand_stage.blind_type = BlindType.Type.BOSS_BLIND
	hand_stage.boss_rule = StageConfig.BossRule.HAND_TYPE_EXCLUDED
	hand_stage.boss_rule_param = {"hand_name": "顺子"}
	
	var hand_desc := hand_stage.get_boss_rule_description()
	if not hand_desc.contains("顺子"):
		push_error("FAIL: Hand excluded description should contain '顺子'")
		passed = false
	
	# Boss stage with play limit
	var limit_stage := StageConfig.new()
	limit_stage.blind_type = BlindType.Type.BOSS_BLIND
	limit_stage.boss_rule = StageConfig.BossRule.PLAY_LIMIT
	limit_stage.boss_rule_param = {"limit": 3}
	
	var limit_desc := limit_stage.get_boss_rule_description()
	if not limit_desc.contains("3"):
		push_error("FAIL: Play limit description should contain '3'")
		passed = false
	if not limit_desc.contains("出牌"):
		push_error("FAIL: Play limit description should contain '出牌'")
		passed = false
	
	# Boss stage with NO rule (valid but should warn)
	var no_rule_boss := StageConfig.new()
	no_rule_boss.blind_type = BlindType.Type.BOSS_BLIND
	no_rule_boss.boss_rule = StageConfig.BossRule.NONE
	
	if no_rule_boss.has_boss_rule() != false:
		push_error("FAIL: Boss without special rule should NOT have boss rule")
		passed = false
	
	if passed:
		print("  PASS: Boss rules work correctly")
	return passed


# ============================================================================
# Stage Description Tests
# ============================================================================

## Test stage full description
static func _test_stage_description() -> bool:
	print("\n[TEST] Stage Full Description")
	var passed := true
	
	var stage := StageConfig.new()
	stage.display_name = "第一关"
	stage.base_target_score = 100
	stage.max_turns = 3
	stage.blind_type = BlindType.Type.SMALL_BLIND
	stage.base_reward = 10
	
	var full_desc := stage.get_full_description()
	
	# Should contain all key info
	if not full_desc.contains("第一关"):
		push_error("FAIL: Full description should contain stage name")
		passed = false
	if not full_desc.contains("100"):
		push_error("FAIL: Full description should contain target score")
		passed = false
	if not full_desc.contains("3"):
		push_error("FAIL: Full description should contain turn limit")
		passed = false
	if not full_desc.contains("小盲注"):
		push_error("FAIL: Full description should contain blind type")
		passed = false
	if not full_desc.contains("金币"):
		push_error("FAIL: Full description should contain reward info")
		passed = false
	
	# Boss stage description
	var boss_stage := StageConfig.new()
	boss_stage.display_name = "Boss关卡"
	boss_stage.base_target_score = 500
	boss_stage.max_turns = 4
	boss_stage.blind_type = BlindType.Type.BOSS_BLIND
	boss_stage.boss_rule = StageConfig.BossRule.SUIT_EXCLUDED
	boss_stage.boss_rule_param = {"suit_name": "方块"}
	
	var boss_desc := boss_stage.get_full_description()
	if not boss_desc.contains("特殊规则"):
		push_error("FAIL: Boss description should contain '特殊规则'")
		passed = false
	if not boss_desc.contains("方块不计分"):
		push_error("FAIL: Boss description should contain boss rule")
		passed = false
	
	if passed:
		print("  PASS: Stage description works correctly")
	return passed


# ============================================================================
# Validation Tests
# ============================================================================

## Test stage validation
static func _test_stage_validation() -> bool:
	print("\n[TEST] Stage Validation")
	var passed := true
	
	# Valid stage
	var valid_stage := StageConfig.new()
	valid_stage.base_target_score = 100
	valid_stage.max_turns = 3
	
	if valid_stage.is_valid() != true:
		push_error("FAIL: Valid stage should pass validation")
		passed = false
	
	# Invalid: zero target score
	var zero_target := StageConfig.new()
	zero_target.base_target_score = 0
	zero_target.max_turns = 3
	
	if zero_target.is_valid() != false:
		push_error("FAIL: Zero target score should fail validation")
		passed = false
	
	# Invalid: zero turns
	var zero_turns := StageConfig.new()
	zero_turns.base_target_score = 100
	zero_turns.max_turns = 0
	
	if zero_turns.is_valid() != false:
		push_error("FAIL: Zero turns should fail validation")
		passed = false
	
	if passed:
		print("  PASS: Stage validation works correctly")
	return passed


# ============================================================================
# Factory Method Tests
# ============================================================================

## Test factory method for quick stage creation
static func _test_factory_method() -> bool:
	print("\n[TEST] Factory Method")
	var passed := true
	
	var quick_stage := StageConfig.create_test_stage(
		"quick_1",
		"快速测试关",
		150,
		4,
		BlindType.Type.BIG_BLIND
	)
	
	if quick_stage.stage_id != "quick_1":
		push_error("FAIL: Factory stage ID should be 'quick_1'")
		passed = false
	if quick_stage.display_name != "快速测试关":
		push_error("FAIL: Factory stage name should be '快速测试关'")
		passed = false
	if quick_stage.base_target_score != 150:
		push_error("FAIL: Factory base target should be 150")
		passed = false
	if quick_stage.max_turns != 4:
		push_error("FAIL: Factory turns should be 4")
		passed = false
	if quick_stage.blind_type != BlindType.Type.BIG_BLIND:
		push_error("FAIL: Factory blind type should be BIG_BLIND")
		passed = false
	if quick_stage.get_target_score() != 300:
		push_error("FAIL: Factory target score should be 300 (150 × 2)")
		passed = false
	
	if passed:
		print("  PASS: Factory method works correctly")
	return passed