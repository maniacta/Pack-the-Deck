class_name ShopConfig
extends Resource

## 商店配置
## 包含商品列表、刷新费用和免费刷新次数

## 商店中显示的商品列表
@export var items: Array[ShopItem] = []

## 刷新商店所需的金币
@export var refresh_cost: int = 5

## 最大免费刷新次数
@export var max_free_refreshes: int = 1

## 商店物品数量
@export var item_count: int = 4

## 已使用的刷新次数
var _refresh_count: int = 0

## 获取剩余免费刷新次数
func get_remaining_free_refreshes() -> int:
	return max(0, max_free_refreshes - _refresh_count)


## 获取刷新费用（免费次数用完后收费）
func get_refresh_cost() -> int:
	if _refresh_count < max_free_refreshes:
		return 0
	return refresh_cost


## 增加刷新计数
func increment_refresh() -> void:
	_refresh_count += 1


## 检查是否还有可购买的物品
func has_available_items() -> bool:
	for item: ShopItem in items:
		if not item.is_sold:
			return true
	return false


## 获取所有未售出的物品
func get_available_items() -> Array[ShopItem]:
	var available: Array[ShopItem] = []
	for item: ShopItem in items:
		if not item.is_sold:
			available.append(item)
	return available


## 重置刷新计数
func reset_refreshes() -> void:
	_refresh_count = 0
