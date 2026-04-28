class_name ShopItem
extends Resource

## 商店中的单个商品
## 包含装备引用、价格和购买状态

## 商品关联的装备数据
@export var equipment: EquipmentData = null:
	set(value):
		if equipment != value:
			equipment = value
			changed.emit()

## 商品价格（金币）
@export var price: int = 0:
	set(value):
		if price != value:
			price = value
			changed.emit()

## 是否已售出
@export var is_sold: bool = false:
	set(value):
		if is_sold != value:
			is_sold = value
			changed.emit()

## 显示名称（简短）
var display_name: String:
	get:
		return equipment.display_name if equipment else "空"


## 获取商品描述
func get_description() -> String:
	if not equipment:
		return "无商品"
	return equipment.description


## 标记为已售出
func mark_as_sold() -> void:
	is_sold = true


## 检查是否可购买
func can_purchase(player_gold: int) -> bool:
	return not is_sold and player_gold >= price
