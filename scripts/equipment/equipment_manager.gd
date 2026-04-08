class_name EquipmentManager
extends RefCounted

## Manages the player's equipment inventory and equipped items.
## Handles placement, removal, and conflict detection.

## Signal emitted when equipment is added to inventory
signal equipment_added(equipment: EquipmentData)

## Signal emitted when equipment is removed from inventory
signal equipment_removed(equipment: EquipmentData)

## Signal emitted when equipment is placed in backpack
signal equipment_placed(equipment: EquipmentData, position: Vector2i)

## Signal emitted when equipment is removed from backpack
signal equipment_unequipped(equipment: EquipmentData)

## Backpack grid size (5x4)
const GRID_WIDTH: int = 5
const GRID_HEIGHT: int = 4

## Player's inventory (unequipped equipment)
var _inventory: Array[EquipmentData] = []

## Backpack grid - stores equipped items with their positions
## Key: Vector2i position, Value: EquipmentData
var _grid: Dictionary = {}

## Map of equipment to their anchor positions
## Key: EquipmentData, Value: Vector2i anchor position
var _equipment_positions: Dictionary = {}


## Add equipment to inventory
func add_to_inventory(equipment: EquipmentData) -> void:
	if equipment == null:
		push_error("Cannot add null equipment to inventory")
		return
	
	_inventory.append(equipment)
	equipment_added.emit(equipment)


## Remove equipment from inventory
func remove_from_inventory(equipment: EquipmentData) -> bool:
	var index := _inventory.find(equipment)
	if index < 0:
		push_warning("Equipment not found in inventory")
		return false
	
	_inventory.remove_at(index)
	equipment_removed.emit(equipment)
	return true


## Check if equipment can be placed at a given position
func can_place(equipment: EquipmentData, anchor: Vector2i) -> bool:
	if equipment == null:
		return false
	
	# Check if already equipped
	if _equipment_positions.has(equipment):
		push_warning("Equipment is already equipped")
		return false
	
	# Check category conflicts
	if _has_category_conflict(equipment):
		push_warning("Category conflict: %s equipment already equipped" % equipment.get_category_name())
		return false
	
	# Check grid boundaries and occupancy
	var positions := equipment.get_absolute_positions(anchor)
	for pos: Vector2i in positions:
		# Check bounds
		if pos.x < 0 or pos.x >= GRID_WIDTH or pos.y < 0 or pos.y >= GRID_HEIGHT:
			return false
		
		# Check if position is already occupied
		if _grid.has(pos):
			return false
	
	return true


## Place equipment at a given position in the backpack
func place_equipment(equipment: EquipmentData, anchor: Vector2i) -> bool:
	if not can_place(equipment, anchor):
		return false
	
	# Remove from inventory if present
	var index := _inventory.find(equipment)
	if index >= 0:
		_inventory.remove_at(index)
	
	# Place in grid
	var positions := equipment.get_absolute_positions(anchor)
	for pos: Vector2i in positions:
		_grid[pos] = equipment
	
	_equipment_positions[equipment] = anchor
	equipment_placed.emit(equipment, anchor)
	return true


## Remove equipment from backpack
func unequip(equipment: EquipmentData) -> bool:
	if not _equipment_positions.has(equipment):
		push_warning("Equipment is not equipped")
		return false
	
	# Remove from grid
	var positions := equipment.get_absolute_positions(_equipment_positions[equipment])
	for pos: Vector2i in positions:
		_grid.erase(pos)
	
	_equipment_positions.erase(equipment)
	_inventory.append(equipment)
	equipment_unequipped.emit(equipment)
	return true


## Get equipment at a specific grid position
func get_equipment_at(pos: Vector2i) -> EquipmentData:
	return _grid.get(pos, null)


## Get all equipped equipment
func get_equipped() -> Array[EquipmentData]:
	var equipped: Array[EquipmentData] = []
	for equipment: EquipmentData in _equipment_positions.keys():
		equipped.append(equipment)
	return equipped


## Get all equipment in inventory
func get_inventory() -> Array[EquipmentData]:
	return _inventory.duplicate()


## Check if a position in the grid is occupied
func is_position_occupied(pos: Vector2i) -> bool:
	return _grid.has(pos)


## Check if there's a category conflict with existing equipment
func _has_category_conflict(new_equipment: EquipmentData) -> bool:
	for equipped: EquipmentData in _equipment_positions.keys():
		if new_equipment.conflicts_with(equipped):
			return true
	return false


## Get adjacent equipment for a given position
func get_adjacent_equipment(pos: Vector2i) -> Array[EquipmentData]:
	var adjacent: Array[EquipmentData] = []
	var directions := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	
	for dir: Vector2i in directions:
		var check_pos := pos + dir
		var equipment: EquipmentData = get_equipment_at(check_pos)
		if equipment and not equipment in adjacent:
			adjacent.append(equipment)
	
	return adjacent


## Count adjacent equipment for a given equipment
func count_adjacent_equipment(equipment: EquipmentData) -> int:
	if not _equipment_positions.has(equipment):
		return 0
	
	var anchor: Vector2i = _equipment_positions[equipment]
	var positions := equipment.get_absolute_positions(anchor)
	var adjacent_set: Array[EquipmentData] = []
	
	for pos: Vector2i in positions:
		for adjacent: EquipmentData in get_adjacent_equipment(pos):
			if adjacent != equipment and adjacent not in adjacent_set:
				adjacent_set.append(adjacent)
	
	return adjacent_set.size()


## Clear all equipment (reset)
func clear() -> void:
	_grid.clear()
	_equipment_positions.clear()
	_inventory.clear()


## Get grid occupation status for display
func get_grid_status() -> Array[bool]:
	var status: Array[bool] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			status.append(is_position_occupied(Vector2i(x, y)))
	return status