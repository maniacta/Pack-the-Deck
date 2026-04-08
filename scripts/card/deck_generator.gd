@tool
class_name DeckGenerator
extends RefCounted

## Utility class for generating a standard 52-card deck.
## Run from editor to create card resource files.

const RANKS: Array[CardData.Rank] = [
	CardData.Rank.TWO,
	CardData.Rank.THREE,
	CardData.Rank.FOUR,
	CardData.Rank.FIVE,
	CardData.Rank.SIX,
	CardData.Rank.SEVEN,
	CardData.Rank.EIGHT,
	CardData.Rank.NINE,
	CardData.Rank.TEN,
	CardData.Rank.JACK,
	CardData.Rank.QUEEN,
	CardData.Rank.KING,
	CardData.Rank.ACE
]

const SUITS: Array[CardData.Suit] = [
	CardData.Suit.SPADES,
	CardData.Suit.HEARTS,
	CardData.Suit.DIAMONDS,
	CardData.Suit.CLUBS
]

const OUTPUT_DIR: String = "res://resources/cards/"


## Generate all 52 standard playing cards as resource files
static func generate_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	
	for suit: CardData.Suit in SUITS:
		for rank: CardData.Rank in RANKS:
			var card := CardData.new()
			card.rank = rank
			card.suit = suit
			
			var filename: String = card.get_id() + ".tres"
			var path: String = OUTPUT_DIR + filename
			
			# Save as resource file
			var error: int = ResourceSaver.save(card, path)
			if error != OK:
				push_error("Failed to save card: %s (error %d)" % [path, error])
			else:
				cards.append(card)
				print("Created: %s" % path)
	
	print("Generated %d cards" % cards.size())
	return cards


## Load all card resources from the resources/cards directory
static func load_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	var dir: DirAccess = DirAccess.open(OUTPUT_DIR)
	
	if not dir:
		push_error("Cannot open cards directory: %s" % OUTPUT_DIR)
		return cards
	
	dir.list_dir_begin()
	var filename := dir.get_next()
	
	while filename != "":
		if filename.ends_with(".tres"):
			var card := load(OUTPUT_DIR + filename) as CardData
			if card:
				cards.append(card)
		filename = dir.get_next()
	
	dir.list_dir_end()
	return cards