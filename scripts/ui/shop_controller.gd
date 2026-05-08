class_name ShopController
extends Control

## 商店控制器 - 处理商店 UI 交互逻辑
## 管理物品展示、购买和刷新

## 信号：请求购买物品
signal purchase_requested(item: ShopItem)

## 信号：请求刷新商店
signal refresh_requested()

## 信号：商店关闭
signal shop_closed()

## 信号：继续下一关
signal continue_requested()

## 商店管理器引用
var shop_manager: ShopManager = null

## 关卡管理器引用
var stage_manager: StageManager = null

## 当前金币
var player_gold: int = 0

## 物品卡片节点引用
var _item_cards: Array[HBoxContainer] = []

# ============================================================================
# UI 节点引用
# ============================================================================

@onready var _title_label: Label = $PanelContainer/MainVBox/TitleBar/TitleLabel
@onready var _gold_label: Label = $PanelContainer/MainVBox/TitleBar/GoldLabel
@onready var _close_button: Button = $PanelContainer/MainVBox/TitleBar/CloseButton
@onready var _items_container: VBoxContainer = $PanelContainer/MainVBox/ItemsScroll/ItemsContainer
@onready var _refresh_button: Button = $PanelContainer/MainVBox/BottomBar/RefreshButton
@onready var _continue_button: Button = $PanelContainer/MainVBox/BottomBar/ContinueButton
@onready var _status_label: Label = $PanelContainer/MainVBox/BottomBar/StatusLabel

# ============================================================================
# 颜色常量
# ============================================================================

const COLOR_PRICE_OK: Color = Color(1, 0.843, 0, 1)
const COLOR_PRICE_NO: Color = Color(0.8, 0.3, 0.3, 1)
const COLOR_SOLD: Color = Color(0.4, 0.4, 0.4, 1)
const COLOR_BUY_BTN: Color = Color(0.231, 0.51, 0.965, 1)
const COLOR_BUY_BTN_DISABLED: Color = Color(0.42, 0.45, 0.5, 1)


# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_refresh_button.pressed.connect(_on_refresh_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)


## 打开商店
func open_shop(gold: int, manager: ShopManager, stage_mgr: StageManager) -> void:
	visible = true
	player_gold = gold
	shop_manager = manager
	stage_manager = stage_mgr
	
	_gold_label.text = "金币: %d" % player_gold
	_refresh_button.visible = true
	
	if shop_manager:
		shop_manager.open_shop()
	
	_refresh_display()
	_update_status()


## 关闭商店
func close_shop() -> void:
	visible = false
	if shop_manager:
		shop_manager.close_shop()
	shop_closed.emit()


# ============================================================================
# 信号处理
# ============================================================================

func _on_close_pressed() -> void:
	close_shop()


func _on_refresh_pressed() -> void:
	refresh_requested.emit()


func _on_continue_pressed() -> void:
	continue_requested.emit()


## 处理购买按钮点击
func _on_buy_item_pressed(item: ShopItem) -> void:
	purchase_requested.emit(item)


# ============================================================================
# 显示更新
# ============================================================================

## 刷新整个商店显示
func _refresh_display() -> void:
	if not shop_manager or not shop_manager.shop_config:
		return
	
	# 清除现有物品卡片
	for card: Control in _item_cards:
		card.queue_free()
	_item_cards.clear()
	
	# 创建物品卡片
	var items: Array[ShopItem] = shop_manager.shop_config.items
	for item: ShopItem in items:
		var card := _create_item_card(item)
		_items_container.add_child(card)
		_item_cards.append(card)
	
	# 更新刷新按钮
	_update_refresh_button()


## 创建单个物品卡片
func _create_item_card(item: ShopItem) -> HBoxContainer:
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	card.custom_minimum_size = Vector2(0, 70)
	
	# 装备图标/颜色标记
	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(50, 50)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = _get_category_color(item.equipment.category)
	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_right = 6
	icon_style.corner_radius_bottom_left = 6
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	
	var icon_label := Label.new()
	icon_label.text = item.equipment.display_name.substr(0, 2) if item.equipment.display_name.length() > 0 else "?"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_color_override("font_color", Color.WHITE)
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_panel.add_child(icon_label)
	card.add_child(icon_panel)
	
	# 装备信息区
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	
	var name_label := Label.new()
	name_label.text = item.equipment.display_name
	name_label.add_theme_font_size_override("font_size", 15)
	if item.is_sold:
		name_label.add_theme_color_override("font_color", COLOR_SOLD)
	else:
		name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(name_label)
	
	var desc_label := Label.new()
	desc_label.text = item.equipment.description if not item.equipment.description.is_empty() else "无描述"
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(desc_label)
	
	var meta_hbox := HBoxContainer.new()
	meta_hbox.add_theme_constant_override("separation", 10)
	
	var category_label := Label.new()
	category_label.text = item.equipment.get_category_name()
	category_label.add_theme_font_size_override("font_size", 10)
	category_label.add_theme_color_override("font_color", _get_category_color(item.equipment.category))
	meta_hbox.add_child(category_label)
	
	var shape_label := Label.new()
	shape_label.text = "占 %s 格" % item.equipment.get_shape_display()
	shape_label.add_theme_font_size_override("font_size", 10)
	shape_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	meta_hbox.add_child(shape_label)
	
	info_vbox.add_child(meta_hbox)
	card.add_child(info_vbox)
	
	# 价格与购买区
	var price_vbox := VBoxContainer.new()
	price_vbox.add_theme_constant_override("separation", 4)
	
	var price_label := Label.new()
	if item.is_sold:
		price_label.text = "已售出"
		price_label.add_theme_color_override("font_color", COLOR_SOLD)
	else:
		price_label.text = "%d 金币" % item.price
		if player_gold >= item.price:
			price_label.add_theme_color_override("font_color", COLOR_PRICE_OK)
		else:
			price_label.add_theme_color_override("font_color", COLOR_PRICE_NO)
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_vbox.add_child(price_label)
	
	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(90, 32)
	buy_button.text = "购买"
	buy_button.add_theme_font_size_override("font_size", 13)
	
	if item.is_sold:
		buy_button.disabled = true
		buy_button.text = "已售"
	elif item.price > player_gold:
		buy_button.disabled = true
	else:
		buy_button.disabled = false
	
	buy_button.pressed.connect(_on_buy_item_pressed.bind(item))
	
	price_vbox.add_child(buy_button)
	card.add_child(price_vbox)
	
	return card


## 更新刷新按钮状态
func _update_refresh_button() -> void:
	if not shop_manager or not shop_manager.shop_config:
		_refresh_button.disabled = true
		return
	
	var config: ShopConfig = shop_manager.shop_config
	var free_refreshes: int = config.get_remaining_free_refreshes()
	var cost: int = config.get_refresh_cost()
	
	if free_refreshes > 0:
		_refresh_button.text = "刷新 (免费 ×%d)" % free_refreshes
		_refresh_button.disabled = false
	elif player_gold >= cost:
		_refresh_button.text = "刷新 (%d 金币)" % cost
		_refresh_button.disabled = false
	else:
		_refresh_button.text = "刷新 (%d 金币)" % cost
		_refresh_button.disabled = true


## 更新状态栏
func _update_status() -> void:
	if shop_manager:
		_status_label.text = shop_manager.get_shop_summary()


## 更新购买后状态
func update_after_purchase() -> void:
	_gold_label.text = "金币: %d" % player_gold
	_refresh_display()
	_update_status()


## 更新刷新后状态
func update_after_refresh() -> void:
	_gold_label.text = "金币: %d" % player_gold
	_refresh_display()
	_update_status()


# ============================================================================
# 辅助方法
# ============================================================================

func _get_category_color(category: EquipmentData.Category) -> Color:
	match category:
		EquipmentData.Category.OPTICAL:
			return Color(0.3, 0.6, 0.9, 1)
		EquipmentData.Category.MECHANICAL:
			return Color(0.8, 0.5, 0.3, 1)
		EquipmentData.Category.MAGICAL:
			return Color(0.6, 0.3, 0.8, 1)
		EquipmentData.Category.GENERIC:
			return Color(0.5, 0.5, 0.5, 1)
		_:
			return Color(0.5, 0.5, 0.5, 1)


## 设置金币（从外部更新）
func set_gold(gold: int) -> void:
	player_gold = gold
	_gold_label.text = "金币: %d" % player_gold
	_refresh_display()
