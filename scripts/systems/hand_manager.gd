class_name HandManager
extends RefCounted

## 手牌管理器 —— 管理玩家手牌和选牌状态。
## 纯逻辑类，不涉及 UI 渲染。UI 更新由 BattleController 负责。

## 手牌变化信号
signal hand_changed(hand_size: int)

## 选牌变化信号
signal selection_changed(selected_size: int)

## 手牌已满信号
signal hand_full()

## 选牌已满信号（达到最大可选数）
signal selection_full()

## 选择上限已满提示信号
signal selection_limit_reached(limit: int)

## 最大手牌数量（默认 10 张）
var max_hand_size: int = 10

## 最大选牌数量（默认 5 张）
var max_selection_size: int = 5

## 当前手牌数组
var _hand: Array[CardData] = []

## 当前已选中卡牌数组
var _selected: Array[CardData] = []


func _init() -> void:
	print("HandManager 初始化完成")


## 获取手牌数组（返回副本）
func get_hand() -> Array[CardData]:
	return _hand.duplicate()


## 获取手牌数组引用（避免复制的性能开销）
func get_hand_ref() -> Array[CardData]:
	return _hand


## 获取已选卡牌数组（返回副本）
func get_selection() -> Array[CardData]:
	return _selected.duplicate()


## 获取已选卡牌数组引用
func get_selection_ref() -> Array[CardData]:
	return _selected


## 获取手牌数量
func get_hand_size() -> int:
	return _hand.size()


## 获取已选卡牌数量
func get_selection_size() -> int:
	return _selected.size()


## 检查手牌是否已满
func is_hand_full() -> bool:
	return _hand.size() >= max_hand_size


## 检查选牌是否达到上限
func is_selection_full() -> bool:
	return _selected.size() >= max_selection_size


## 是否有卡牌被选中
func has_selection() -> bool:
	return not _selected.is_empty()


## 添加卡牌到手牌
func add_to_hand(cards: Array[CardData]) -> void:
	for card: CardData in cards:
		if card == null:
			push_warning("尝试将空卡牌添加到手牌")
			continue
		if not is_hand_full():
			_hand.append(card)
		else:
			hand_full.emit()
			return
	hand_changed.emit(_hand.size())


## 从手牌移除指定卡牌
func remove_from_hand(cards: Array[CardData]) -> void:
	for card: CardData in cards:
		_hand.erase(card)
	hand_changed.emit(_hand.size())


## 切换卡牌选中状态
## 返回 true 表示选中状态发生了变化
func toggle_selection(card: CardData) -> bool:
	if card == null:
		push_warning("无法选择空卡牌")
		return false

	if card in _selected:
		# 取消选中
		_selected.erase(card)
		selection_changed.emit(_selected.size())
		return true
	elif not is_selection_full():
		# 选中
		_selected.append(card)
		if is_selection_full():
			selection_full.emit()
		selection_changed.emit(_selected.size())
		return true
	else:
		# 已达上限，无法再选
		selection_limit_reached.emit(max_selection_size)
		return false


## 检查指定卡牌是否被选中
func is_selected(card: CardData) -> bool:
	return card in _selected


## 清除所有选中状态
func clear_selection() -> void:
	_selected.clear()
	selection_changed.emit(0)


## 清除所有手牌和选中状态
func clear_all() -> void:
	_hand.clear()
	_selected.clear()
	hand_changed.emit(0)
	selection_changed.emit(0)


## 设置手牌和选牌的容量限制
func set_capacity(max_hand: int, max_select: int) -> void:
	max_hand_size = max_hand
	max_selection_size = max_select
	print("手牌容量: 最大%d张, 最大选%d张" % [max_hand, max_select])
