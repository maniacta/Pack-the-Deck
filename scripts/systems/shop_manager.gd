class_name ShopManager
extends RefCounted

## 商店管理器 - 管理商店物品生成、刷新和购买流程
## 与 StageManager 集成处理金币和库存

## 信号：购买成功
signal item_purchased(item: ShopItem)

## 信号：商店已刷新
signal shop_refreshed(items: Array[ShopItem])

## 装备资源路径池（待购买装备列表）
const EQUIPMENT_POOL: Array[String] = [
	"res://resources/equipment/lucky_coin.tres",
	"res://resources/equipment/pair_booster.tres",
	"res://resources/equipment/perfect_lens.tres",
	"res://resources/equipment/reinforced_anvil.tres",
	"res://resources/equipment/flush_lens.tres",
	"res://resources/equipment/straight_doubler.tres",
	"res://resources/equipment/full_house_crown.tres",
	"res://resources/equipment/ace_pendant.tres",
	"res://resources/equipment/score_gem.tres",
	"res://resources/equipment/gold_ring.tres",
]

## 当前商店配置
var shop_config: ShopConfig = null

## 商店是否已打开
var is_open: bool = false

## 随机数生成器
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## 初始化商店管理器
func _init() -> void:
	_rng.randomize()


## 生成新商店
func generate_shop(item_count: int = 4, refresh_cost: int = 5, max_free_refreshes: int = 1) -> ShopConfig:
	shop_config = ShopConfig.new()
	shop_config.item_count = item_count
	shop_config.refresh_cost = refresh_cost
	shop_config.max_free_refreshes = max_free_refreshes
	
	_refresh_items()
	
	return shop_config


## 刷新商店物品（不处理金币，仅重新生成）
func perform_refresh() -> void:
	if not shop_config:
		return
	shop_config.increment_refresh()
	_refresh_items()
	shop_refreshed.emit(shop_config.items)


## 支付刷新费用并刷新
func pay_and_refresh(player_gold: int) -> int:
	if not shop_config:
		return player_gold
	
	var cost: int = shop_config.get_refresh_cost()
	if cost > player_gold:
		push_warning("金币不足，无法刷新商店（需要 %d，当前 %d）" % [cost, player_gold])
		return player_gold
	
	player_gold -= cost
	shop_config.increment_refresh()
	_refresh_items()
	shop_refreshed.emit(shop_config.items)
	
	return player_gold


## 购买物品
func purchase_item(item: ShopItem, player_gold: int, inventory: Array[EquipmentData]) -> int:
	if not item or item.is_sold:
		push_warning("物品已售出或无效")
		return player_gold
	
	if not item.can_purchase(player_gold):
		push_warning("金币不足或物品不可购买")
		return player_gold
	
	# 扣除金币
	player_gold -= item.price
	
	# 标记为已售出
	item.mark_as_sold()
	
	# 添加到库存
	inventory.append(item.equipment)
	
	# 发出购买成功信号
	item_purchased.emit(item)
	
	return player_gold


## 从装备池中随机选择物品
func _refresh_items() -> void:
	shop_config.items.clear()
	
	var selected_equipment: Array[EquipmentData] = _select_random_equipment(shop_config.item_count)
	
	for eq: EquipmentData in selected_equipment:
		var item := ShopItem.new()
		item.equipment = eq
		item.price = _calculate_price(eq)
		shop_config.items.append(item)


## 从装备池中随机选择装备
func _select_random_equipment(count: int) -> Array[EquipmentData]:
	var available: Array[EquipmentData] = []
	
	for path: String in EQUIPMENT_POOL:
		var eq: EquipmentData = load(path) as EquipmentData
		if eq:
			available.append(eq)
	
	var selected: Array[EquipmentData] = []
	var pool := available.duplicate()
	
	for _i in range(min(count, pool.size())):
		if pool.is_empty():
			break
		
		var index: int = _rng.randi_range(0, pool.size() - 1)
		selected.append(pool[index])
		pool.remove_at(index)
	
	return selected


## 根据装备属性计算价格
func _calculate_price(equipment: EquipmentData) -> int:
	var base_price: int = 10
	
	# 格数越多越贵
	base_price += equipment.get_cell_count() * 5
	
	# 根据类别调整
	match equipment.category:
		EquipmentData.Category.OPTICAL:
			base_price += 5
		EquipmentData.Category.MECHANICAL:
			base_price += 8
		EquipmentData.Category.MAGICAL:
			base_price += 10
		EquipmentData.Category.GENERIC:
			base_price += 3
	
	# 根据参数调整
	if equipment.has_param("straight_min_cards"):
		base_price += 15
	if equipment.has_param("multiplier_bonus"):
		base_price += int(equipment.get_param("multiplier_bonus", 1.0) * 10)
	if equipment.has_param("score_bonus"):
		base_price += equipment.get_param("score_bonus", 0) / 2
	if equipment.has_param("gold_per_turn"):
		base_price += equipment.get_param("gold_per_turn", 0) * 8
	
	return base_price


## 检查商店是否可用（有未售出物品且未关闭）
func is_shop_available() -> bool:
	return is_open and shop_config and shop_config.has_available_items()


## 打开商店
func open_shop() -> void:
	is_open = true


## 关闭商店
func close_shop() -> void:
	is_open = false


## 获取商店摘要信息
func get_shop_summary() -> String:
	if not shop_config:
		return "商店未初始化"
	
	var available: int = shop_config.get_available_items().size()
	var total: int = shop_config.items.size()
	var refresh_text: String = "免费" if shop_config.get_remaining_free_refreshes() > 0 else ("%d 金币" % shop_config.refresh_cost)
	
	return "商品: %d/%d | 刷新: %s (剩余免费 %d 次)" % [
		available, total, refresh_text, shop_config.get_remaining_free_refreshes()
	]
