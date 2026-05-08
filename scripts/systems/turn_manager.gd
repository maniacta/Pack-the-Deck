class_name TurnManager
extends RefCounted

## 回合管理器 —— 管理回合计数、出牌次数限制和 Boss 规则执行。
## 纯逻辑类，不涉及 UI 渲染。

## 新回合开始信号
signal turn_started(turn_number: int)

## 回合结束信号
signal turn_ended(turn_number: int, remaining_turns: int)

## 所有回合耗尽信号
signal turns_exhausted()

## 本回合出牌次数达到上限信号
signal play_limit_reached(limit: int)

## 剩余回合数
var remaining_turns: int = 0

## 最大回合数
var max_turns: int = 0

## 当前回合编号（从 1 开始）
var current_turn: int = 0

## 本回合已出牌次数
var plays_this_turn: int = 0

## 每回合最大出牌次数（-1 = 无限制，由 Boss PLAY_LIMIT 规则设置）
var max_plays_per_turn: int = -1

## 强制手牌上限（-1 = 无限制，由 Boss CARD_LIMIT 规则设置）
var max_hand_size_enforced: int = -1


func _init() -> void:
	print("TurnManager 初始化完成")


## 根据关卡配置设置回合参数
func setup(config: StageConfig) -> void:
	if not config:
		push_error("无效的关卡配置")
		return

	remaining_turns = config.max_turns
	max_turns = config.max_turns
	current_turn = 0
	plays_this_turn = 0
	max_plays_per_turn = -1
	max_hand_size_enforced = -1

	# 应用 Boss 特殊规则
	if config.has_boss_rule():
		_apply_boss_rules(config)

	print("回合管理器设置完成: 最多%d回合" % max_turns)


## 应用 Boss 规则到回合限制
func _apply_boss_rules(config: StageConfig) -> void:
	match config.boss_rule:
		StageConfig.BossRule.PLAY_LIMIT:
			max_plays_per_turn = config.boss_rule_param.get("limit", 3)
			print("Boss 规则: 每回合最多出牌 %d 次" % max_plays_per_turn)
		StageConfig.BossRule.CARD_LIMIT:
			max_hand_size_enforced = config.boss_rule_param.get("limit", 5)
			print("Boss 规则: 手牌上限 %d 张" % max_hand_size_enforced)


## 开始新回合（更新回合计数并重置本回合出牌次数）
func start_new_turn() -> void:
	current_turn += 1
	plays_this_turn = 0
	turn_started.emit(current_turn)
	print("第 %d 回合开始 (剩余 %d 回合)" % [current_turn, remaining_turns])


## 检查本回合是否可以继续出牌
func can_play() -> bool:
	if remaining_turns <= 0:
		return false
	if max_plays_per_turn > 0 and plays_this_turn >= max_plays_per_turn:
		play_limit_reached.emit(max_plays_per_turn)
		return false
	return true


## 记录一次出牌（扣减剩余回合，增加本回合出牌计数）
func record_play() -> void:
	plays_this_turn += 1
	remaining_turns -= 1


## 检查是否还有剩余回合
func has_remaining_turns() -> bool:
	return remaining_turns > 0


## 检查是否所有回合已耗尽（用于判定失败）
func is_turns_exhausted() -> bool:
	return remaining_turns <= 0


## 获取 Boss 规则强制的手牌上限（-1 表示无限制）
func get_hand_size_limit() -> int:
	return max_hand_size_enforced


## 检查是否有 Boss 手牌限制规则
func has_hand_size_limit() -> bool:
	return max_hand_size_enforced > 0


## 检查是否有 Boss 出牌次数限制规则
func has_play_limit() -> bool:
	return max_plays_per_turn > 0


## 获取 Boss 规则的描述文本（用于 UI 显示）
func get_boss_rule_description() -> String:
	if max_plays_per_turn > 0:
		return "每回合最多出牌 %d 次" % max_plays_per_turn
	if max_hand_size_enforced > 0:
		return "手牌上限 %d 张" % max_hand_size_enforced
	return ""


## 完全重置回合管理器状态
func reset() -> void:
	remaining_turns = 0
	max_turns = 0
	current_turn = 0
	plays_this_turn = 0
	max_plays_per_turn = -1
	max_hand_size_enforced = -1
	print("回合管理器已重置")
