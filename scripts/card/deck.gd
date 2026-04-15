class_name Deck
extends RefCounted

## Manages a standard 52-card deck with shuffle and draw functionality.

## All cards in the deck
var _cards: Array[CardData] = []

## Cards that have been drawn (discard pile)
var _discarded: Array[CardData] = []


## Create a new standard 52-card deck
func _init() -> void:
	_initialize_standard_deck()


## Initialize the deck with all 52 standard playing cards
func _initialize_standard_deck() -> void:
	_cards.clear()
	_discarded.clear()
	
	const RANKS: Array[CardData.Rank] = [
		CardData.Rank.TWO, CardData.Rank.THREE, CardData.Rank.FOUR,
		CardData.Rank.FIVE, CardData.Rank.SIX, CardData.Rank.SEVEN,
		CardData.Rank.EIGHT, CardData.Rank.NINE, CardData.Rank.TEN,
		CardData.Rank.JACK, CardData.Rank.QUEEN, CardData.Rank.KING,
		CardData.Rank.ACE
	]
	
	const SUITS: Array[CardData.Suit] = [
		CardData.Suit.SPADES, CardData.Suit.HEARTS,
		CardData.Suit.DIAMONDS, CardData.Suit.CLUBS
	]
	
	for suit: CardData.Suit in SUITS:
		for rank: CardData.Rank in RANKS:
			var card := CardData.new()
			card.rank = rank
			card.suit = suit
			_cards.append(card)
	
	print("牌堆初始化完成，共 %d 张牌" % _cards.size())


## Shuffle the deck randomly
func shuffle() -> void:
	_cards.shuffle()


## Draw a card from the top of the deck
## Returns null if deck is empty
func draw_card() -> CardData:
	if _cards.is_empty():
		# Try to reshuffle discard pile
		if _discarded.is_empty():
			push_warning("无法抽取：牌堆和弃牌堆都已空")
			return null
		_reshuffle_discard()
	
	var card: CardData = _cards.pop_back()
	return card


## Draw multiple cards from the deck
## Returns an array of drawn cards (may be fewer than requested if deck is exhausted)
func draw_cards(count: int) -> Array[CardData]:
	var drawn: Array[CardData] = []
	
	for i in range(count):
		var card := draw_card()
		if card:
			drawn.append(card)
		else:
			break
	
	return drawn


## Discard a card (add to discard pile)
func discard(card: CardData) -> void:
	if card:
		_discarded.append(card)


## Discard multiple cards
func discard_cards(cards: Array[CardData]) -> void:
	for card: CardData in cards:
		discard(card)


## Reshuffle the discard pile back into the deck
func _reshuffle_discard() -> void:
	_cards.append_array(_discarded)
	_discarded.clear()
	shuffle()
	print("弃牌堆已重新洗入牌堆（%d 张牌）" % _cards.size())


## Get the number of cards remaining in the deck
func get_remaining_count() -> int:
	return _cards.size()


## Get the number of cards in the discard pile
func get_discard_count() -> int:
	return _discarded.size()


## Check if the deck is empty
func is_empty() -> bool:
	return _cards.is_empty()


## Reset the deck to a fresh 52-card deck
func reset() -> void:
	_initialize_standard_deck()
	shuffle()


## Get a copy of all cards in the deck (for testing/debugging)
func get_all_cards() -> Array[CardData]:
	return _cards.duplicate()
