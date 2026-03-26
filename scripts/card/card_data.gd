class_name CardData
extends Resource

## Card data for standard playing cards.
## Stores rank (2-10, J, Q, K, A), suit (Spades, Hearts, Diamonds, Clubs),
## and provides base score calculation.

## Signal emitted when card data changes
signal changed()

## Card suits - standard French-suited playing cards
enum Suit {
	SPADES,    ## ♠ - Black
	HEARTS,    ## ♥ - Red
	DIAMONDS,  ## ♦ - Red
	CLUBS      ## ♣ - Black
}

## Card ranks - 2 through Ace
enum Rank {
	TWO = 2,
	THREE = 3,
	FOUR = 4,
	FIVE = 5,
	SIX = 6,
	SEVEN = 7,
	EIGHT = 8,
	NINE = 9,
	TEN = 10,
	JACK = 11,
	QUEEN = 12,
	KING = 13,
	ACE = 14
}

## Card suit - which of the four suits this card belongs to
@export var suit: Suit = Suit.SPADES:
	set(value):
		if suit != value:
			suit = value
			changed.emit()

## Card rank - face value of the card (2-14, where 14 is Ace)
@export var rank: Rank = Rank.TWO:
	set(value):
		if rank != value:
			rank = value
			changed.emit()

## Cached base score value
var _cached_base_score: int = -1


## Create a new card with specified rank and suit
func _init(p_rank: Rank = Rank.TWO, p_suit: Suit = Suit.SPADES) -> void:
	rank = p_rank
	suit = p_suit


## Get the base score value for this card
## - Number cards (2-10): face value
## - Face cards (J, Q, K): 10 points
## - Ace: 11 points (can be modified by equipment)
func get_base_score() -> int:
	if _cached_base_score < 0:
		_cached_base_score = _calculate_base_score()
	return _cached_base_score


## Calculate base score based on rank
func _calculate_base_score() -> int:
	match rank:
		Rank.JACK, Rank.QUEEN, Rank.KING:
			return 10
		Rank.ACE:
			return 11
		_:
			return int(rank)


## Get the display string for rank (e.g., "A", "K", "Q", "J", "10", "2")
func get_rank_display() -> String:
	match rank:
		Rank.ACE:
			return "A"
		Rank.KING:
			return "K"
		Rank.QUEEN:
			return "Q"
		Rank.JACK:
			return "J"
		_:
			return str(int(rank))


## Get the display string for suit symbol (e.g., "♠", "♥", "♦", "♣")
func get_suit_display() -> String:
	match suit:
		Suit.SPADES:
			return "♠"
		Suit.HEARTS:
			return "♥"
		Suit.DIAMONDS:
			return "♦"
		Suit.CLUBS:
			return "♣"
		_:
			return "?"


## Get the suit color for UI display
func get_suit_color() -> Color:
	match suit:
		Suit.HEARTS, Suit.DIAMONDS:
			return Color.RED
		_:
			return Color.BLACK


## Get a unique identifier for this card (e.g., "spades_ace", "hearts_5")
func get_id() -> String:
	var suit_name: String = Suit.keys()[suit].to_lower()
	var rank_name: String = Rank.keys()[rank].to_lower()
	return "%s_%s" % [suit_name, rank_name]


## Get a human-readable name for this card (e.g., "Ace of Spades")
func get_display_name() -> String:
	return "%s of %s" % [get_rank_display(), Suit.keys()[suit].capitalize()]


## Check if this card is a face card (J, Q, K)
func is_face_card() -> bool:
	return rank in [Rank.JACK, Rank.QUEEN, Rank.KING]


## Check if this card is an Ace
func is_ace() -> bool:
	return rank == Rank.ACE


## Get numeric rank value (for sorting and comparison)
func get_numeric_rank() -> int:
	return int(rank)


## Compare two cards by rank (for sorting)
## Returns: -1 if self < other, 0 if equal, 1 if self > other
static func compare_by_rank(a: CardData, b: CardData) -> int:
	if a.rank < b.rank:
		return -1
	elif a.rank > b.rank:
		return 1
	return 0


## Sort an array of cards by rank (descending, highest first)
static func sort_by_rank_desc(cards: Array[CardData]) -> Array[CardData]:
	var sorted: Array[CardData] = cards.duplicate()
	sorted.sort_custom(func(a: CardData, b: CardData) -> bool:
		return a.rank > b.rank
	)
	return sorted


## Create a card from rank and suit values (factory method)
static func create(p_rank: Rank, p_suit: Suit) -> CardData:
	var card := CardData.new()
	card.rank = p_rank
	card.suit = p_suit
	return card