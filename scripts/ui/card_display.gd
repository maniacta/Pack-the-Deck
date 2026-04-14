class_name CardDisplay
extends Control

## Card display component for visualizing a single playing card.
## Handles card rendering, selection state, and click interactions.

## Signal emitted when this card is clicked
signal card_clicked(card_data: CardData)

## Signal emitted when selection state changes
signal selection_changed(is_selected: bool)

## Card data to display
var card_data: CardData = null

## Whether this card is currently selected
var is_selected: bool = false:
	set(value):
		if is_selected != value:
			is_selected = value
			_update_selection_visual()
			selection_changed.emit(is_selected)

## Whether this card can be selected (clickable)
var is_selectable: bool = true

## Card dimensions (default 100x140 as per design spec)
const CARD_WIDTH: int = 100
const CARD_HEIGHT: int = 140

## UI color constants (from battle-scene-design.md)
const COLOR_CARD_BLACK_SUIT: Color = Color("#2d2d44")  # Background for Spades/Clubs
const COLOR_CARD_RED_SUIT: Color = Color("#442d2d")    # Background for Hearts/Diamonds
const COLOR_SELECTION_BORDER: Color = Color("#ffd700") # Gold selection border
const COLOR_TEXT_BLACK_SUIT: Color = Color.WHITE       # Text for Spades/Clubs
const COLOR_TEXT_RED_SUIT: Color = Color("#ff6b6b")    # Text for Hearts/Diamonds

# Node references
@onready var _card_background: Panel = $CardBackground
@onready var _rank_label: Label = $RankLabel
@onready var _suit_label: Label = $SuitLabel
@onready var _selection_border: Panel = $SelectionBorder


func _ready() -> void:
	# Set default size
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	
	# Initialize visual state
	_update_selection_visual()


## Setup this card display with card data
func setup(data: CardData) -> void:
	card_data = data
	_update_display()


## Update the visual display based on current card data
func _update_display() -> void:
	if not card_data:
		return
	
	if not is_node_ready():
		await ready
	
	# Update rank and suit text
	_rank_label.text = card_data.get_rank_display()
	_suit_label.text = card_data.get_suit_display()
	
	# Determine colors based on suit
	var is_red_suit: bool = card_data.suit in [CardData.Suit.HEARTS, CardData.Suit.DIAMONDS]
	
	# Update background color - create a new style to avoid affecting other cards
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = is_red_suit ? COLOR_CARD_RED_SUIT : COLOR_CARD_BLACK_SUIT
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.4, 0.4, 0.5, 1)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.corner_radius_bottom_left = 8
	_card_background.add_theme_stylebox_override("panel", bg_style)
	
	# Update text colors
	var text_color: Color = is_red_suit ? COLOR_TEXT_RED_SUIT : COLOR_TEXT_BLACK_SUIT
	_rank_label.add_theme_color_override("font_color", text_color)
	_suit_label.add_theme_color_override("font_color", text_color)


## Update the selection border visibility and color
func _update_selection_visual() -> void:
	if not is_node_ready():
		return
	
	if _selection_border:
		_selection_border.visible = is_selected
		if is_selected:
			# Create a new style for selection border
			var border_style: StyleBoxFlat = StyleBoxFlat.new()
			border_style.bg_color = Color(0, 0, 0, 0)
			border_style.border_width_left = 3
			border_style.border_width_top = 3
			border_style.border_width_right = 3
			border_style.border_width_bottom = 3
			border_style.border_color = COLOR_SELECTION_BORDER
			border_style.corner_radius_top_left = 10
			border_style.corner_radius_top_right = 10
			border_style.corner_radius_bottom_right = 10
			border_style.corner_radius_bottom_left = 10
			_selection_border.add_theme_stylebox_override("panel", border_style)


## Toggle selection state (called on click)
func toggle_selection() -> void:
	if is_selectable:
		is_selected = not is_selected


## Set selection state directly
func set_selected(selected: bool) -> void:
	is_selected = selected


## Clear selection
func clear_selection() -> void:
	is_selected = false


## Handle mouse click events
func _gui_input(event: InputEvent) -> void:
	if not is_selectable:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Toggle selection and emit signal
			toggle_selection()
			card_clicked.emit(card_data)
			# Accept the event to prevent propagation
			accept_event()


## Get the current card data
func get_card_data() -> CardData:
	return card_data


## Check if this display has valid card data
func has_card() -> bool:
	return card_data != null