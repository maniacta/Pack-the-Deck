class_name BlindType
extends RefCounted

## Blind type enumeration for poker roguelike scoring.
## Defines ante levels that affect target score and rewards.

## Blind ante types - affects difficulty and rewards
enum Type {
	SMALL_BLIND,  ## Small ante - target ×1, reward ×1
	BIG_BLIND,    ## Big ante - target ×2, reward ×2
	BOSS_BLIND    ## Boss ante - target ×3, reward ×3, special rules
}

## Multipliers for target score by blind type
const TARGET_MULTIPLIERS: Dictionary = {
	Type.SMALL_BLIND: 1,
	Type.BIG_BLIND: 2,
	Type.BOSS_BLIND: 3
}

## Multipliers for rewards by blind type
const REWARD_MULTIPLIERS: Dictionary = {
	Type.SMALL_BLIND: 1,
	Type.BIG_BLIND: 2,
	Type.BOSS_BLIND: 3
}

## Display names for each blind type (Chinese)
const DISPLAY_NAMES_CN: Dictionary = {
	Type.SMALL_BLIND: "小盲注",
	Type.BIG_BLIND: "大盲注",
	Type.BOSS_BLIND: "Boss 盲注"
}

## Display names for each blind type (English)
const DISPLAY_NAMES_EN: Dictionary = {
	Type.SMALL_BLIND: "Small Blind",
	Type.BIG_BLIND: "Big Blind",
	Type.BOSS_BLIND: "Boss Blind"
}


## Get the target score multiplier for a blind type
static func get_target_multiplier(blind_type: Type) -> int:
	return TARGET_MULTIPLIERS.get(blind_type, 1)


## Get the reward multiplier for a blind type
static func get_reward_multiplier(blind_type: Type) -> int:
	return REWARD_MULTIPLIERS.get(blind_type, 1)


## Get the Chinese display name for a blind type
static func get_display_name_cn(blind_type: Type) -> String:
	return DISPLAY_NAMES_CN.get(blind_type, "未知")


## Get the English display name for a blind type
static func get_display_name_en(blind_type: Type) -> String:
	return DISPLAY_NAMES_EN.get(blind_type, "Unknown")


## Check if this blind type is a boss blind (has special rules)
static func is_boss(blind_type: Type) -> bool:
	return blind_type == Type.BOSS_BLIND