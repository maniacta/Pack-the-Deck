class_name HandClassifier
extends RefCounted

## Poker hand classifier that evaluates a set of cards and identifies the hand type.
## Supports all standard poker hand rankings with proper handling of Ace as both 1 and 14.
## Now supports rule modifications from equipment.

## Evaluate a set of cards and return the best hand type found.
## The player selects cards manually, we just identify what hand they've made.
## 
## Parameters:
## - cards: The cards selected by the player (1-5 cards typically)
## 
## Returns:
## - HandResult containing the identified hand type, multiplier, and cards
static func evaluate(cards: Array[CardData]) -> HandType.HandResult:
	return evaluate_with_modifiers(cards, null)


## Evaluate with rule modifications from equipment.
## This is the enhanced version that supports rule rewriting.
## 
## Parameters:
## - cards: The cards selected by the player
## - modifier: RuleModifier from equipped items (can be null for default rules)
## 
## Returns:
## - HandResult with modified rules applied
static func evaluate_with_modifiers(cards: Array[CardData], modifier: RuleModifier) -> HandType.HandResult:
	if cards.is_empty():
		return HandType.HandResult.create_empty()
	
	# Sort cards by rank (descending, highest first)
	var sorted_cards: Array[CardData] = CardData.sort_by_rank_desc(cards)
	
	# Get rule parameters
	var straight_min: int = 5
	var flush_min: int = 5
	
	if modifier:
		straight_min = modifier.get_straight_min_cards()
		flush_min = modifier.get_flush_min_cards()
	
	# Check from highest to lowest hand type
	# Note: For 5 cards, we check all types
	# For fewer cards, we only check applicable types
	
	# Royal Flush (5 cards, 10-J-Q-K-A same suit)
	var royal_flush_result := _check_royal_flush(sorted_cards)
	if royal_flush_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.ROYAL_FLUSH):
			# Hand type disabled by equipment, skip to next
			pass
		else:
			return _apply_multiplier_modifier(royal_flush_result, modifier)
	
	# Straight Flush (cards consecutive, same suit) - now supports custom min
	var straight_flush_result := _check_straight_flush_with_min(sorted_cards, straight_min)
	if straight_flush_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.STRAIGHT_FLUSH):
			pass
		else:
			return _apply_multiplier_modifier(straight_flush_result, modifier)
	
	# Four of a Kind (4 cards of same rank)
	var four_kind_result := _check_four_of_a_kind(sorted_cards)
	if four_kind_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.FOUR_OF_A_KIND):
			pass
		else:
			return _apply_multiplier_modifier(four_kind_result, modifier)
	
	# Full House (3 + 2, exactly 5 cards)
	var full_house_result := _check_full_house(sorted_cards)
	if full_house_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.FULL_HOUSE):
			pass
		else:
			return _apply_multiplier_modifier(full_house_result, modifier)
	
	# Flush (same suit cards) - now supports custom min
	var flush_result := _check_flush_with_min(sorted_cards, flush_min)
	if flush_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.FLUSH):
			pass
		else:
			return _apply_multiplier_modifier(flush_result, modifier)
	
	# Straight (consecutive cards) - now supports custom min
	var straight_result := _check_straight_with_min(sorted_cards, straight_min)
	if straight_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.STRAIGHT):
			pass
		else:
			return _apply_multiplier_modifier(straight_result, modifier)
	
	# Three of a Kind (3 cards of same rank)
	var three_kind_result := _check_three_of_a_kind(sorted_cards)
	if three_kind_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.THREE_OF_A_KIND):
			pass
		else:
			return _apply_multiplier_modifier(three_kind_result, modifier)
	
	# Two Pair (2 pairs, 4 cards total)
	var two_pair_result := _check_two_pair(sorted_cards)
	if two_pair_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.TWO_PAIR):
			pass
		else:
			return _apply_multiplier_modifier(two_pair_result, modifier)
	
	# One Pair (2 cards of same rank)
	var one_pair_result := _check_one_pair(sorted_cards)
	if one_pair_result.is_valid:
		if modifier and not modifier.is_hand_type_enabled(HandType.Type.ONE_PAIR):
			pass
		else:
			return _apply_multiplier_modifier(one_pair_result, modifier)
	
	# High Card (default, any cards)
	return _apply_multiplier_modifier(HandType.HandResult.create_high_card(sorted_cards), modifier)


## Apply multiplier modification from equipment to a hand result
static func _apply_multiplier_modifier(result: HandType.HandResult, modifier: RuleModifier) -> HandType.HandResult:
	if not modifier:
		return result
	
	# Get modified multiplier
	var new_multiplier: int = modifier.get_hand_type_multiplier(result.hand_type)
	
	# Create new result with modified multiplier
	var modified_result := HandType.HandResult.new(result.hand_type, result.cards)
	modified_result.multiplier = new_multiplier
	modified_result.is_valid = result.is_valid
	
	return modified_result


# ============================================================================
# Individual Hand Type Checks
# ============================================================================

## Check for One Pair: exactly 2 cards of the same rank
static func _check_one_pair(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 2 cards for a pair
	if cards.size() != 2:
		return HandType.HandResult.create_empty()
	
	# Check if both cards have same rank
	if cards[0].rank == cards[1].rank:
		return HandType.HandResult.new(HandType.Type.ONE_PAIR, cards)
	
	return HandType.HandResult.create_empty()


## Check for Two Pair: exactly 4 cards forming two different pairs
static func _check_two_pair(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 4 cards
	if cards.size() != 4:
		return HandType.HandResult.create_empty()
	
	# Count ranks
	var rank_counts: Dictionary = _count_ranks(cards)
	
	# Should have exactly 2 ranks, each appearing 2 times
	var pairs: Array[int] = []
	for rank: int in rank_counts:
		if rank_counts[rank] == 2:
			pairs.append(rank)
	
	if pairs.size() == 2:
		# Sort pairs by rank (descending)
		pairs.sort()
		pairs.reverse()
		
		# Build result with cards from both pairs
		var pair_cards: Array[CardData] = []
		for card: CardData in cards:
			if card.rank == pairs[0] or card.rank == pairs[1]:
				pair_cards.append(card)
		
		return HandType.HandResult.new(HandType.Type.TWO_PAIR, pair_cards)
	
	return HandType.HandResult.create_empty()


## Check for Three of a Kind: exactly 3 cards of the same rank
static func _check_three_of_a_kind(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 3 cards
	if cards.size() != 3:
		return HandType.HandResult.create_empty()
	
	# All three must have same rank
	if cards[0].rank == cards[1].rank and cards[1].rank == cards[2].rank:
		return HandType.HandResult.new(HandType.Type.THREE_OF_A_KIND, cards)
	
	return HandType.HandResult.create_empty()


## Check for Straight: 5 consecutive cards (Ace can be 1 or 14)
static func _check_straight(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 5 cards
	if cards.size() != 5:
		return HandType.HandResult.create_empty()
	
	# Get ranks as integers
	var ranks: Array[int] = []
	for card: CardData in cards:
		ranks.append(int(card.rank))
	
	# Sort ranks (ascending)
	ranks.sort()
	
	# Check for regular straight (consecutive ranks)
	if _is_consecutive(ranks):
		return HandType.HandResult.new(HandType.Type.STRAIGHT, cards)
	
	# Check for Ace-low straight (A-2-3-4-5)
	# ranks would be [2, 3, 4, 5, 14] for A-2-3-4-5
	if ranks == [2, 3, 4, 5, 14]:
		return HandType.HandResult.new(HandType.Type.STRAIGHT, cards)
	
	return HandType.HandResult.create_empty()


## Check for Flush: 5 cards of the same suit
static func _check_flush(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 5 cards
	if cards.size() != 5:
		return HandType.HandResult.create_empty()
	
	# All cards must have the same suit
	var first_suit: CardData.Suit = cards[0].suit
	for card: CardData in cards:
		if card.suit != first_suit:
			return HandType.HandResult.create_empty()
	
	return HandType.HandResult.new(HandType.Type.FLUSH, cards)


## Check for Full House: 3 cards of one rank + 2 cards of another rank
static func _check_full_house(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 5 cards
	if cards.size() != 5:
		return HandType.HandResult.create_empty()
	
	# Count ranks
	var rank_counts: Dictionary = _count_ranks(cards)
	
	# Should have exactly 2 ranks: one with 3, one with 2
	var has_three: bool = false
	var has_two: bool = false
	var three_rank: int = 0
	
	for rank: int in rank_counts:
		if rank_counts[rank] == 3:
			has_three = true
			three_rank = rank
		elif rank_counts[rank] == 2:
			has_two = true
	
	if has_three and has_two:
		return HandType.HandResult.new(HandType.Type.FULL_HOUSE, cards)
	
	return HandType.HandResult.create_empty()


## Check for Four of a Kind: exactly 4 cards of the same rank
static func _check_four_of_a_kind(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 4 cards
	if cards.size() != 4:
		return HandType.HandResult.create_empty()
	
	# All four must have same rank
	if cards[0].rank == cards[1].rank and \
	   cards[1].rank == cards[2].rank and \
	   cards[2].rank == cards[3].rank:
		return HandType.HandResult.new(HandType.Type.FOUR_OF_A_KIND, cards)
	
	return HandType.HandResult.create_empty()


## Check for Straight Flush: 5 consecutive cards of the same suit
static func _check_straight_flush(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 5 cards
	if cards.size() != 5:
		return HandType.HandResult.create_empty()
	
	# Must be both a straight and a flush
	var is_straight: bool = _check_straight(cards).is_valid
	var is_flush: bool = _check_flush(cards).is_valid
	
	if is_straight and is_flush:
		return HandType.HandResult.new(HandType.Type.STRAIGHT_FLUSH, cards)
	
	return HandType.HandResult.create_empty()


## Check for Royal Flush: 10-J-Q-K-A of the same suit
static func _check_royal_flush(cards: Array[CardData]) -> HandType.HandResult:
	# Must have exactly 5 cards
	if cards.size() != 5:
		return HandType.HandResult.create_empty()
	
	# Must be a flush first
	if not _check_flush(cards).is_valid:
		return HandType.HandResult.create_empty()
	
	# Check for exactly 10, J, Q, K, A ranks
	var ranks: Array[int] = []
	for card: CardData in cards:
		ranks.append(int(card.rank))
	
	ranks.sort()
	
	# Royal flush ranks: [10, 11, 12, 13, 14]
	if ranks == [10, 11, 12, 13, 14]:
		return HandType.HandResult.new(HandType.Type.ROYAL_FLUSH, cards)
	
	return HandType.HandResult.create_empty()


# ============================================================================
# Helper Functions
# ============================================================================

## Count occurrences of each rank in a set of cards
static func _count_ranks(cards: Array[CardData]) -> Dictionary:
	var counts: Dictionary = {}
	for card: CardData in cards:
		var rank_value: int = int(card.rank)
		if counts.has(rank_value):
			counts[rank_value] += 1
		else:
			counts[rank_value] = 1
	return counts


## Check if an array of integers is consecutive (each value is +1 from previous)
static func _is_consecutive(values: Array[int]) -> bool:
	if values.size() < 2:
		return true
	
	for i in range(1, values.size()):
		if values[i] != values[i - 1] + 1:
			return false
	return true


## Count occurrences of each suit in a set of cards
static func _count_suits(cards: Array[CardData]) -> Dictionary:
	var counts: Dictionary = {}
	for card: CardData in cards:
		var suit_value: int = int(card.suit)
		if counts.has(suit_value):
			counts[suit_value] += 1
		else:
			counts[suit_value] = 1
	return counts


## Get the highest rank from a set of cards
static func _get_highest_rank(cards: Array[CardData]) -> int:
	if cards.is_empty():
		return 0
	var max_rank: int = 0
	for card: CardData in cards:
		if int(card.rank) > max_rank:
			max_rank = int(card.rank)
	return max_rank


## Get cards of a specific rank from a set
static func _get_cards_of_rank(cards: Array[CardData], rank: CardData.Rank) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in cards:
		if card.rank == rank:
			result.append(card)
	return result


# ============================================================================
# Rule Modifier Support Methods
# ============================================================================

## Check for Straight with customizable minimum cards
## Supports equipment that reduces minimum cards needed for a straight
static func _check_straight_with_min(cards: Array[CardData], min_cards: int) -> HandType.HandResult:
	# Must have at least min_cards cards
	if cards.size() < min_cards:
		return HandType.HandResult.create_empty()
	
	# For standard 5-card straight, use existing logic
	if min_cards == 5 and cards.size() == 5:
		return _check_straight(cards)
	
	# For reduced minimum (e.g., 4-card straight)
	# Find consecutive sequence of min_cards length
	var ranks: Array[int] = []
	for card: CardData in cards:
		ranks.append(int(card.rank))
	
	ranks.sort()
	
	# Check for consecutive sequence of min_cards length
	if _has_consecutive_sequence(ranks, min_cards):
		# Take the best consecutive sequence
		var best_sequence: Array[CardData] = _find_best_consecutive_cards(cards, min_cards)
		if not best_sequence.is_empty():
			return HandType.HandResult.new(HandType.Type.STRAIGHT, best_sequence)
	
	# Check for Ace-low straight (A-2-3-4-5)
	# This works for 5-card minimum, but for 4-card, check A-2-3-4 or 2-3-4-5
	if min_cards <= 4:
		# Check for A-2-3-4 sequence
		var ace_low_ranks: Array[int] = [2, 3, 4, 14]  # A=14 when sorted
		if _has_subset(ranks, ace_low_ranks.slice(0, min_cards)):
			var ace_low_cards: Array[CardData] = _find_ace_low_cards(cards, min_cards)
			if not ace_low_cards.is_empty():
				return HandType.HandResult.new(HandType.Type.STRAIGHT, ace_low_cards)
	
	return HandType.HandResult.create_empty()


## Check for Flush with customizable minimum cards
static func _check_flush_with_min(cards: Array[CardData], min_cards: int) -> HandType.HandResult:
	# Must have at least min_cards cards
	if cards.size() < min_cards:
		return HandType.HandResult.create_empty()
	
	# For standard 5-card flush, use existing logic
	if min_cards == 5 and cards.size() == 5:
		return _check_flush(cards)
	
	# Count suits
	var suit_counts: Dictionary = _count_suits(cards)
	
	# Find if any suit has at least min_cards
	for suit: int in suit_counts:
		if suit_counts[suit] >= min_cards:
			# Get the cards of that suit
			var suit_cards: Array[CardData] = _get_cards_of_suit(cards, suit)
			# Take the best min_cards (highest ranks)
			suit_cards = CardData.sort_by_rank_desc(suit_cards)
			var best_cards: Array[CardData] = []
			for i in range(min(min_cards, suit_cards.size())):
				best_cards.append(suit_cards[i])
			return HandType.HandResult.new(HandType.Type.FLUSH, best_cards)
	
	return HandType.HandResult.create_empty()


## Check for Straight Flush with customizable minimum cards
static func _check_straight_flush_with_min(cards: Array[CardData], min_cards: int) -> HandType.HandResult:
	# Must have at least min_cards cards
	if cards.size() < min_cards:
		return HandType.HandResult.create_empty()
	
	# First check for flush
	var flush_result: HandType.HandResult = _check_flush_with_min(cards, min_cards)
	if not flush_result.is_valid:
		return HandType.HandResult.create_empty()
	
	# Then check if flush cards form a straight
	var flush_cards: Array[CardData] = flush_result.cards
	var straight_result: HandType.HandResult = _check_straight_with_min(flush_cards, min_cards)
	if straight_result.is_valid:
		# Create straight flush result with the straight cards
		return HandType.HandResult.new(HandType.Type.STRAIGHT_FLUSH, straight_result.cards)
	
	# Also check all cards of the same suit for a straight
	# (for cases where we have more cards of one suit than min_cards)
	var suit_counts: Dictionary = _count_suits(cards)
	for suit: int in suit_counts:
		if suit_counts[suit] >= min_cards:
			var suit_cards: Array[CardData] = _get_cards_of_suit(cards, suit)
			var suit_straight: HandType.HandResult = _check_straight_with_min(suit_cards, min_cards)
			if suit_straight.is_valid:
				return HandType.HandResult.new(HandType.Type.STRAIGHT_FLUSH, suit_straight.cards)
	
	return HandType.HandResult.create_empty()


## Check if an array has a consecutive sequence of given length
static func _has_consecutive_sequence(values: Array[int], length: int) -> bool:
	if values.size() < length:
		return false
	
	# Sort and deduplicate
	var sorted: Array[int] = values.duplicate()
	sorted.sort()
	
	# Remove duplicates while keeping order
	var unique: Array[int] = []
	for v: int in sorted:
		if unique.is_empty() or unique[-1] != v:
			unique.append(v)
	
	# Check for consecutive sequence
	for start: int in range(unique.size() - length + 1):
		var consecutive: bool = true
		for i in range(1, length):
			if unique[start + i] != unique[start + i - 1] + 1:
				consecutive = false
				break
		if consecutive:
			return true
	
	return false


## Find the best consecutive cards for a straight
static func _find_best_consecutive_cards(cards: Array[CardData], min_cards: int) -> Array[CardData]:
	var sorted: Array[CardData] = CardData.sort_by_rank_desc(cards)
	var ranks: Array[int] = []
	for card: CardData in sorted:
		ranks.append(int(card.rank))
	
	ranks.sort()
	
	# Find highest consecutive sequence
	for start: int in range(ranks.size() - min_cards + 1):
		var consecutive: bool = true
		for i in range(1, min_cards):
			if ranks[start + i] != ranks[start + i - 1] + 1:
				consecutive = false
				break
		
		if consecutive:
			# Get cards matching these ranks
			var target_ranks: Array[int] = []
			for i in range(min_cards):
				target_ranks.append(ranks[start + i])
			
			var result: Array[CardData] = []
			for card: CardData in sorted:
				if int(card.rank) in target_ranks and result.size() < min_cards:
					result.append(card)
			return result
	
	return []


## Find ace-low cards for a straight (A-2-3-4...)
static func _find_ace_low_cards(cards: Array[CardData], min_cards: int) -> Array[CardData]:
	# We need Ace (14) and low cards (2, 3, 4...)
	var sorted: Array[CardData] = CardData.sort_by_rank_desc(cards)
	
	var ace_card: CardData = null
	var low_cards: Array[CardData] = []
	
	for card: CardData in sorted:
		if card.rank == CardData.Rank.ACE:
			ace_card = card
		elif int(card.rank) <= min_cards:  # 2, 3, 4, 5...
			low_cards.append(card)
	
	low_cards = CardData.sort_by_rank_desc(low_cards)
	
	# Build the sequence
	var result: Array[CardData] = []
	if ace_card:
		result.append(ace_card)
	
	for i in range(min(min_cards - 1, low_cards.size())):
		result.append(low_cards[i])
	
	if result.size() >= min_cards:
		return result
	
	return []


## Check if an array contains a subset of values
static func _has_subset(values: Array[int], subset: Array[int]) -> bool:
	for v: int in subset:
		if v not in values:
			return false
	return true


## Get cards of a specific suit from a set
static func _get_cards_of_suit(cards: Array[CardData], suit: int) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in cards:
		if int(card.suit) == suit:
			result.append(card)
	return result