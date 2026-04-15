class_name EffectTrigger
extends RefCounted

## Equipment effect trigger system.
## Handles triggering equipment effects at the correct timing.
## Works with EquipmentManager to process effects from equipped items.

## Effect trigger timing (matches EquipmentData.TriggerTiming)
enum Timing {
	ON_TURN_START,   ## Trigger at the start of each turn
	ON_TURN_END,     ## Trigger at the end of each turn
	ON_PLAY,         ## Trigger when playing cards
	ON_SCORE,        ## Trigger when calculating score
	ON_EQUIP,        ## Trigger when equipment is placed
	ON_ADJACENT,     ## Trigger when adjacent equipment changes
}

## Effect context - provides information for effect execution
class EffectContext extends RefCounted:
	
	## Current timing
	var timing: Timing = Timing.ON_TURN_START
	
	## Cards being played (for ON_PLAY timing)
	var played_cards: Array[CardData] = []
	
	## Hand result (for ON_SCORE timing)
	var hand_result: HandType.HandResult = null
	
	## Current score (for ON_SCORE timing)
	var current_score: int = 0
	
	## Blind type (for ON_SCORE timing)
	var blind_type: BlindType.Type = BlindType.Type.SMALL_BLIND
	
	## Player gold (for resource effects)
	var player_gold: int = 0
	
	## Current turn number
	var turn_number: int = 0
	
	## Equipment manager reference
	var equipment_manager: EquipmentManager = null
	
	## Additional parameters
	var params: Dictionary = {}
	
	
	func _init(p_timing: Timing = Timing.ON_TURN_START) -> void:
		timing = p_timing


## Effect execution result
class EffectResult extends RefCounted:
	
	## Whether the effect was executed successfully
	var success: bool = false
	
	## Score bonus added
	var score_bonus: int = 0
	
	## Multiplier bonus applied
	var multiplier_bonus: float = 1.0
	
	## Gold change
	var gold_change: int = 0
	
	## Cards added/removed
	var cards_change: Array[CardData] = []
	
	## Message for display
	var message: String = ""
	
	## Source equipment
	var source: EquipmentData = null
	
	## Additional data
	var data: Dictionary = {}
	
	
	func _init(p_success: bool = false) -> void:
		success = p_success


## Reference to equipment manager
var _equipment_manager: EquipmentManager = null

## Rule modifier (built from equipped items)
var _rule_modifier: RuleModifier = null

## Active effect results (for display)
var _pending_results: Array[EffectResult] = []

## Signals for UI updates
signal effect_triggered(result: EffectResult)
signal rules_updated()


func _init(manager: EquipmentManager = null) -> void:
	_equipment_manager = manager
	_rule_modifier = RuleModifier.new()
	
	if _equipment_manager:
		# Connect to equipment changes
		_equipment_manager.equipment_placed.connect(_on_equipment_placed)
		_equipment_manager.equipment_unequipped.connect(_on_equipment_unequipped)


## Set the equipment manager
func set_equipment_manager(manager: EquipmentManager) -> void:
	_equipment_manager = manager
	_rebuild_rule_modifier()


## Get the current rule modifier
func get_rule_modifier() -> RuleModifier:
	return _rule_modifier


## Trigger effects at a specific timing
func trigger_effects(timing: Timing, context: EffectContext) -> Array[EffectResult]:
	if not _equipment_manager:
		return []
	
	var results: Array[EffectResult] = []
	var equipped: Array[EquipmentData] = _equipment_manager.get_equipped()
	
	for equipment: EquipmentData in equipped:
		# Check if this equipment triggers at this timing
		if _should_trigger(equipment, timing):
			var result: EffectResult = execute_effect(equipment, context)
			if result.success:
				results.append(result)
				effect_triggered.emit(result)
	
	return results


## Check if an equipment should trigger at a timing
func _should_trigger(equipment: EquipmentData, timing: Timing) -> bool:
	var eq_timing: EquipmentData.TriggerTiming = equipment.trigger_timing
	
	match timing:
		Timing.ON_TURN_START:
			return eq_timing == EquipmentData.TriggerTiming.ON_TURN_START
		Timing.ON_TURN_END:
			return eq_timing == EquipmentData.TriggerTiming.ON_TURN_END
		Timing.ON_PLAY:
			return eq_timing == EquipmentData.TriggerTiming.ON_PLAY
		Timing.ON_SCORE:
			return eq_timing == EquipmentData.TriggerTiming.ON_SCORE
		Timing.ON_EQUIP:
			return eq_timing == EquipmentData.TriggerTiming.ON_EQUIP
		Timing.ON_ADJACENT:
			return eq_timing == EquipmentData.TriggerTiming.ON_ADJACENT
	
	return false


## Execute an equipment's effect
func execute_effect(equipment: EquipmentData, context: EffectContext) -> EffectResult:
	if not equipment:
		return EffectResult.new(false)
	
	var result := EffectResult.new(true)
	result.source = equipment
	
	# Parse effect type and params
	match equipment.effect_type:
		EquipmentData.EffectType.RULE_MODIFY:
			# Rule modifications are handled by RuleModifier
			# Just mark as successful, no immediate effect
			result.message = "规则已改写: %s" % equipment.display_name
		
		EquipmentData.EffectType.SCORE_MODIFY:
			# Score modification effects
			_apply_score_modify(equipment, context, result)
		
		EquipmentData.EffectType.RESOURCE:
			# Resource flow effects (gold, etc.)
			_apply_resource_effect(equipment, context, result)
		
		EquipmentData.EffectType.STRUCTURE:
			# Structure trigger effects (adjacent, position-based)
			_apply_structure_effect(equipment, context, result)
	
	return result


## Apply score modification effect
func _apply_score_modify(equipment: EquipmentData, context: EffectContext, result: EffectResult) -> void:
	var params: Dictionary = equipment.effect_params
	
	# Score bonus (flat addition)
	if params.has("score_bonus"):
		result.score_bonus = int(params["score_bonus"])
		result.message = "+%d 分" % result.score_bonus
	
	# Multiplier bonus
	if params.has("multiplier_bonus"):
		result.multiplier_bonus = float(params["multiplier_bonus"])
		result.message = "倍率 ×%.1f" % result.multiplier_bonus
	
	# Hand type multiplier
	if params.has("hand_type_multiplier"):
		# This affects the rule modifier, handled separately
		pass


## Apply resource effect (gold, cards, etc.)
func _apply_resource_effect(equipment: EquipmentData, context: EffectContext, result: EffectResult) -> void:
	var params: Dictionary = equipment.effect_params
	
	# Gold per turn
	if params.has("gold_per_turn"):
		var gold: int = int(params["gold_per_turn"])
		result.gold_change = gold
		result.message = "+%d 金币" % gold
	
	# Draw extra cards
	if params.has("draw_cards"):
		var extra: int = int(params["draw_cards"])
		# This needs to be handled by the battle controller
		result.data["draw_cards"] = extra
		result.message = "+%d 张牌" % extra


## Apply structure effect (position-based)
func _apply_structure_effect(equipment: EquipmentData, context: EffectContext, result: EffectResult) -> void:
	var params: Dictionary = equipment.effect_params
	
	# Adjacent bonus
	if params.has("adjacent_bonus"):
		if _equipment_manager:
			var adjacent_count: int = _equipment_manager.count_adjacent_equipment(equipment)
			if adjacent_count > 0:
				var bonus_per_adjacent: int = int(params.get("bonus_per_adjacent", 5))
				result.score_bonus = adjacent_count * bonus_per_adjacent
				result.message = "相邻装备 +%d 分" % result.score_bonus


## Handle equipment placed
func _on_equipment_placed(equipment: EquipmentData, position: Vector2i) -> void:
	_rebuild_rule_modifier()
	
	# Trigger ON_EQUIP timing
	if equipment.trigger_timing == EquipmentData.TriggerTiming.ON_EQUIP:
		var context := EffectContext.new(Timing.ON_EQUIP)
		context.params["position"] = position
		var result: EffectResult = execute_effect(equipment, context)
		if result.success:
			effect_triggered.emit(result)
	
	rules_updated.emit()


## Handle equipment unequipped
func _on_equipment_unequipped(equipment: EquipmentData) -> void:
	_rebuild_rule_modifier()
	rules_updated.emit()


## Rebuild rule modifier from equipped items
func _rebuild_rule_modifier() -> void:
	if not _equipment_manager:
		_rule_modifier.clear_rules()
		return
	
	_rule_modifier.clear_rules()
	
	var equipped: Array[EquipmentData] = _equipment_manager.get_equipped()
	for equipment: EquipmentData in equipped:
		_rule_modifier.add_equipment_rules(equipment)


## Get score modifiers for current equipped items
func get_score_modifiers() -> Dictionary:
	var modifiers: Dictionary = {}
	
	if not _equipment_manager:
		return modifiers
	
	var equipped: Array[EquipmentData] = _equipment_manager.get_equipped()
	var total_score_bonus: int = 0
	var total_multiplier_bonus: float = 1.0
	
	for equipment: EquipmentData in equipped:
		if equipment.effect_type == EquipmentData.EffectType.SCORE_MODIFY:
			var params: Dictionary = equipment.effect_params
			
			if params.has("score_bonus"):
				total_score_bonus += int(params["score_bonus"])
			
			if params.has("multiplier_bonus"):
				total_multiplier_bonus *= float(params["multiplier_bonus"])
	
	modifiers["score_bonus"] = total_score_bonus
	modifiers["multiplier_bonus"] = total_multiplier_bonus
	
	return modifiers


## Trigger turn start effects
func trigger_turn_start(turn_number: int, player_gold: int) -> Array[EffectResult]:
	var context := EffectContext.new(Timing.ON_TURN_START)
	context.turn_number = turn_number
	context.player_gold = player_gold
	return trigger_effects(Timing.ON_TURN_START, context)


## Trigger turn end effects
func trigger_turn_end(turn_number: int, player_gold: int) -> Array[EffectResult]:
	var context := EffectContext.new(Timing.ON_TURN_END)
	context.turn_number = turn_number
	context.player_gold = player_gold
	return trigger_effects(Timing.ON_TURN_END, context)


## Trigger play effects
func trigger_play_effects(played_cards: Array[CardData]) -> Array[EffectResult]:
	var context := EffectContext.new(Timing.ON_PLAY)
	context.played_cards = played_cards
	return trigger_effects(Timing.ON_PLAY, context)


## Trigger score effects
func trigger_score_effects(
	hand_result: HandType.HandResult,
	current_score: int,
	blind_type: BlindType.Type
) -> Array[EffectResult]:
	var context := EffectContext.new(Timing.ON_SCORE)
	context.hand_result = hand_result
	context.current_score = current_score
	context.blind_type = blind_type
	return trigger_effects(Timing.ON_SCORE, context)


## Get all active rules summary
func get_rules_summary() -> String:
	return _rule_modifier.get_rules_summary()


## Check if any rules are active
func has_active_rules() -> bool:
	return _rule_modifier.has_active_rules()