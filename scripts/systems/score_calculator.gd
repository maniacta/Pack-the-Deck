class_name ScoreCalculator
extends RefCounted

## Score calculator for poker hands.
## Integrates base score calculation with blind multipliers and equipment effects.

## Calculate the final score for a hand result with blind multiplier
## Formula: (base_score × hand_multiplier) × blind_multiplier
static func calculate_score(hand_result: HandType.HandResult, blind_type: BlindType.Type) -> int:
	if not hand_result.is_valid:
		return 0
	
	var base_score: int = hand_result.get_total_score()
	var blind_multiplier: int = BlindType.get_target_multiplier(blind_type)
	
	return base_score * blind_multiplier


## Calculate score with equipment modifiers (for future expansion)
## This method accepts a dictionary of modifiers for equipment effects
static func calculate_score_with_modifiers(
	hand_result: HandType.HandResult,
	blind_type: BlindType.Type,
	modifiers: Dictionary = {}
) -> int:
	if not hand_result.is_valid:
		return 0
	
	var base_score: int = hand_result.base_score
	var hand_multiplier: int = hand_result.multiplier
	var blind_multiplier: int = BlindType.get_target_multiplier(blind_type)
	
	# Apply equipment score bonus (additive)
	var score_bonus: int = modifiers.get("score_bonus", 0)
	base_score += score_bonus
	
	# Apply equipment multiplier bonus (multiplicative)
	var multiplier_bonus: float = modifiers.get("multiplier_bonus", 1.0)
	hand_multiplier = int(hand_multiplier * multiplier_bonus)
	
	# Calculate final score
	return base_score * hand_multiplier * blind_multiplier


## Check if player has passed the target score
static func check_victory(current_score: int, target_score: int) -> bool:
	return current_score >= target_score


## Calculate reward for passing a stage
static func calculate_reward(blind_type: BlindType.Type, base_reward: int) -> int:
	return base_reward * BlindType.get_reward_multiplier(blind_type)


## Get a formatted score display string
static func format_score_display(
	hand_result: HandType.HandResult,
	blind_type: BlindType.Type
) -> String:
	if not hand_result.is_valid:
		return "无效牌型 - 0 分"
	
	var base_score: int = hand_result.base_score
	var hand_mult: int = hand_result.multiplier
	var blind_mult: int = BlindType.get_target_multiplier(blind_type)
	var final_score: int = calculate_score(hand_result, blind_type)
	
	return "%s: %d × %d × %d = %d 分" % [
		hand_result.get_display_name_cn(),
		base_score,
		hand_mult,
		blind_mult,
		final_score
	]


## Score breakdown for detailed display
class ScoreBreakdown extends RefCounted:
	
	## The hand result being scored
	var hand_result: HandType.HandResult
	
	## The blind type multiplier
	var blind_type: BlindType.Type
	
	## Base score from cards
	var card_base_score: int = 0
	
	## Hand type multiplier
	var hand_multiplier: int = 1
	
	## Blind type multiplier
	var blind_multiplier: int = 1
	
	## Equipment score bonus
	var equipment_score_bonus: int = 0
	
	## Equipment multiplier bonus
	var equipment_multiplier_bonus: float = 1.0
	
	## Final calculated score
	var final_score: int = 0
	
	
	func _init(p_hand_result: HandType.HandResult, p_blind_type: BlindType.Type) -> void:
		hand_result = p_hand_result
		blind_type = p_blind_type
		_calculate_breakdown()
	
	
	func _calculate_breakdown() -> void:
		if not hand_result.is_valid:
			final_score = 0
			return
		
		card_base_score = hand_result.base_score
		hand_multiplier = hand_result.multiplier
		blind_multiplier = BlindType.get_target_multiplier(blind_type)
		
		# Calculate: (card_score + bonus) × hand_mult × equip_mult × blind_mult
		var adjusted_base: int = card_base_score + equipment_score_bonus
		var adjusted_hand_mult: int = int(hand_multiplier * equipment_multiplier_bonus)
		
		final_score = adjusted_base * adjusted_hand_mult * blind_multiplier
	
	
	func apply_equipment_bonus(score_bonus: int, mult_bonus: float) -> void:
		equipment_score_bonus = score_bonus
		equipment_multiplier_bonus = mult_bonus
		_calculate_breakdown()
	
	
	func get_display_string() -> String:
		if not hand_result.is_valid:
			return "无效牌型"
		
		var parts: Array[String] = []
		parts.append("%s" % hand_result.get_display_name_cn())
		parts.append("卡牌基础分: %d" % card_base_score)
		
		if equipment_score_bonus > 0:
			parts.append("装备加成: +%d" % equipment_score_bonus)
		
		parts.append("牌型倍率: ×%d" % hand_multiplier)
		
		if equipment_multiplier_bonus > 1.0:
			parts.append("装备倍率: ×%.1f" % equipment_multiplier_bonus)
		
		parts.append("盲注倍率: ×%d" % blind_multiplier)
		parts.append("最终得分: %d" % final_score)
		
		return "\n".join(parts)