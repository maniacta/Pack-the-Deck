class_name StageManager
extends RefCounted

## Stage manager for tracking game progress across multiple stages.
## Handles stage progression, gold persistence, and equipment inventory.

## Game progress state enum
enum ProgressState {
	NOT_STARTED,     ## Game hasn't started yet
	IN_PROGRESS,     ## Currently playing through stages
	VICTORY,         ## Completed all stages
	GAME_OVER,       ## Failed and chose not to retry
}

## List of available stage resource paths
var _stage_list: Array[String] = [
	"res://resources/stages/stage_1.tres",
	"res://resources/stages/stage_2.tres",
	"res://resources/stages/stage_3.tres",
]

## Current stage index (0-based)
var _current_stage_index: int = 0

## Current progress state
var _progress_state: ProgressState = ProgressState.NOT_STARTED

## Player's accumulated gold across stages
var _player_gold: int = 0

## Player's equipment inventory (items bought from shop but not equipped)
var _equipment_inventory: Array[EquipmentData] = []

## Player's equipped items (persisted across stages)
var _equipped_items: Array[EquipmentData] = []

## Stages completed count
var _stages_completed: int = 0

## Total score accumulated
var _total_score: int = 0

## Signals for UI updates
signal stage_changed(stage_config: StageConfig, stage_index: int)
signal gold_changed(new_gold: int)
signal progress_completed()
signal game_over()


func _init() -> void:
	print("StageManager 初始化完成")


## Get the list of available stages
func get_stage_list() -> Array[String]:
	return _stage_list.duplicate()


## Get current stage index
func get_current_stage_index() -> int:
	return _current_stage_index


## Get total stages count
func get_total_stages() -> int:
	return _stage_list.size()


## Get current progress state
func get_progress_state() -> ProgressState:
	return _progress_state


## Get player gold
func get_player_gold() -> int:
	return _player_gold


## Add gold to player
func add_gold(amount: int) -> void:
	_player_gold += amount
	gold_changed.emit(_player_gold)
	print("金币 +%d (总计: %d)" % [amount, _player_gold])


## Spend gold
func spend_gold(amount: int) -> bool:
	if _player_gold < amount:
		push_warning("金币不足: 需要 %d, 拥有 %d" % [amount, _player_gold])
		return false
	
	_player_gold -= amount
	gold_changed.emit(_player_gold)
	print("金币 -%d (剩余: %d)" % [amount, _player_gold])
	return true


## Get equipment inventory
func get_equipment_inventory() -> Array[EquipmentData]:
	return _equipment_inventory.duplicate()


## Add equipment to inventory
func add_equipment(equipment: EquipmentData) -> void:
	_equipment_inventory.append(equipment)
	print("获得装备: %s" % equipment.display_name)


## Remove equipment from inventory
func remove_equipment(equipment: EquipmentData) -> bool:
	if equipment in _equipment_inventory:
		_equipment_inventory.erase(equipment)
		return true
	return false


## Get equipped items
func get_equipped_items() -> Array[EquipmentData]:
	return _equipped_items.duplicate()


## Equip an item from inventory
func equip_item(equipment: EquipmentData) -> bool:
	if equipment not in _equipment_inventory:
		push_warning("装备不在库存中")
		return false
	
	_equipment_inventory.erase(equipment)
	_equipped_items.append(equipment)
	print("装备: %s" % equipment.display_name)
	return true


## Unequip an item back to inventory
func unequip_item(equipment: EquipmentData) -> bool:
	if equipment not in _equipped_items:
		push_warning("装备未装备")
		return false
	
	_equipped_items.erase(equipment)
	_equipment_inventory.append(equipment)
	print("卸下装备: %s" % equipment.display_name)
	return true


## Load the current stage configuration
func load_current_stage() -> StageConfig:
	if _current_stage_index >= _stage_list.size():
		push_error("当前关卡索引超出范围")
		return null
	
	var stage_path: String = _stage_list[_current_stage_index]
	var resource: Resource = load(stage_path)
	
	if resource is StageConfig:
		return resource as StageConfig
	
	push_error("无法加载关卡资源: %s" % stage_path)
	return null


## Load a specific stage by index
func load_stage_by_index(index: int) -> StageConfig:
	if index < 0 or index >= _stage_list.size():
		push_error("无效关卡索引: %d" % index)
		return null
	
	_current_stage_index = index
	return load_current_stage()


## Start the game (load first stage)
func start_game() -> StageConfig:
	_progress_state = ProgressState.IN_PROGRESS
	_current_stage_index = 0
	_player_gold = 0
	_equipment_inventory.clear()
	_equipped_items.clear()
	_stages_completed = 0
	_total_score = 0
	
	print("游戏开始 - 第一关")
	return load_current_stage()


## Complete current stage and move to next
func complete_stage(score: int, reward: int) -> StageConfig:
	_stages_completed += 1
	_total_score += score
	
	# Add reward gold
	add_gold(reward)
	
	print("关卡 %d 完成 - 得分: %d, 奖励: %d 金币" % [_current_stage_index + 1, score, reward])
	
	# Check if all stages completed
	if _current_stage_index + 1 >= _stage_list.size():
		_progress_state = ProgressState.VICTORY
		progress_completed.emit()
		print("游戏胜利！完成所有 %d 关" % _stages_completed)
		return null
	
	# Move to next stage
	_current_stage_index += 1
	var next_stage: StageConfig = load_current_stage()
	
	if next_stage:
		stage_changed.emit(next_stage, _current_stage_index)
		print("进入下一关: %s" % next_stage.display_name)
	
	return next_stage


## Check if there's a next stage
func has_next_stage() -> bool:
	return _current_stage_index + 1 < _stage_list.size()


## Get next stage preview (without advancing)
func peek_next_stage() -> StageConfig:
	if not has_next_stage():
		return null
	
	var next_path: String = _stage_list[_current_stage_index + 1]
	var resource: Resource = load(next_path)
	
	if resource is StageConfig:
		return resource as StageConfig
	
	return null


## Reset progress (restart from first stage)
func reset_progress() -> void:
	_progress_state = ProgressState.NOT_STARTED
	_current_stage_index = 0
	# Keep gold and equipment for retry? Or reset everything?
	# For MVP, we keep gold and equipment
	print("进度已重置")


## Full reset (new game)
func full_reset() -> void:
	_progress_state = ProgressState.NOT_STARTED
	_current_stage_index = 0
	_player_gold = 0
	_equipment_inventory.clear()
	_equipped_items.clear()
	_stages_completed = 0
	_total_score = 0
	print("完全重置 - 新游戏")


## Get progress summary
func get_progress_summary() -> String:
	var lines: Array[String] = []
	lines.append("关卡进度: %d / %d" % [_stages_completed, _stage_list.size()])
	lines.append("累计得分: %d" % _total_score)
	lines.append("金币: %d" % _player_gold)
	lines.append("装备库存: %d 件" % _equipment_inventory.size())
	lines.append("已装备: %d 件" % _equipped_items.size())
	
	match _progress_state:
		ProgressState.NOT_STARTED:
			lines.append("状态: 未开始")
		ProgressState.IN_PROGRESS:
			lines.append("状态: 进行中")
		ProgressState.VICTORY:
			lines.append("状态: 胜利！")
		ProgressState.GAME_OVER:
			lines.append("状态: 游戏结束")
	
	return "\n".join(lines)


## Check if game is in progress
func is_in_progress() -> bool:
	return _progress_state == ProgressState.IN_PROGRESS


## Check if game is completed
func is_completed() -> bool:
	return _progress_state == ProgressState.VICTORY


## Get stages completed count
func get_stages_completed() -> int:
	return _stages_completed


## Get total score
func get_total_score() -> int:
	return _total_score