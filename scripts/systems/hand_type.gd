class_name HandType
extends RefCounted

## Poker hand type enumeration and result class.
## Defines all standard poker hand rankings from high card to royal flush.

## Poker hand types ranked from lowest to highest
enum Type {
	HIGH_CARD,       ## Any 5 cards that don't form a hand - multiplier 1
	ONE_PAIR,        ## Two cards of same rank - multiplier 2
	TWO_PAIR,        ## Two different pairs - multiplier 3
	THREE_OF_A_KIND, ## Three cards of same rank - multiplier 4
	STRAIGHT,        ## Five consecutive cards - multiplier 30
	FLUSH,           ## Five cards of same suit - multiplier 35
	FULL_HOUSE,      ## Three of a kind + one pair - multiplier 40
	FOUR_OF_A_KIND,  ## Four cards of same rank - multiplier 60
	STRAIGHT_FLUSH,  ## Straight + flush - multiplier 80
	ROYAL_FLUSH      ## 10-J-Q-K-A of same suit - multiplier 100
}

## Base multipliers for each hand type
const MULTIPLIERS: Dictionary = {
	Type.HIGH_CARD: 1,
	Type.ONE_PAIR: 2,
	Type.TWO_PAIR: 3,
	Type.THREE_OF_A_KIND: 4,
	Type.STRAIGHT: 30,
	Type.FLUSH: 35,
	Type.FULL_HOUSE: 40,
	Type.FOUR_OF_A_KIND: 60,
	Type.STRAIGHT_FLUSH: 80,
	Type.ROYAL_FLUSH: 100
}

## Display names for each hand type (Chinese)
const DISPLAY_NAMES_CN: Dictionary = {
	Type.HIGH_CARD: "高牌",
	Type.ONE_PAIR: "对子",
	Type.TWO_PAIR: "两对",
	Type.THREE_OF_A_KIND: "三条",
	Type.STRAIGHT: "顺子",
	Type.FLUSH: "同花",
	Type.FULL_HOUSE: "葫芦",
	Type.FOUR_OF_A_KIND: "四条",
	Type.STRAIGHT_FLUSH: "同花顺",
	Type.ROYAL_FLUSH: "皇家同花顺"
}

## Display names for each hand type (English)
const DISPLAY_NAMES_EN: Dictionary = {
	Type.HIGH_CARD: "High Card",
	Type.ONE_PAIR: "One Pair",
	Type.TWO_PAIR: "Two Pair",
	Type.THREE_OF_A_KIND: "Three of a Kind",
	Type.STRAIGHT: "Straight",
	Type.FLUSH: "Flush",
	Type.FULL_HOUSE: "Full House",
	Type.FOUR_OF_A_KIND: "Four of a Kind",
	Type.STRAIGHT_FLUSH: "Straight Flush",
	Type.ROYAL_FLUSH: "Royal Flush"
}


## Get the base multiplier for a hand type
static func get_multiplier(hand_type: Type) -> int:
	return MULTIPLIERS.get(hand_type, 1)


## Get the Chinese display name for a hand type
static func get_display_name_cn(hand_type: Type) -> String:
	return DISPLAY_NAMES_CN.get(hand_type, "未知")


## Get the English display name for a hand type
static func get_display_name_en(hand_type: Type) -> String:
	return DISPLAY_NAMES_EN.get(hand_type, "Unknown")


## Compare two hand types (higher is better)
## Returns: -1 if a < b, 0 if equal, 1 if a > b
static func compare(a: Type, b: Type) -> int:
	if a < b:
		return -1
	elif a > b:
		return 1
	return 0


# ============================================================================
# HandResult Class
# ============================================================================

## Result of a hand evaluation.
## Contains the hand type, multiplier, and cards that form the hand.
class HandResult extends RefCounted:
	
	## The type of poker hand identified
	var hand_type: HandType.Type = HandType.Type.HIGH_CARD
	
	## The base multiplier for this hand type
	var multiplier: int = 1
	
	## The cards that form this hand (the best 5 cards for the hand type)
	var cards: Array[CardData] = []
	
	## The base score sum of all cards in the hand
	var base_score: int = 0
	
	## Whether this result represents a valid hand
	var is_valid: bool = false
	
	## Additional info for debugging (optional)
	var debug_info: String = ""
	
	
	## Create a new hand result
	func _init(p_type: HandType.Type = HandType.Type.HIGH_CARD, p_cards: Array[CardData] = []) -> void:
		hand_type = p_type
		multiplier = HandType.get_multiplier(p_type)
		cards = p_cards
		is_valid = p_cards.size() > 0
		_calculate_base_score()
	
	
	## Calculate the total base score from all cards
	func _calculate_base_score() -> void:
		base_score = 0
		for card: CardData in cards:
			base_score += card.get_base_score()
	
	
	## Get the total score for this hand (base_score × multiplier)
	func get_total_score() -> int:
		return base_score * multiplier
	
	
	## Get the display name for this hand (Chinese)
	func get_display_name_cn() -> String:
		return HandType.get_display_name_cn(hand_type)
	
	
	## Get the display name for this hand (English)
	func get_display_name_en() -> String:
		return HandType.get_display_name_en(hand_type)
	
	
	## Get a summary string for debugging
	func get_summary() -> String:
		var card_names: Array[String] = []
		for card: CardData in cards:
			card_names.append(card.get_display_name())
		return "%s (%s) × %d = %d" % [
			get_display_name_cn(),
			", ".join(card_names),
			multiplier,
			get_total_score()
		]
	
	
	## Create an invalid/empty hand result
	static func create_empty() -> HandResult:
		var result := HandResult.new(HandType.Type.HIGH_CARD, [])
		result.is_valid = false
		return result
	
	
	## Create a high card result from any cards
	static func create_high_card(cards: Array[CardData]) -> HandResult:
		# For high card, take the best 5 cards (highest ranks)
		var sorted := CardData.sort_by_rank_desc(cards)
		var best_five: Array[CardData] = []
		for i in range(min(5, sorted.size())):
			best_five.append(sorted[i])
		return HandResult.new(HandType.Type.HIGH_CARD, best_five)