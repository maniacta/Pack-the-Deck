class_name BackpackPanel
extends Control

## 背包面板 - 显示 5×4 装备网格和库存列表
## 支持装备的放置、移除和详情查看

## 信号：装备放置请求
signal equipment_place_requested(equipment: EquipmentData, position: Vector2i)

## 信号：装备移除请求
signal equipment_remove_requested(equipment: EquipmentData)

## 信号：面板关闭
signal panel_closed()

## 常量：网格尺寸
const GRID_COLS: int = 5
const GRID_ROWS: int = 4
const CELL_SIZE: int = 56
const CELL_GAP: int = 4

## 装备管理器引用
var equipment_manager: EquipmentManager = null:
	set(value):
		if equipment_manager:
			_disconnect_manager_signals()
		equipment_manager = value
		if equipment_manager:
			_connect_manager_signals()
			_refresh_grid()
			_refresh_inventory()

## 当前选中的库存物品（用于放置）
var _selected_inventory_item: EquipmentData = null

## 当前选中的已装备物品（用于查看详情）
var _selected_equipped_item: EquipmentData = null

## 网格单元格节点引用
var _grid_cells: Array[Panel] = []
var _grid_labels: Array[Label] = []

## 库存物品节点引用
var _inventory_item_nodes: Array[Control] = []

# ============================================================================
# UI 节点引用
# ============================================================================

@onready var _title_label: Label = $PanelContainer/MainVBox/TitleBar/TitleLabel
@onready var _close_button: Button = $PanelContainer/MainVBox/TitleBar/CloseButton
@onready var _grid_container: GridContainer = $PanelContainer/MainVBox/ContentHBox/GridArea/GridScroll/GridContainer
@onready var _inventory_container: VBoxContainer = $PanelContainer/MainVBox/ContentHBox/InventoryArea/InventoryScroll/InventoryContainer
@onready var _detail_panel: PanelContainer = $PanelContainer/MainVBox/DetailArea
@onready var _detail_name_label: Label = $PanelContainer/MainVBox/DetailArea/DetailVBox/DetailNameLabel
@onready var _detail_desc_label: Label = $PanelContainer/MainVBox/DetailArea/DetailVBox/DetailDescLabel
@onready var _detail_category_label: Label = $PanelContainer/MainVBox/DetailArea/DetailVBox/DetailCategoryLabel
@onready var _detail_shape_label: Label = $PanelContainer/MainVBox/DetailArea/DetailVBox/DetailShapeLabel
@onready var _detail_remove_button: Button = $PanelContainer/MainVBox/DetailArea/DetailVBox/DetailRemoveButton
@onready var _gold_label: Label = $PanelContainer/MainVBox/TitleBar/GoldLabel
@onready var _status_label: Label = $PanelContainer/MainVBox/StatusBar/StatusLabel

# ============================================================================
# 颜色常量
# ============================================================================

const COLOR_GRID_EMPTY: Color = Color(0.15, 0.15, 0.22, 1)
const COLOR_GRID_OCCUPIED: Color = Color(0.18, 0.25, 0.35, 1)
const COLOR_GRID_HOVER: Color = Color(0.22, 0.3, 0.42, 1)
const COLOR_GRID_CONFLICT: Color = Color(0.4, 0.15, 0.15, 1)
const COLOR_GRID_INVALID: Color = Color(0.25, 0.1, 0.1, 1)

const COLOR_CATEGORY_OPTICAL: Color = Color(0.3, 0.6, 0.9, 1)
const COLOR_CATEGORY_MECHANICAL: Color = Color(0.8, 0.5, 0.3, 1)
const COLOR_CATEGORY_MAGICAL: Color = Color(0.6, 0.3, 0.8, 1)
const COLOR_CATEGORY_GENERIC: Color = Color(0.5, 0.5, 0.5, 1)

const COLOR_SELECTED_ITEM: Color = Color(1, 0.843, 0, 1)
const COLOR_INVENTORY_ITEM: Color = Color(0.7, 0.7, 0.7, 1)

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_detail_remove_button.pressed.connect(_on_remove_equipment_pressed)
	_detail_panel.visible = false
	_hide_detail()
	_create_grid_cells()


## 创建 5×4 网格单元格
func _create_grid_cells() -> void:
	for child: Node in _grid_container.get_children():
		child.queue_free()
	_grid_cells.clear()
	_grid_labels.clear()
	
	for y in range(GRID_ROWS):
		for x in range(GRID_COLS):
			var cell_panel: Panel = Panel.new()
			cell_panel.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			cell_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = COLOR_GRID_EMPTY
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.25, 0.25, 0.35, 1)
			style.corner_radius_top_left = 4
			style.corner_radius_top_right = 4
			style.corner_radius_bottom_right = 4
			style.corner_radius_bottom_left = 4
			cell_panel.add_theme_stylebox_override("panel", style)
			
			var label: Label = Label.new()
			label.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
			label.add_theme_font_size_override("font_size", 9)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			
			cell_panel.add_child(label)
			_grid_container.add_child(cell_panel)
			
			_grid_cells.append(cell_panel)
			_grid_labels.append(label)
			
			# 添加点击检测
			var pos := Vector2i(x, y)
			cell_panel.gui_input.connect(_on_grid_cell_input.bind(pos))


## 打开面板
func open_panel(gold: int = 0, stage_manager: StageManager = null) -> void:
	visible = true
	
	# 更新金币显示
	_gold_label.text = "金币: %d" % gold
	
	# 刷新显示
	_refresh_grid()
	_refresh_inventory()
	_hide_detail()
	_selected_inventory_item = null
	
	_status_label.text = "点击库存物品选择，再点击网格放置"


## 关闭面板
func close_panel() -> void:
	visible = false
	_selected_inventory_item = null
	_selected_equipped_item = null
	panel_closed.emit()


## 设置状态栏消息
func set_status_message(message: String) -> void:
	_status_label.text = message


## 信号处理

func _on_close_pressed() -> void:
	close_panel()


func _on_remove_equipment_pressed() -> void:
	if _selected_equipped_item:
		equipment_remove_requested.emit(_selected_equipped_item)


## 连接装备管理器的信号
func _connect_manager_signals() -> void:
	if not equipment_manager:
		return
	if not equipment_manager.equipment_placed.is_connected(_on_equipment_placed):
		equipment_manager.equipment_placed.connect(_on_equipment_placed)
	if not equipment_manager.equipment_unequipped.is_connected(_on_equipment_unequipped):
		equipment_manager.equipment_unequipped.connect(_on_equipment_unequipped)
	if not equipment_manager.equipment_added.is_connected(_on_equipment_added):
		equipment_manager.equipment_added.connect(_on_equipment_added)


## 断开装备管理器的信号
func _disconnect_manager_signals() -> void:
	if not equipment_manager:
		return
	if equipment_manager.equipment_placed.is_connected(_on_equipment_placed):
		equipment_manager.equipment_placed.disconnect(_on_equipment_placed)
	if equipment_manager.equipment_unequipped.is_connected(_on_equipment_unequipped):
		equipment_manager.equipment_unequipped.disconnect(_on_equipment_unequipped)
	if equipment_manager.equipment_added.is_connected(_on_equipment_added):
		equipment_manager.equipment_added.disconnect(_on_equipment_added)


func _on_equipment_placed(_equipment: EquipmentData, _position: Vector2i) -> void:
	if visible:
		_refresh_grid()
		_refresh_inventory()
		_selected_inventory_item = null
		_status_label.text = "装备已放置: %s" % _equipment.display_name


func _on_equipment_unequipped(_equipment: EquipmentData) -> void:
	if visible:
		_refresh_grid()
		_refresh_inventory()
		if _selected_equipped_item == _equipment:
			_hide_detail()
		_status_label.text = "装备已卸下: %s" % _equipment.display_name


func _on_equipment_added(_equipment: EquipmentData) -> void:
	if visible:
		_refresh_inventory()
		_status_label.text = "获得新装备: %s" % _equipment.display_name


# ============================================================================
# 网格单元格交互
# ============================================================================

func _on_grid_cell_input(event: InputEvent, pos: Vector2i) -> void:
	if not equipment_manager:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 检查该位置是否已有装备
			var existing: EquipmentData = equipment_manager.get_equipment_at(pos)
			if existing:
				# 点击已占用的格子 -> 显示详情
				_show_equipment_detail(existing)
				_selected_inventory_item = null
			elif _selected_inventory_item:
				# 有选中的库存物品 -> 尝试放置
				equipment_place_requested.emit(_selected_inventory_item, pos)
			else:
				# 空格子，无选中物品 -> 隐藏详情
				_hide_detail()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键点击已占用的格子 -> 卸下装备
			var existing: EquipmentData = equipment_manager.get_equipment_at(pos)
			if existing:
				equipment_remove_requested.emit(existing)


# ============================================================================
# 网格刷新
# ============================================================================

## 刷新整个网格显示
func _refresh_grid() -> void:
	if not equipment_manager:
		return
	
	for i in range(_grid_cells.size()):
		var x: int = i % GRID_COLS
		var y: int = i / GRID_COLS
		var pos := Vector2i(x, y)
		var cell_panel: Panel = _grid_cells[i]
		var label: Label = _grid_labels[i]
		
		var style: StyleBoxFlat = cell_panel.get_theme_stylebox("panel").duplicate()
		var equipment: EquipmentData = equipment_manager.get_equipment_at(pos)
		
		if equipment:
			# 已占用
			style.bg_color = _get_category_color(equipment.category)
			label.text = _get_equipment_short_name(equipment)
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			# 空格子
			style.bg_color = COLOR_GRID_EMPTY
			label.text = ""
		
		cell_panel.add_theme_stylebox_override("panel", style)


## 刷新库存物品列表
func _refresh_inventory() -> void:
	if not equipment_manager:
		return
	
	# 清除现有库存物品节点
	for node: Control in _inventory_item_nodes:
		node.queue_free()
	_inventory_item_nodes.clear()
	
	# 获取库存列表
	var inventory: Array[EquipmentData] = equipment_manager.get_inventory()
	
	if inventory.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "库存为空"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		empty_label.add_theme_font_size_override("font_size", 14)
		_inventory_container.add_child(empty_label)
		_inventory_item_nodes.append(empty_label)
		return
	
	for equipment: EquipmentData in inventory:
		var item_row: HBoxContainer = _create_inventory_item_row(equipment)
		_inventory_container.add_child(item_row)
		_inventory_item_nodes.append(item_row)


func _create_inventory_item_row(equipment: EquipmentData) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	var name_label: Label = Label.new()
	name_label.text = equipment.display_name
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 设置选中状态的颜色
	if _selected_inventory_item == equipment:
		name_label.add_theme_color_override("font_color", COLOR_SELECTED_ITEM)
	else:
		name_label.add_theme_color_override("font_color", _get_category_color(equipment.category))
	
	row.add_child(name_label)
	
	# 形状标签
	var shape_label: Label = Label.new()
	shape_label.text = equipment.get_shape_display()
	shape_label.add_theme_font_size_override("font_size", 11)
	shape_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	shape_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(shape_label)
	
	# 点击事件
	row.gui_input.connect(_on_inventory_item_clicked.bind(equipment))
	
	return row


func _on_inventory_item_clicked(event: InputEvent, equipment: EquipmentData) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 切换选中
			if _selected_inventory_item == equipment:
				_selected_inventory_item = null
				_status_label.text = "已取消选择"
			else:
				_selected_inventory_item = equipment
				_status_label.text = "已选择: %s - 点击网格放置" % equipment.display_name
				_hide_detail()
			_refresh_inventory()
			_update_grid_highlights()


# ============================================================================
# 装备详情
# ============================================================================

func _show_equipment_detail(equipment: EquipmentData) -> void:
	_selected_equipped_item = equipment
	_detail_name_label.text = equipment.display_name
	_detail_desc_label.text = equipment.description if not equipment.description.is_empty() else "无描述"
	_detail_category_label.text = "类别: %s" % equipment.get_category_name()
	_detail_shape_label.text = "占格: %d 格 (%s)" % [equipment.get_cell_count(), equipment.get_shape_display()]
	
	_detail_name_label.add_theme_color_override("font_color", _get_category_color(equipment.category))
	_detail_panel.visible = true
	_detail_remove_button.visible = true


func _hide_detail() -> void:
	_selected_equipped_item = null
	_detail_panel.visible = false
	_detail_remove_button.visible = false


## 更新网格高亮（显示可放置位置）
func _update_grid_highlights() -> void:
	_refresh_grid()  # 清除高亮，恢复基础状态
	
	if not _selected_inventory_item or not equipment_manager:
		return
	
	# 高亮可放置的位置
	var equipment: EquipmentData = _selected_inventory_item
	for y in range(GRID_ROWS):
		for x in range(GRID_COLS):
			var pos := Vector2i(x, y)
			var i: int = y * GRID_COLS + x
			var cell: Panel = _grid_cells[i]
			var style: StyleBoxFlat = cell.get_theme_stylebox("panel").duplicate()
			
			# 检查是否可以在该位置放置
			if equipment_manager.get_equipment_at(pos) != null:
				# 已占用 - 不修改
				pass
			elif not equipment_manager.can_place(equipment, pos):
				# 不可放置（越界或冲突）
				style.bg_color = COLOR_GRID_INVALID
				cell.add_theme_stylebox_override("panel", style)
			else:
				# 可放置
				style.bg_color = COLOR_GRID_HOVER
				style.border_color = COLOR_SELECTED_ITEM
				cell.add_theme_stylebox_override("panel", style)


# ============================================================================
# 辅助方法
# ============================================================================

## 获取装备的简称（用于网格显示）
func _get_equipment_short_name(equipment: EquipmentData) -> String:
	var name: String = equipment.display_name
	if name.length() > 6:
		name = name.substr(0, 5) + "…"
	return name


## 根据类别获取显示颜色
func _get_category_color(category: EquipmentData.Category) -> Color:
	match category:
		EquipmentData.Category.OPTICAL:
			return COLOR_CATEGORY_OPTICAL
		EquipmentData.Category.MECHANICAL:
			return COLOR_CATEGORY_MECHANICAL
		EquipmentData.Category.MAGICAL:
			return COLOR_CATEGORY_MAGICAL
		EquipmentData.Category.GENERIC:
			return COLOR_CATEGORY_GENERIC
		_:
			return COLOR_CATEGORY_GENERIC
