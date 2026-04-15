class_name RuleModifier
extends RefCounted

## Rule modifier for equipment-based rule rewriting.
## This is the core system for the "rule rewriting" mechanic.
## Equipment can modify hand detection rules, multipliers, and scoring.

## Types of rule modifications that equipment can apply
enum ModifyType {
	STRAIGHT_MIN_CARDS,      ## Minimum cards needed for a straight (default 5)
	FLUSH_MIN_CARDS,         ## Minimum cards needed for a flush (default 5)
	HAND_TYPE_MULTIPLIER,    ## Multiplier for a specific hand type
	HAND_TYPE_ENABLED,       ## Enable/disable a hand type
	NEW_HAND_TYPE,           ## Add a new custom hand type (future)
	ACE_VALUE_OVERRIDE,      ## Override Ace value (default 11)
	SUIT_BONUS,              ## Bonus for specific suit
	RANK_BONUS,              ## Bonus for specific rank
}

## Rule modification entry - a single modification from one equipment
class RuleEntry extends RefCounted:
	
	## The type of modification
	var modify_type: ModifyType = ModifyType.STRAIGHT_MIN_CARDS
	
	## The value of the modification (meaning depends on type)
	var value: Variant = null
	
	## Target hand type for HAND_TYPE_MULTIPLIER and HAND_TYPE_ENABLED
	var target_hand_type: HandType.Type = HandType.Type.HIGH_CARD
	
	## Priority for rule stacking (higher = applied later, overrides earlier)
	var priority: int = 0
	
	## Source equipment for debugging
	var source: EquipmentData = null
	
	## Unique ID for this entry
	var id: String = ""
	
	
	func _init(
		p_type: ModifyType = ModifyType.STRAIGHT_MIN_CARDS,
		p_value: Variant = null,
		p_priority: int = 0,
		p_source: EquipmentData = null
	) -> void:
		modify_type = p_type
		value = p_value
		priority = p_priority
		source = p_source
		id = _generate_id()
	
	
	func _generate_id() -> String:
		if source:
			return source.get_id() + "_" + str(modify_type)
		return "rule_" + str(modify_type) + "_" + str(priority)
	
	
	func get_description() -> String:
		match modify_type:
			ModifyType.STRAIGHT_MIN_CARDS:
				return "顺子只需 %d 张牌" % int(value)
			ModifyType.FLUSH_MIN_CARDS:
				return "同花只需 %d 张牌" % int(value)
			ModifyType.HAND_TYPE_MULTIPLIER:
				return "%s 倍率 × %.1f" % [HandType.get_display_name_cn(target_hand_type), float(value)]
			ModifyType.HAND_TYPE_ENABLED:
				var enabled: bool = bool(value)
				if enabled:
					return "%s 可用" % HandType.get_display_name_cn(target_hand_type)
				else:
					return "%s 不可用" % HandType.get_display_name_cn(target_hand_type)
			ModifyType.ACE_VALUE_OVERRIDE:
				return "A 牌面值改为 %d" % int(value)
			ModifyType.SUIT_BONUS:
				return "特定花色加成"
			ModifyType.RANK_BONUS:
				return "特定牌面加成"
			_:
				return "未知规则改写"


## Collection of active rule modifiers from equipped items
## Handles rule stacking and conflict resolution
var _rules: Array[RuleEntry] = []

## Cached computed values for quick lookup
var _cached_straight_min: int = 5
var _cached_flush_min: int = 5
var _cached_multipliers: Dictionary = {}
var _cached_disabled_types: Array[HandType.Type] = []


signal rules_changed()


func _init() -> void:
	# Initialize default multipliers
	_reset_to_defaults()


## Reset all rules to default values
func _reset_to_defaults() -> void:
	_cached_straight_min = 5
	_cached_flush_min = 5
	_cached_multipliers.clear()
	_cached_disabled_types.clear()
	
	# Copy base multipliers
	for hand_type: HandType.Type in HandType.MULTIPLIERS:
		_cached_multipliers[hand_type] = HandType.MULTIPLIERS[hand_type]


## Add a rule entry from equipment
func add_rule(entry: RuleEntry) -> void:
	if entry == null:
		push_error("Cannot add null rule entry")
		return
	
	_rules.append(entry)
	# Sort by priority (lower first, higher applied later)
	_rules.sort_custom(_compare_rule_priority)
	
	_recompute_cache()
	rules_changed.emit()


## Add rules from an equipment data
func add_equipment_rules(equipment: EquipmentData) -> void:
	if equipment == null:
		push_error("Cannot add rules from null equipment")
		return
	
	if equipment.effect_type != EquipmentData.EffectType.RULE_MODIFY:
		# Not a rule-modifying equipment
		return
	
	# Parse effect_params to create rule entries
	var params: Dictionary = equipment.effect_params
	
	# Straight minimum cards
	if params.has("straight_min_cards"):
		var entry := RuleEntry.new(
			ModifyType.STRAIGHT_MIN_CARDS,
			params["straight_min_cards"],
			equipment.priority,
			equipment
		)
		add_rule(entry)
	
	# Flush minimum cards
	if params.has("flush_min_cards"):
		var entry := RuleEntry.new(
			ModifyType.FLUSH_MIN_CARDS,
			params["flush_min_cards"],
			equipment.priority,
			equipment
		)
		add_rule(entry)
	
	# Hand type multiplier
	if params.has("hand_type_multiplier"):
		var target: int = params.get("target_hand_type", HandType.Type.HIGH_CARD)
		var mult: float = params.get("multiplier_factor", 2.0)
		var entry := RuleEntry.new(
			ModifyType.HAND_TYPE_MULTIPLIER,
			mult,
			equipment.priority,
			equipment
		)
		entry.target_hand_type = target as HandType.Type
		add_rule(entry)
	
	# Ace value override
	if params.has("ace_value"):
		var entry := RuleEntry.new(
			ModifyType.ACE_VALUE_OVERRIDE,
			params["ace_value"],
			equipment.priority,
			equipment
		)
		add_rule(entry)


## Remove all rules from a specific equipment
func remove_equipment_rules(equipment: EquipmentData) -> void:
	if equipment == null:
		return
	
	var to_remove: Array[RuleEntry] = []
	for entry: RuleEntry in _rules:
		if entry.source == equipment:
			to_remove.append(entry)
	
	for entry: RuleEntry in to_remove:
		_rules.erase(entry)
	
	_recompute_cache()
	rules_changed.emit()


## Clear all rules
func clear_rules() -> void:
	_rules.clear()
	_reset_to_defaults()
	rules_changed.emit()


## Compare rule priority for sorting
func _compare_rule_priority(a: RuleEntry, b: RuleEntry) -> bool:
	return a.priority < b.priority


## Recompute cached values from current rules
func _recompute_cache() -> void:
	_reset_to_defaults()
	
	for entry: RuleEntry in _rules:
		_apply_rule_to_cache(entry)


## Apply a single rule to the cache
func _apply_rule_to_cache(entry: RuleEntry) -> void:
	match entry.modify_type:
		ModifyType.STRAIGHT_MIN_CARDS:
			_cached_straight_min = int(entry.value)
		
		ModifyType.FLUSH_MIN_CARDS:
			_cached_flush_min = int(entry.value)
		
		ModifyType.HAND_TYPE_MULTIPLIER:
			var base: int = HandType.MULTIPLIERS.get(entry.target_hand_type, 1)
			_cached_multipliers[entry.target_hand_type] = int(base * float(entry.value))
		
		ModifyType.HAND_TYPE_ENABLED:
			if not bool(entry.value):
				_cached_disabled_types.append(entry.target_hand_type)
		
		ModifyType.ACE_VALUE_OVERRIDE:
			# This needs special handling in CardData
			pass


## Get minimum cards for a straight
func get_straight_min_cards() -> int:
	return _cached_straight_min


## Get minimum cards for a flush
func get_flush_min_cards() -> int:
	return _cached_flush_min


## Get multiplier for a hand type (modified by equipment)
func get_hand_type_multiplier(hand_type: HandType.Type) -> int:
	return _cached_multipliers.get(hand_type, HandType.MULTIPLIERS.get(hand_type, 1))


## Check if a hand type is enabled
func is_hand_type_enabled(hand_type: HandType.Type) -> bool:
	return hand_type not in _cached_disabled_types


## Get all active rules
func get_all_rules() -> Array[RuleEntry]:
	return _rules.duplicate()


## Get rules summary for display
func get_rules_summary() -> String:
	if _rules.is_empty():
		return "无规则改写"
	
	var lines: Array[String] = []
	for entry: RuleEntry in _rules:
		lines.append(entry.get_description())
	
	return "\n".join(lines)


## Check if any rules are active
func has_active_rules() -> bool:
	return not _rules.is_empty()


## Get count of active rules
func get_rule_count() -> int:
	return _rules.size()


## Create a RuleModifier from a list of equipment (factory method)
static func create_from_equipment(equipment_list: Array[EquipmentData]) -> RuleModifier:
	var modifier := RuleModifier.new()
	for equipment: EquipmentData in equipment_list:
		modifier.add_equipment_rules(equipment)
	return modifier