class_name EquipmentData
extends Resource

## Equipment data for items that modify game rules.
## Equipment can have different shapes, effects, and categories.

## Signal emitted when equipment data changes
signal changed()

## Equipment categories - used for conflict detection
enum Category {
	OPTICAL,    ## Optical items: lenses, mirrors, crystals
	MECHANICAL, ## Mechanical items: gears, anvils, tools
	MAGICAL,    ## Magical items: runes, enchantments
	GENERIC     ## Generic items - no category conflicts
}

## Effect types - determines when and how the effect triggers
enum EffectType {
	RULE_MODIFY,    ## Rule modification: changes hand detection, multipliers
	STRUCTURE,      ## Structure trigger: effects based on backpack position
	RESOURCE,       ## Resource flow: affects gold, cards, etc.
	SCORE_MODIFY    ## Score modification: adds bonuses to scoring
}

## Trigger timing - when the effect should activate
enum TriggerTiming {
	ON_TURN_START,   ## Trigger at the start of each turn
	ON_TURN_END,     ## Trigger at the end of each turn
	ON_PLAY,         ## Trigger when playing cards
	ON_SCORE,        ## Trigger when calculating score
	ON_EQUIP,        ## Trigger when equipment is placed
	ON_ADJACENT      ## Trigger when adjacent equipment changes
}

## Display name of the equipment
@export var display_name: String = "Unnamed Equipment":
	set(value):
		if display_name != value:
			display_name = value
			changed.emit()

## Description shown to player
@export_multiline var description: String = "":
	set(value):
		if description != value:
			description = value
			changed.emit()

## Equipment category for conflict detection
@export var category: Category = Category.GENERIC:
	set(value):
		if category != value:
			category = value
			changed.emit()

## Effect type
@export var effect_type: EffectType = EffectType.SCORE_MODIFY:
	set(value):
		if effect_type != value:
			effect_type = value
			changed.emit()

## When this equipment's effect triggers
@export var trigger_timing: TriggerTiming = TriggerTiming.ON_SCORE:
	set(value):
		if trigger_timing != value:
			trigger_timing = value
			changed.emit()

## Shape of the equipment as relative grid positions
## Example: [[0,0]] = 1x1, [[0,0],[0,1],[1,0],[1,1]] = 2x2
## Positions are relative to the top-left corner of the equipment
@export var shape: Array[Vector2i] = [Vector2i(0, 0)]:
	set(value):
		if shape != value:
			shape = value
			changed.emit()

## Effect parameters - stored as a dictionary for flexibility
## Common parameters:
## - score_bonus: int - flat score bonus
## - multiplier_bonus: float - multiplier increase
## - straight_min_cards: int - minimum cards for straight (rule modify)
## - gold_per_turn: int - gold gained per turn (resource)
@export var effect_params: Dictionary = {}:
	set(value):
		if effect_params != value:
			effect_params = value
			changed.emit()

## Priority for rule stacking (higher = applied later, overrides earlier)
@export var priority: int = 0:
	set(value):
		if priority != value:
			priority = value
			changed.emit()

## Icon path for UI display (optional)
@export var icon_path: String = "":
	set(value):
		if icon_path != value:
			icon_path = value
			changed.emit()


## Get the number of grid cells this equipment occupies
func get_cell_count() -> int:
	return shape.size()


## Get the bounding box size of this equipment
func get_bounds() -> Vector2i:
	if shape.is_empty():
		return Vector2i(1, 1)
	
	var max_x := 0
	var max_y := 0
	
	for pos: Vector2i in shape:
		max_x = maxi(max_x, pos.x)
		max_y = maxi(max_y, pos.y)
	
	return Vector2i(max_x + 1, max_y + 1)


## Check if a relative position is part of this equipment's shape
func has_position(relative_pos: Vector2i) -> bool:
	return relative_pos in shape


## Get all absolute grid positions when placed at a given anchor
func get_absolute_positions(anchor: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for relative_pos: Vector2i in shape:
		positions.append(anchor + relative_pos)
	return positions


## Get a unique identifier for this equipment
func get_id() -> String:
	return resource_path.get_file().get_basename() if resource_path else display_name.to_lower().replace(" ", "_")


## Get the category name for display
func get_category_name() -> String:
	return Category.keys()[category].capitalize()


## Check if this equipment conflicts with another (same category)
func conflicts_with(other: EquipmentData) -> bool:
	if category == Category.GENERIC or other.category == Category.GENERIC:
		return false
	return category == other.category


## Check if this equipment has a specific effect parameter
func has_param(param_name: String) -> bool:
	return param_name in effect_params


## Get an effect parameter value with a default
func get_param(param_name: String, default: Variant = null) -> Variant:
	return effect_params.get(param_name, default)


## Set an effect parameter
func set_param(param_name: String, value: Variant) -> void:
	effect_params[param_name] = value
	changed.emit()


## Factory method to create common equipment shapes
static func create_shape_1x1() -> Array[Vector2i]:
	return [Vector2i(0, 0)]


static func create_shape_1x2() -> Array[Vector2i]:
	return [Vector2i(0, 0), Vector2i(0, 1)]


static func create_shape_2x1() -> Array[Vector2i]:
	return [Vector2i(0, 0), Vector2i(1, 0)]


static func create_shape_2x2() -> Array[Vector2i]:
	return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)]


static func create_shape_l() -> Array[Vector2i]:
	return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)]