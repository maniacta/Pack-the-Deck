class_name StageConfig
extends Resource

## Stage configuration for poker roguelike game.
## Defines target score, turns, blind type, and boss special rules.

## Boss special rule types
enum BossRule {
	NONE,                ## No special rule
	SUIT_EXCLUDED,       ## A specific suit doesn't score
	HAND_TYPE_EXCLUDED,  ## A specific hand type doesn't score
	PLAY_LIMIT,          ## Limit number of plays per turn
	CARD_LIMIT,          ## Limit number of cards in hand
}

## Stage ID (unique identifier)
@export var stage_id: String = "stage_1"

## Stage display name
@export var display_name: String = "关卡 1"

## Base target score (before blind multiplier)
@export var base_target_score: int = 100

## Maximum number of turns/rounds
@export var max_turns: int = 3

## Blind ante type for this stage
@export var blind_type: BlindType.Type = BlindType.Type.SMALL_BLIND

## Boss special rule (only applies to BOSS_BLIND)
@export var boss_rule: BossRule = BossRule.NONE

## Boss rule parameter (e.g., which suit is excluded)
@export var boss_rule_param: Dictionary = {}

## Reward for passing this stage (base value, before blind multiplier)
@export var base_reward: int = 10

## Initial hand size
@export var initial_hand_size: int = 8

## Maximum hand size
@export var max_hand_size: int = 8

## Maximum cards to select for a play
@export var max_selection_size: int = 5


## Get the actual target score after applying blind multiplier
func get_target_score() -> int:
	return base_target_score * BlindType.get_target_multiplier(blind_type)


## Get the actual reward after applying blind multiplier
func get_reward() -> int:
	return base_reward * BlindType.get_reward_multiplier(blind_type)


## Check if this stage has a boss special rule
func has_boss_rule() -> bool:
	return blind_type == BlindType.Type.BOSS_BLIND and boss_rule != BossRule.NONE


## Get the boss rule description
func get_boss_rule_description() -> String:
	if not has_boss_rule():
		return ""
	
	match boss_rule:
		BossRule.SUIT_EXCLUDED:
			var suit_name: String = boss_rule_param.get("suit_name", "方块")
			return "%s 不计分" % suit_name
		BossRule.HAND_TYPE_EXCLUDED:
			var hand_name: String = boss_rule_param.get("hand_name", "顺子")
			return "%s 不计分" % hand_name
		BossRule.PLAY_LIMIT:
			var limit: int = boss_rule_param.get("limit", 3)
			return "每回合最多出牌 %d 次" % limit
		BossRule.CARD_LIMIT:
			var limit: int = boss_rule_param.get("limit", 5)
			return "手牌上限 %d 张" % limit
		_:
			return ""


## Get a full description of this stage
func get_full_description() -> String:
	var lines: Array[String] = []
	lines.append("【%s】" % display_name)
	lines.append("目标分数: %d" % get_target_score())
	lines.append("回合限制: %d" % max_turns)
	lines.append("盲注类型: %s" % BlindType.get_display_name_cn(blind_type))
	
	if has_boss_rule():
		lines.append("特殊规则: %s" % get_boss_rule_description())
	
	lines.append("过关奖励: %d 金币" % get_reward())
	
	return "\n".join(lines)


## Validate that this stage config is properly configured
func is_valid() -> bool:
	if base_target_score <= 0:
		push_error("StageConfig: base_target_score 必须为正数")
		return false
	
	if max_turns <= 0:
		push_error("StageConfig: max_turns 必须为正数")
		return false
	
	if blind_type == BlindType.Type.BOSS_BLIND and boss_rule == BossRule.NONE:
		# Boss blind without special rule is valid, but warn
		push_warning("StageConfig: Boss 盲注未定义特殊规则")
	
	return true


## Create a simple test stage (factory method)
static func create_test_stage(
	p_id: String,
	p_name: String,
	p_target: int,
	p_turns: int,
	p_blind: BlindType.Type
) -> StageConfig:
	var stage := StageConfig.new()
	stage.stage_id = p_id
	stage.display_name = p_name
	stage.base_target_score = p_target
	stage.max_turns = p_turns
	stage.blind_type = p_blind
	return stage
