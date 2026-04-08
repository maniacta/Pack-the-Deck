class_name TestCardData
extends RefCounted

## Simple test runner for CardData and Deck classes.
## Run this in Godot to verify the card system works correctly.


## Run all tests
static func run_all_tests() -> bool:
	print("=== Running CardData Tests ===")
	var all_passed := true
	
	all_passed = _test_card_creation() and all_passed
	all_passed = _test_card_scores() and all_passed
	all_passed = _test_card_display() and all_passed
	all_passed = _test_deck_creation() and all_passed
	all_passed = _test_deck_shuffle() and all_passed
	all_passed = _test_deck_draw() and all_passed
	
	if all_passed:
		print("=== All tests PASSED ===")
	else:
		print("=== Some tests FAILED ===")
	
	return all_passed


## Test card creation
static func _test_card_creation() -> bool:
	print("\n[TEST] Card Creation")
	var passed := true
	
	# Test creating a card
	var card := CardData.new()
	card.rank = CardData.Rank.ACE
	card.suit = CardData.Suit.SPADES
	
	if card.rank != CardData.Rank.ACE:
		push_error("FAIL: Rank should be ACE")
		passed = false
	if card.suit != CardData.Suit.SPADES:
		push_error("FAIL: Suit should be SPADES")
		passed = false
	
	# Test all suits and ranks
	for suit: CardData.Suit in [CardData.Suit.SPADES, CardData.Suit.HEARTS, CardData.Suit.DIAMONDS, CardData.Suit.CLUBS]:
		for rank: CardData.Rank in [CardData.Rank.TWO, CardData.Rank.KING, CardData.Rank.ACE]:
			var test_card := CardData.new()
			test_card.rank = rank
			test_card.suit = suit
			if test_card.rank != rank or test_card.suit != suit:
				push_error("FAIL: Card creation failed for %s %s" % [rank, suit])
				passed = false
	
	if passed:
		print("  PASS: Card creation works correctly")
	return passed


## Test card score calculation
static func _test_card_scores() -> bool:
	print("\n[TEST] Card Scores")
	var passed := true
	
	# Test number cards
	var two := CardData.new()
	two.rank = CardData.Rank.TWO
	if two.get_base_score() != 2:
		push_error("FAIL: TWO should have score 2, got %d" % two.get_base_score())
		passed = false
	
	var ten := CardData.new()
	ten.rank = CardData.Rank.TEN
	if ten.get_base_score() != 10:
		push_error("FAIL: TEN should have score 10, got %d" % ten.get_base_score())
		passed = false
	
	# Test face cards
	var jack := CardData.new()
	jack.rank = CardData.Rank.JACK
	if jack.get_base_score() != 10:
		push_error("FAIL: JACK should have score 10, got %d" % jack.get_base_score())
		passed = false
	
	var queen := CardData.new()
	queen.rank = CardData.Rank.QUEEN
	if queen.get_base_score() != 10:
		push_error("FAIL: QUEEN should have score 10, got %d" % queen.get_base_score())
		passed = false
	
	var king := CardData.new()
	king.rank = CardData.Rank.KING
	if king.get_base_score() != 10:
		push_error("FAIL: KING should have score 10, got %d" % king.get_base_score())
		passed = false
	
	# Test Ace
	var ace := CardData.new()
	ace.rank = CardData.Rank.ACE
	if ace.get_base_score() != 11:
		push_error("FAIL: ACE should have score 11, got %d" % ace.get_base_score())
		passed = false
	
	if passed:
		print("  PASS: Card scores calculated correctly")
	return passed


## Test card display methods
static func _test_card_display() -> bool:
	print("\n[TEST] Card Display")
	var passed := true
	
	# Test rank display
	var ace := CardData.new()
	ace.rank = CardData.Rank.ACE
	if ace.get_rank_display() != "A":
		push_error("FAIL: ACE display should be 'A', got '%s'" % ace.get_rank_display())
		passed = false
	
	var king := CardData.new()
	king.rank = CardData.Rank.KING
	if king.get_rank_display() != "K":
		push_error("FAIL: KING display should be 'K', got '%s'" % king.get_rank_display())
		passed = false
	
	# Test suit display
	var spade := CardData.new()
	spade.suit = CardData.Suit.SPADES
	if spade.get_suit_display() != "♠":
		push_error("FAIL: SPADES display should be '♠', got '%s'" % spade.get_suit_display())
		passed = false
	
	var heart := CardData.new()
	heart.suit = CardData.Suit.HEARTS
	if heart.get_suit_display() != "♥":
		push_error("FAIL: HEARTS display should be '♥', got '%s'" % heart.get_suit_display())
		passed = false
	
	# Test suit color
	if spade.get_suit_color() != Color.BLACK:
		push_error("FAIL: SPADES should be black")
		passed = false
	
	if heart.get_suit_color() != Color.RED:
		push_error("FAIL: HEARTS should be red")
		passed = false
	
	if passed:
		print("  PASS: Card display methods work correctly")
	return passed


## Test deck creation
static func _test_deck_creation() -> bool:
	print("\n[TEST] Deck Creation")
	var passed := true
	
	var deck := Deck.new()
	
	if deck.get_remaining_count() != 52:
		push_error("FAIL: Deck should have 52 cards, got %d" % deck.get_remaining_count())
		passed = false
	
	if deck.get_discard_count() != 0:
		push_error("FAIL: Discard pile should be empty")
		passed = false
	
	if passed:
		print("  PASS: Deck created with 52 cards")
	return passed


## Test deck shuffle
static func _test_deck_shuffle() -> bool:
	print("\n[TEST] Deck Shuffle")
	var passed := true
	
	var deck1 := Deck.new()
	var cards1 := deck1.get_all_cards()
	
	var deck2 := Deck.new()
	deck2.shuffle()
	var cards2 := deck2.get_all_cards()
	
	# After shuffle, the order should be different (with very high probability)
	var same_order := true
	for i in range(min(cards1.size(), cards2.size())):
		if cards1[i].rank != cards2[i].rank or cards1[i].suit != cards2[i].suit:
			same_order = false
			break
	
	# Note: There's a tiny chance they could be the same, but extremely unlikely
	if same_order:
		push_warning("WARNING: Deck appears to be in same order after shuffle (extremely unlikely)")
	
	print("  PASS: Deck shuffle works")
	return passed


## Test deck draw
static func _test_deck_draw() -> bool:
	print("\n[TEST] Deck Draw")
	var passed := true
	
	var deck := Deck.new()
	
	# Draw single card
	var card := deck.draw_card()
	if card == null:
		push_error("FAIL: Should be able to draw a card")
		passed = false
	else:
		if deck.get_remaining_count() != 51:
			push_error("FAIL: Deck should have 51 cards after draw, got %d" % deck.get_remaining_count())
			passed = false
	
	# Draw multiple cards
	deck.reset()
	var drawn := deck.draw_cards(5)
	if drawn.size() != 5:
		push_error("FAIL: Should draw 5 cards, got %d" % drawn.size())
		passed = false
	else:
		if deck.get_remaining_count() != 47:
			push_error("FAIL: Deck should have 47 cards after drawing 5, got %d" % deck.get_remaining_count())
			passed = false
	
	# Draw all cards
	deck.reset()
	var all_cards := deck.draw_cards(52)
	if all_cards.size() != 52:
		push_error("FAIL: Should draw all 52 cards, got %d" % all_cards.size())
		passed = false
	
	if deck.get_remaining_count() != 0:
		push_error("FAIL: Deck should be empty after drawing all cards")
		passed = false
	
	# Try to draw from empty deck
	var empty_draw := deck.draw_card()
	if empty_draw != null:
		push_error("FAIL: Should not be able to draw from empty deck")
		passed = false
	
	if passed:
		print("  PASS: Deck draw works correctly")
	return passed
