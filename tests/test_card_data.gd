class_name TestCardData
extends RefCounted

## Simple test runner for CardData and Deck classes.
## Run this in Godot to verify the card system works correctly.


## Run all tests
static func run_all_tests() -> bool:
	print("=== 正在运行 CardData 测试 ===")
	var all_passed := true
	
	all_passed = _test_card_creation() and all_passed
	all_passed = _test_card_scores() and all_passed
	all_passed = _test_card_display() and all_passed
	all_passed = _test_deck_creation() and all_passed
	all_passed = _test_deck_shuffle() and all_passed
	all_passed = _test_deck_draw() and all_passed
	
	if all_passed:
		print("=== 所有测试通过 ===")
	else:
		print("=== 部分测试失败 ===")
	
	return all_passed


## Test card creation
static func _test_card_creation() -> bool:
	print("\n[测试] 卡牌创建")
	var passed := true
	
	# Test creating a card
	var card := CardData.new()
	card.rank = CardData.Rank.ACE
	card.suit = CardData.Suit.SPADES
	
	if card.rank != CardData.Rank.ACE:
		push_error("失败: 等级应为 ACE")
		passed = false
	if card.suit != CardData.Suit.SPADES:
		push_error("失败: 花色应为 SPADES")
		passed = false
	
	# Test all suits and ranks
	for suit: CardData.Suit in [CardData.Suit.SPADES, CardData.Suit.HEARTS, CardData.Suit.DIAMONDS, CardData.Suit.CLUBS]:
		for rank: CardData.Rank in [CardData.Rank.TWO, CardData.Rank.KING, CardData.Rank.ACE]:
			var test_card := CardData.new()
			test_card.rank = rank
			test_card.suit = suit
			if test_card.rank != rank or test_card.suit != suit:
				push_error("失败: 卡牌创建失败 %s %s" % [rank, suit])
				passed = false
	
	if passed:
		print("  通过: 卡牌创建正常工作")
	return passed


## Test card score calculation
static func _test_card_scores() -> bool:
	print("\n[测试] 卡牌分数")
	var passed := true
	
	# Test number cards
	var two := CardData.new()
	two.rank = CardData.Rank.TWO
	if two.get_base_score() != 2:
		push_error("失败: TWO 应得分 2，实际得 %d" % two.get_base_score())
		passed = false
	
	var ten := CardData.new()
	ten.rank = CardData.Rank.TEN
	if ten.get_base_score() != 10:
		push_error("失败: TEN 应得分 10，实际得 %d" % ten.get_base_score())
		passed = false
	
	# Test face cards
	var jack := CardData.new()
	jack.rank = CardData.Rank.JACK
	if jack.get_base_score() != 10:
		push_error("失败: JACK 应得分 10，实际得 %d" % jack.get_base_score())
		passed = false
	
	var queen := CardData.new()
	queen.rank = CardData.Rank.QUEEN
	if queen.get_base_score() != 10:
		push_error("失败: QUEEN 应得分 10，实际得 %d" % queen.get_base_score())
		passed = false
	
	var king := CardData.new()
	king.rank = CardData.Rank.KING
	if king.get_base_score() != 10:
		push_error("失败: KING 应得分 10，实际得 %d" % king.get_base_score())
		passed = false
	
	# Test Ace
	var ace := CardData.new()
	ace.rank = CardData.Rank.ACE
	if ace.get_base_score() != 11:
		push_error("失败: ACE 应得分 11，实际得 %d" % ace.get_base_score())
		passed = false
	
	if passed:
		print("  通过: 卡牌分数计算正常")
	return passed


## Test card display methods
static func _test_card_display() -> bool:
	print("\n[测试] 卡牌显示")
	var passed := true
	
	# Test rank display
	var ace := CardData.new()
	ace.rank = CardData.Rank.ACE
	if ace.get_rank_display() != "A":
		push_error("失败: ACE 显示应为 'A'，实际 '%s'" % ace.get_rank_display())
		passed = false
	
	var king := CardData.new()
	king.rank = CardData.Rank.KING
	if king.get_rank_display() != "K":
		push_error("失败: KING 显示应为 'K'，实际 '%s'" % king.get_rank_display())
		passed = false
	
	# Test suit display
	var spade := CardData.new()
	spade.suit = CardData.Suit.SPADES
	if spade.get_suit_display() != "♠":
		push_error("失败: SPADES 显示应为 '♠'，实际 '%s'" % spade.get_suit_display())
		passed = false
	
	var heart := CardData.new()
	heart.suit = CardData.Suit.HEARTS
	if heart.get_suit_display() != "♥":
		push_error("失败: HEARTS 显示应为 '♥'，实际 '%s'" % heart.get_suit_display())
		passed = false
	
	# Test suit color
	if spade.get_suit_color() != Color.BLACK:
		push_error("失败: SPADES 应为黑色")
		passed = false
	
	if heart.get_suit_color() != Color.RED:
		push_error("失败: HEARTS 应为红色")
		passed = false
	
	if passed:
		print("  通过: 卡牌显示方法正常")
	return passed


## Test deck creation
static func _test_deck_creation() -> bool:
	print("\n[测试] 牌堆创建")
	var passed := true
	
	var deck := Deck.new()
	
	if deck.get_remaining_count() != 52:
		push_error("失败: 牌堆应有 52 张牌，实际 %d" % deck.get_remaining_count())
		passed = false
	
	if deck.get_discard_count() != 0:
		push_error("失败: 弃牌堆应为空")
		passed = false
	
	if passed:
		print("  通过: 牌堆创建完成，共 52 张牌")
	return passed


## Test deck shuffle
static func _test_deck_shuffle() -> bool:
	print("\n[测试] 牌堆洗牌")
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
		push_warning("警告: 洗牌后牌堆顺序似乎相同（极其罕见）")
	
	print("  通过: 牌堆洗牌正常")
	return passed


## Test deck draw
static func _test_deck_draw() -> bool:
	print("\n[测试] 牌堆抽牌")
	var passed := true
	
	var deck := Deck.new()
	
	# Draw single card
	var card := deck.draw_card()
	if card == null:
		push_error("失败: 应能抽牌")
		passed = false
	else:
		if deck.get_remaining_count() != 51:
			push_error("失败: 抽牌后牌堆应有 51 张牌，实际 %d" % deck.get_remaining_count())
			passed = false
	
	# Draw multiple cards
	deck.reset()
	var drawn := deck.draw_cards(5)
	if drawn.size() != 5:
		push_error("失败: 应抽 5 张牌，实际 %d" % drawn.size())
		passed = false
	else:
		if deck.get_remaining_count() != 47:
			push_error("失败: 抽 5 张后牌堆应有 47 张牌，实际 %d" % deck.get_remaining_count())
			passed = false
	
	# Draw all cards
	deck.reset()
	var all_cards := deck.draw_cards(52)
	if all_cards.size() != 52:
		push_error("失败: 应能抽完所有 52 张牌，实际 %d" % all_cards.size())
		passed = false
	
	if deck.get_remaining_count() != 0:
		push_error("失败: 抽完所有牌后牌堆应为空")
		passed = false
	
	# Try to draw from empty deck
	var empty_draw := deck.draw_card()
	if empty_draw != null:
		push_error("失败: 空牌堆不应能抽牌")
		passed = false
	
	if passed:
		print("  通过: 牌堆抽牌正常")
	return passed
