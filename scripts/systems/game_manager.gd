class_name GameManager
extends RefCounted

## 游戏状态机 —— 管理游戏全局状态和阶段流转。
## 不拥有数据（StageManager/EquipmentManager 由 BattleController 持有），
## 仅提供状态转换逻辑和信号协调。
## 后续可提升为 Autoload 单例。

## 游戏状态枚举
enum GameState {
	TITLE,          ## 标题界面
	BATTLE,         ## 战斗阶段
	SHOP,           ## 商店阶段
	GAME_OVER,      ## 游戏结束（失败）
	VICTORY,        ## 通关胜利
}

## 当前游戏状态
var current_state: GameState = GameState.TITLE

# ============================================================================
# 信号
# ============================================================================

## 游戏状态变化信号（old_state, new_state）
signal state_changed(old_state: GameState, new_state: GameState)

## 新游戏开始信号
signal game_started()

## 关卡通关信号（已通关数, 总关卡数）
signal stage_cleared(stages_completed: int, total_stages: int)

## 所有关卡完成信号
signal all_stages_completed()

## 游戏结束信号（失败）
signal game_over()

## 进入战斗阶段信号
signal battle_entered()

## 进入商店阶段信号
signal shop_entered()


func _init() -> void:
	print("GameManager 状态机初始化完成")


# ============================================================================
# 状态管理
# ============================================================================

## 切换游戏状态
func change_state(new_state: GameState) -> void:
	var old_state: GameState = current_state
	if old_state == new_state:
		return

	current_state = new_state
	state_changed.emit(old_state, new_state)

	print("游戏状态: %s → %s" % [_state_name(old_state), _state_name(new_state)])

	# 根据新状态发出特定信号
	match new_state:
		GameState.BATTLE:
			battle_entered.emit()
		GameState.SHOP:
			shop_entered.emit()
		GameState.VICTORY:
			all_stages_completed.emit()
		GameState.GAME_OVER:
			game_over.emit()


## 检查当前是否在指定状态
func is_in_state(state: GameState) -> bool:
	return current_state == state


## 检查是否在战斗阶段
func is_in_battle() -> bool:
	return current_state == GameState.BATTLE


## 检查是否在商店阶段
func is_in_shop() -> bool:
	return current_state == GameState.SHOP


## 检查游戏是否已结束（含胜利和失败）
func is_game_ended() -> bool:
	return current_state == GameState.GAME_OVER or current_state == GameState.VICTORY


## 检查是否通关
func is_game_completed() -> bool:
	return current_state == GameState.VICTORY


# ============================================================================
# 游戏流程方法
# ============================================================================

## 开始新游戏，进入战斗阶段
func start_game() -> void:
	change_state(GameState.BATTLE)
	game_started.emit()


## 进入战斗阶段（用于从商店返回）
func enter_battle() -> void:
	change_state(GameState.BATTLE)


## 进入商店阶段
func enter_shop() -> void:
	change_state(GameState.SHOP)


## 关卡通关（由外部提供进度信息）
func on_stage_cleared(stages_completed: int, total_stages: int, is_last_stage: bool) -> void:
	stage_cleared.emit(stages_completed, total_stages)

	if is_last_stage:
		change_state(GameState.VICTORY)
		all_stages_completed.emit()


## 游戏失败
func on_game_lost() -> void:
	change_state(GameState.GAME_OVER)


# ============================================================================
# 状态查询辅助方法
# ============================================================================

## 是否可以出牌（仅在战斗阶段）
func can_play_cards() -> bool:
	return current_state == GameState.BATTLE


## 获取当前状态的中文名称
func get_current_state_name() -> String:
	return _state_name(current_state)


## 获取状态的中文名称（静态版本）
static func get_state_name_cn(state: GameState) -> String:
	match state:
		GameState.TITLE:
			return "标题"
		GameState.BATTLE:
			return "战斗"
		GameState.SHOP:
			return "商店"
		GameState.GAME_OVER:
			return "游戏结束"
		GameState.VICTORY:
			return "胜利"
	return "未知"


# ============================================================================
# 私有辅助方法
# ============================================================================

func _state_name(state: GameState) -> String:
	return get_state_name_cn(state)
