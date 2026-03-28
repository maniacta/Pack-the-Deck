class_name HandClassifier
extends RefCounted

## Poker hand classifier that evaluates a set of cards and identifies the hand type.
## Supports all standard poker hand rankings with proper handling of Ace as both 1 and 14.

## Evaluate a set of cards and return the best hand type found.
## The player selects cards manually, we just identify what hand they've made.
## 
## Parameters:
## - cards: The cards selected by the player (1-5 cards typically)
## 
## Returns:
## - HandResult containing the identified hand type, multiplier, and cards
static func evaluate(cards: Array[CardData]) -> HandType.HandResult:
	if cards.is_empty():
		return HandType.HandResult.create_empty()
	
	# Sort cards by rank (descending, highest first)
	var sorted_cards: Array[CardData] = CardData.sort_by_rank_desc(cards)
	
	# Check from highest to lowest hand type
	# Note: For 5 cards, we check all types
	# For fewer cards, we only check applicable types
	
	# Royal Flush (5 cards, 10-J-Q-K-A same suit)
	var royal_flush_result := _check_royal_flush(sorted_cards)
	if royal_flush_result.is_valid:
		return royal_flush_result
	
	# Straight Flush (5 cards consecutive, same suit)
	var straight_flush_result := _check_straight_flush(sorted_cards)
	if straight_flush_result.is_valid:
		return straight_flush_result
	
	# Four of a Kind (4 cards of same rank)
	var four_kind_result := _check_four_of_a_kind(sorted_cards)
	if four_kind_result.is_valid:
		return four_kind_result
	
	# Full House (3 + 2, exactly 5 cards)
	var full_house_result := _check_full_house(sorted_cards)
	if full_house_result.is_valid:
		return full_house_result
	
	# Flush (5 cards same suit)
	var flush_result := _check_flush(sorted_cards)
	if flush_result.is_valid:
		return flush_result
	
	# Straight (5 cards consecutive)
	var straight_result := _check_straight(sorted_cards)
	if straight_result.is_valid:
		return straight_result
	
	# Three of a Kind (3 cards of same rank)
	var three_kind_result := _check_three_of_a_kind(sorted_cards)
	if three_kind_result.is_valid:
		return three_kind_result
	
	# Two Pair (2 pairs, 4 cards total)
	var two_pair_result := _check_two_pair(sorted_cards)
	if two_pair_result.is_valid:
		return two_pair_result
	
	# One Pair (2 cards of same rank)
	var one_pair_result := _check_one_pair(sorted_cards)
	if one_pair_result.is_valid:
		return one_pair_result
	
	# High Card (default, any cards)
	return HandType.HandResult.create_high_card(sorted_cards)


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