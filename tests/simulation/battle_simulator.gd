class_name BattleSimulator
extends RefCounted

## 无 UI 战斗模拟器 —— 用于端到端游戏流程测试。
## 模拟完整战斗过程：抽牌 → 选牌 → 出牌 → 计分 → 判定，不依赖 UI 渲染。

## 牌组
var deck: Deck

## 手牌管理器
var hand_manager: HandManager

## 回合管理器
var turn_manager: TurnManager

## 当前关卡配置
var stage_config: StageConfig

## 装备管理器
var equipment_manager: EquipmentManager

## 效果触发器
var effect_trigger: EffectTrigger

## 规则改写器
var rule_modifier: RuleModifier

## 当前累计得分
var current_score: int = 0

## 当前金币
var player_gold: int = 0

## 出牌历史记录
var play_history: Array[Dictionary] = []


## 设置模拟器环境
## config: 关卡配置
## equipment: 初始装备数组（可选，会尝试放置到背包）
## fixed_seed: 固定随机种子（0 = 随机）
func setup(config: StageConfig, equipment: Array[EquipmentData] = [], fixed_seed: int = 0) -> void:
	stage_config = config
	current_score = 0
	player_gold = 0
	play_history.clear()

	# 固定随机种子确保 Deck.shuffle() 结果可复现
	if fixed_seed != 0:
		seed(fixed_seed)

	# 创建牌组
	deck = Deck.new()
	deck.shuffle()

	# 创建手牌管理器
	hand_manager = HandManager.new()
	hand_manager.set_capacity(config.max_hand_size, config.max_selection_size)

	# 创建回合管理器
	turn_manager = TurnManager.new()
	turn_manager.setup(config)

	# 创建装备管理器（必须在 EffectTrigger 之前）
	equipment_manager = EquipmentManager.new()

	# 创建效果触发器和规则改写器
	effect_trigger = EffectTrigger.new(equipment_manager)
	rule_modifier = effect_trigger.get_rule_modifier()
	if rule_modifier == null:
		rule_modifier = RuleModifier.new()

	# 放置初始装备
	for eq: EquipmentData in equipment:
		var slot := _find_free_slot(eq)
		if slot.x >= 0 and slot.y >= 0:
			equipment_manager.add_to_inventory(eq)
			equipment_manager.place_equipment(eq, slot)

	# 起始回合
	turn_manager.start_new_turn()

	# 触发回合开始效果
	var start_results: Array[EffectTrigger.EffectResult] = effect_trigger.trigger_turn_start(
		turn_manager.current_turn, player_gold
	)
	for result: EffectTrigger.EffectResult in start_results:
		if result.gold_change != 0:
			player_gold += result.gold_change

	# 抽取初始手牌
	_draw_to_fill()


## 补充手牌至上限
func _draw_to_fill() -> void:
	var needed: int = hand_manager.max_hand_size - hand_manager.get_hand_size()
	if needed <= 0:
		return

	var new_cards: Array[CardData] = deck.draw_cards(needed)
	if new_cards.is_empty():
		return

	hand_manager.add_to_hand(new_cards)


## 自动选择当前手牌中得分最高的牌型组合
## 返回选中的卡牌数组
func auto_select_best() -> Array[CardData]:
	var hand := hand_manager.get_hand_ref()
	if hand.is_empty():
		return []

	var best_score: int = -1
	var best_combo: Array[CardData] = []

	# 尝试 1-5 张牌的所有组合
	var combos := _generate_combinations(hand, 1, min(5, hand.size()))
	for combo: Array[CardData] in combos:
		var result: HandType.HandResult = HandClassifier.evaluate_with_modifiers(combo, rule_modifier)
		if not result.is_valid:
			continue

		# 计算得分（含装备修正）
		var score: int = _calculate_score(result)
		if score > best_score:
			best_score = score
			best_combo = combo

	return best_combo


## 生成手牌的所有组合（简化迭代版本）
func _generate_combinations(arr: Array, min_len: int, max_len: int) -> Array[Array]:
	var result: Array[Array] = []
	var n: int = arr.size()

	for size in range(min_len, max_len + 1):
		var indices: Array[int] = []
		for i in range(size):
			indices.append(i)

		while true:
			var combo: Array = []
			for i: int in indices:
				combo.append(arr[i])
			result.append(combo)

			# 移动到下一个组合
			var j: int = size - 1
			while j >= 0 and indices[j] == j + n - size:
				j -= 1
			if j < 0:
				break
			indices[j] += 1
			for k in range(j + 1, size):
				indices[k] = indices[k - 1] + 1

	return result


## 计算得分（含装备修正和 Boss 规则）
func _calculate_score(hand_result: HandType.HandResult) -> int:
	if not hand_result.is_valid:
		return 0

	# 检查 Boss 规则 - 牌型排除
	if stage_config.has_boss_rule() and stage_config.boss_rule == StageConfig.BossRule.HAND_TYPE_EXCLUDED:
		var excluded_type: int = stage_config.boss_rule_param.get("hand_type", HandType.Type.HIGH_CARD)
		if hand_result.hand_type == excluded_type:
			return 0

	# 花色排除
	var adjusted_base_score: int = hand_result.base_score
	if stage_config.has_boss_rule() and stage_config.boss_rule == StageConfig.BossRule.SUIT_EXCLUDED:
		var excluded_suit: int = stage_config.boss_rule_param.get("suit", CardData.Suit.DIAMONDS)
		adjusted_base_score = 0
		for card: CardData in hand_result.cards:
			if card.suit != excluded_suit:
				adjusted_base_score += card.get_base_score()

	# 装备加分
	var modifiers: Dictionary = effect_trigger.get_score_modifiers()
	var score_bonus: int = modifiers.get("score_bonus", 0)
	var multiplier_bonus: float = modifiers.get("multiplier_bonus", 1.0)

	adjusted_base_score += score_bonus
	var adjusted_multiplier: int = int(hand_result.multiplier * multiplier_bonus)

	# 盲注倍率
	var blind_multiplier: int = BlindType.get_target_multiplier(stage_config.blind_type)

	return adjusted_base_score * adjusted_multiplier * blind_multiplier


## 执行一次出牌
## 返回出牌结果信息 Dictionary
func play_turn(cards: Array[CardData]) -> Dictionary:
	var info: Dictionary = {}

	# 选牌
	hand_manager.clear_selection()
	for c: CardData in cards:
		hand_manager.toggle_selection(c)

	# 牌型识别
	var hand_result: HandType.HandResult = HandClassifier.evaluate_with_modifiers(cards, rule_modifier)

	# 触发得分效果
	var score_effects: Array[EffectTrigger.EffectResult] = effect_trigger.trigger_score_effects(
		hand_result, 0, stage_config.blind_type
	)

	# 计算最终得分
	var score: int = _calculate_score(hand_result)
	current_score += score

	# 记录出牌
	turn_manager.record_play()

	# 移除已出牌
	hand_manager.remove_from_hand(cards)
	for c: CardData in cards:
		deck.discard(c)

	# 补充手牌
	_draw_to_fill()

	# Boss 手牌上限检查
	_check_hand_size_limit()

	# 触发回合结束效果
	var end_results: Array[EffectTrigger.EffectResult] = effect_trigger.trigger_turn_end(
		turn_manager.current_turn, player_gold
	)
	for result: EffectTrigger.EffectResult in end_results:
		if result.gold_change != 0:
			player_gold += result.gold_change

	# 记录
	info["hand_type"] = hand_result.hand_type
	info["hand_type_name"] = hand_result.get_display_name_cn()
	info["score"] = score
	info["current_total"] = current_score
	info["remaining_turns"] = turn_manager.remaining_turns
	info["cards_count"] = cards.size()
	play_history.append(info)

	# 开始新回合
	if not is_defeat() and not is_victory():
		turn_manager.plays_this_turn = 0
		turn_manager.start_new_turn()
		var start_results2: Array[EffectTrigger.EffectResult] = effect_trigger.trigger_turn_start(
			turn_manager.current_turn, player_gold
		)
		for result: EffectTrigger.EffectResult in start_results2:
			if result.gold_change != 0:
				player_gold += result.gold_change

	return info


## Boss 手牌上限检查
func _check_hand_size_limit() -> void:
	if not turn_manager.has_hand_size_limit():
		return

	var limit: int = turn_manager.get_hand_size_limit()
	var hand_ref := hand_manager.get_hand_ref()

	while hand_ref.size() > limit:
		var excess: CardData = hand_ref.pop_back()
		deck.discard(excess)


## 是否已胜利
func is_victory() -> bool:
	return current_score >= stage_config.get_target_score()


## 是否已失败
func is_defeat() -> bool:
	return turn_manager.is_turns_exhausted() and not is_victory()


## 运行完整战斗直到结束
## 返回 BattleResult Dictionary
func run_full_battle() -> Dictionary:
	var turns_played: int = 0

	while not is_defeat() and not is_victory():
		if not turn_manager.can_play():
			break

		var best := auto_select_best()
		if best.is_empty():
			# 无有效出牌，尝试弃牌重抽
			if hand_manager.get_hand_size() > 0:
				var discard_cards_count: int = min(hand_manager.get_hand_size(), 5)
				var to_discard: Array[CardData] = []
				var hand_ref := hand_manager.get_hand_ref()
				for i in range(discard_cards_count):
					if i < hand_ref.size():
						to_discard.append(hand_ref[i])
				hand_manager.remove_from_hand(to_discard)
				for c: CardData in to_discard:
					deck.discard(c)
				_draw_to_fill()
			continue

		play_turn(best)
		turns_played += 1

	return {
		"won": is_victory(),
		"score": current_score,
		"target": stage_config.get_target_score(),
		"turns_used": turns_played,
		"max_turns": stage_config.max_turns,
		"history": play_history.duplicate()
	}


## 查找空闲槽位放置装备
func _find_free_slot(eq: EquipmentData) -> Vector2i:
	for y in range(EquipmentManager.GRID_HEIGHT):
		for x in range(EquipmentManager.GRID_WIDTH):
			var pos := Vector2i(x, y)
			if equipment_manager.can_place(eq, pos):
				return pos
	return Vector2i(-1, -1)


## 获取战斗摘要字符串
func get_summary() -> String:
	var lines: Array[String] = []
	lines.append("=== 模拟战斗摘要 ===")
	lines.append("关卡: %s" % stage_config.display_name)
	lines.append("得分: %d / %d" % [current_score, stage_config.get_target_score()])
	lines.append("回合: %d" % play_history.size())
	lines.append("结果: %s" % ("胜利" if is_victory() else ("失败" if is_defeat() else "进行中")))

	for i in range(play_history.size()):
		var h := play_history[i]
		lines.append("  出牌 %d: %s (%d 张) → %d 分" % [
			i + 1,
			h.get("hand_type_name", "未知"),
			h.get("cards_count", 0),
			h.get("score", 0)
		])

	return "\n".join(lines)
