# 游戏场景设计开发文档

> **目标**：创建一个可运行的游戏场景，用于测试已完成的牌型判断和得分计算功能
> **范围**：战斗场景基础实现 + 基础 UI + 完整的出牌流程
> **依赖**：阶段一、二、三已完成的功能（卡牌数据、牌型判断、得分计算）
> **原则**：先实现核心交互流程，再逐步完善 UI 和细节

---

## 一、现状分析

### 已完成功能
- ✅ **卡牌数据系统**：CardData、Deck、DeckGenerator
- ✅ **牌型判断系统**：HandType、HandClassifier（10种牌型识别）
- ✅ **得分计算系统**：BlindType、ScoreCalculator、StageConfig
- ✅ **装备数据系统**：EquipmentData、EquipmentManager（基础数据结构）

### 当前问题
- ❌ **没有可运行的游戏场景**
- ❌ **只能通过测试脚本验证功能**
- ❌ **无法直观测试卡牌选择、牌型识别、得分显示的完整流程**

### 解决方案
创建一个**战斗场景原型**，包含：
1. 手牌显示与选择交互
2. 牌型识别与得分显示
3. 基础的游戏流程（出牌 → 得分 → 补牌）

---

## 二、场景架构设计

### 2.1 场景树结构

```
BattleScene (Control)
├── Background (ColorRect) - #1a1a2e 深色背景
│
├── InfoPanel (HBoxContainer) - 顶部信息栏
│   ├── StageLabel (Label) - 关卡名称
│   ├── TargetScoreLabel (Label) - 目标分数
│   ├── CurrentScoreLabel (Label) - 当前累计分数
│   ├── RemainingTurnsLabel (Label) - 剩余回合数
│   └── BlindTypeLabel (Label) - 盲注类型
│
├── GameArea (VBoxContainer) - 中央游戏区域
│   ├── PlayZone (Panel) - 出牌区域
│   │   ├── SelectedCardsContainer (HBoxContainer) - 已选卡牌
│   │   ├── HandTypeLabel (Label) - 识别出的牌型
│   │   └── ScorePreviewLabel (Label) - 预计得分
│   │
│   └── HandArea (ScrollContainer) - 手牌区域
│       ├── HandContainer (HBoxContainer) - 手牌容器
│       │   ├── [CardDisplay节点 - 动态生成]
│       │   └── ...
│
├── ActionBar (HBoxContainer) - 底部操作栏
│   ├── PlayButton (Button) - 出牌按钮
│   ├── DiscardButton (Button) - 弃牌按钮
│   ├── ResetButton (Button) - 重置关卡按钮
│   └── StatusLabel (Label) - 状态提示
│
└── BattleController (Node) - 场景逻辑控制器（脚本）
```

### 2.2 卡牌显示节点结构

```
CardDisplay (Control) - 单张卡牌显示
├── CardBackground (Panel) - 卡牌背景
│   ├── ColorRect - 花色颜色（红心/方块=红色，黑桃/梅花=黑色）
│
├── RankLabel (Label) - 牌面值（左上角）
│   - 字体大小：24px
│   - 位置：相对左上角 (8, 8)
│
├── SuitLabel (Label) - 花色符号（中央）
│   - 字体大小：32px
│   - 位置：卡牌中央
│   - 文字：♠ ♥ ♦ ♣
│
├── SelectionBorder (Panel) - 选中状态边框
│   - 默认隐藏
│   - 选中时显示黄色边框（#ffd700）
│
└── HoverEffect (动画) - 悬停效果（后续迭代）
```

---

## 三、UI 设计规范

### 3.1 尺寸规范

| 元素 | 尺寸 | 说明 |
|------|------|------|
| **卡牌** | 100×140 px | 标准卡牌尺寸 |
| **卡牌间距** | 10 px | 手牌排列间距 |
| **手牌区域高度** | 180 px | 可容纳 8 张牌 |
| **出牌区域高度** | 200 px | 显示选中牌和牌型信息 |
| **信息栏高度** | 60 px | 顶部固定高度 |
| **操作栏高度** | 80 px | 底部固定高度 |

### 3.2 颜色规范

| 元素 | 颜色 | 用途 |
|------|------|------|
| **背景** | #1a1a2e | 深色游戏背景 |
| **卡牌背景（黑桃/梅花）** | #2d2d44 | 黑色花色卡牌 |
| **卡牌背景（红心/方块）** | #442d2d | 红色花色卡牌 |
| **选中边框** | #ffd700 | 金色高亮 |
| **文字（黑桃/梅花）** | #ffffff | 白色文字 |
| **文字（红心/方块）** | #ff6b6b | 红色文字 |
| **成功色** | #4ade80 | 胜利/过关显示 |
| **失败色** | #f87171 | 失败/警告显示 |
| **按钮背景** | #3b82f6 | 蓝色按钮 |
| **按钮禁用** | #6b7280 | 灰色禁用状态 |

### 3.3 字体规范

| 元素 | 字体大小 | 字体样式 |
|------|---------|---------|
| **牌面值** | 24 px | 粗体 |
| **花色符号** | 32 px | 普通 |
| **牌型名称** | 20 px | 粗体 |
| **分数数字** | 28 px | 粗体（突出） |
| **信息栏文字** | 16 px | 普通 |
| **按钮文字** | 18 px | 普通 |

---

## 四、核心脚本设计

### 4.1 BattleController.gd - 场景控制器

**职责**：管理战斗场景的完整游戏流程

**主要属性**：
```gdscript
extends Node

# 关卡配置
var stage_config: StageConfig

# 游戏状态
var deck: Deck
var hand: Array[CardData] = []  # 当前手牌（最多8张）
var selected_cards: Array[CardData] = []  # 选中的卡牌（最多5张）
var current_score: int = 0  # 累计分数
var remaining_turns: int = 0  # 剩余回合数

# UI 节点引用
@onready var hand_container: HBoxContainer
@onready var selected_cards_container: HBoxContainer
@onready var hand_type_label: Label
@onready var score_preview_label: Label
@onready var play_button: Button
@onready var discard_button: Button
```

**主要方法**：
```gdscript
func _ready() -> void:
    # 初始化场景
    setup_stage(stage_config)
    
func setup_stage(config: StageConfig) -> void:
    # 根据关卡配置初始化游戏状态
    stage_config = config
    current_score = 0
    remaining_turns = config.max_turns
    deck = Deck.new()
    deck.shuffle()
    draw_initial_hand()

func draw_initial_hand() -> void:
    # 抽取初始手牌（8张）
    hand = deck.draw_cards(8)
    update_hand_display()

func draw_cards(count: int) -> void:
    # 补充手牌
    var new_cards = deck.draw_cards(count)
    hand.append_array(new_cards)
    update_hand_display()

func toggle_card_selection(card: CardData) -> void:
    # 切换卡牌选中状态
    if card in selected_cards:
        selected_cards.erase(card)
    elif selected_cards.size() < 5:
        selected_cards.append(card)
    update_selection_display()

func play_cards() -> void:
    # 出牌流程
    if selected_cards.is_empty():
        return
    
    # 识别牌型
    var hand_result = HandClassifier.evaluate(selected_cards)
    
    # 计算得分
    var score = ScoreCalculator.calculate_score(hand_result, stage_config.blind_type)
    
    # 更新状态
    current_score += score
    remaining_turns -= 1
    
    # 移除已出牌
    for card in selected_cards:
        hand.erase(card)
        deck.discard(card)
    selected_cards.clear()
    
    # 补充手牌
    draw_cards(selected_cards.size())
    
    # 检查过关
    check_victory()

func check_victory() -> void:
    # 过关判定
    if current_score >= stage_config.get_target_score():
        show_victory()
    elif remaining_turns <= 0:
        show_defeat()

func discard_cards() -> void:
    # 弃牌流程（可选功能）
    for card in selected_cards:
        hand.erase(card)
        deck.discard(card)
    selected_cards.clear()
    draw_cards(selected_cards.size())

func reset_stage() -> void:
    # 重置当前关卡
    setup_stage(stage_config)
```

### 4.2 CardDisplay.gd - 卡牌显示组件

**职责**：显示单张卡牌并处理选择交互

**主要属性**：
```gdscript
extends Control

class_name CardDisplay

# 卡牌数据
var card_data: CardData

# 状态
var is_selected: bool = false

# UI 节点
@onready var rank_label: Label
@onready var suit_label: Label
@onready var selection_border: Panel
@onready var card_background: Panel

# 信号
signal card_clicked(card: CardData)
```

**主要方法**：
```gdscript
func setup(data: CardData) -> void:
    # 设置卡牌数据并更新显示
    card_data = data
    update_display()

func update_display() -> void:
    # 更新卡牌显示
    rank_label.text = card_data.get_rank_display()
    suit_label.text = card_data.get_suit_display()
    
    # 设置颜色
    var color = card_data.get_suit_color()
    rank_label.add_theme_color_override("font_color", color)
    suit_label.add_theme_color_override("font_color", color)

func toggle_selection() -> void:
    # 切换选中状态
    is_selected = not is_selected
    selection_border.visible = is_selected
    if is_selected:
        selection_border.modulate = Color("#ffd700")

func _gui_input(event: InputEvent) -> void:
    # 处理点击事件
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            card_clicked.emit(card_data)
```

---

## 五、实现步骤（小步迭代）

### 步骤 1：创建场景文件结构

**目标**：搭建基础场景框架

**指令**：
1. 创建 `scenes/battle.tscn` 场景文件
2. 创建基础节点结构：
   - BattleScene（根节点，Control）
   - Background（ColorRect）
   - InfoPanel（HBoxContainer）
   - GameArea（VBoxContainer）
   - ActionBar（HBoxContainer）
3. 创建 `scripts/battle_controller.gd` 脚本
4. 将脚本绑定到 BattleController 节点

**验证**：
- [ ] 场景可在编辑器中打开
- [ ] 节点结构正确
- [ ] 脚本成功绑定

---

### 步骤 2：创建卡牌显示组件

**目标**：实现单张卡牌的可视化显示

**指令**：
1. 创建 `scenes/card_display.tscn` 场景文件
2. 创建节点结构：
   - CardDisplay（根节点，Control，100×140）
   - CardBackground（Panel）
   - RankLabel（Label，左上角）
   - SuitLabel（Label，中央）
   - SelectionBorder（Panel，默认隐藏）
3. 创建 `scripts/ui/card_display.gd` 脚本
4. 实现以下方法：
   - `setup(data: CardData)` - 设置卡牌数据
   - `update_display()` - 更新显示内容
   - `toggle_selection()` - 切换选中状态
5. 实现点击交互（信号 card_clicked）

**验证**：
- [ ] 卡牌能正确显示牌面值（如 "A", "K", "5"）
- [ ] 卡牌能正确显示花色符号（♠ ♥ ♦ ♣）
- [ ] 红心/方块显示红色，黑桃/梅花显示黑色
- [ ] 点击卡牌能触发信号

---

### 步骤 3：实现手牌显示与更新

**目标**：显示 8 张手牌并支持动态更新

**指令**：
1. 在 BattleController 中实现手牌管理：
   - `hand: Array[CardData]` - 手牌数组
   - `draw_initial_hand()` - 抽取初始手牌
   - `update_hand_display()` - 更新手牌显示
2. 实现手牌容器管理：
   - 清空 HandContainer 的所有子节点
   - 为每张手牌创建 CardDisplay 实例
   - 设置点击事件监听
3. 实现卡牌选择逻辑：
   - `selected_cards: Array[CardData]` - 选中卡牌数组
   - `toggle_card_selection(card)` - 切换选中状态
   - 最多选择 5 张

**验证**：
- [ ] 初始显示 8 张手牌
- [ ] 点击卡牌能切换选中状态
- [ ] 选中卡牌显示黄色边框
- [ ] 最多只能选 5 张牌
- [ ] 点击已选中的牌能取消选中

---

### 步骤 4：实现出牌区域显示

**目标**：显示选中的卡牌和预计得分

**指令**：
1. 创建出牌区域节点：
   - SelectedCardsContainer（HBoxContainer）
   - HandTypeLabel（Label）
   - ScorePreviewLabel（Label）
2. 实现 `update_selection_display()`：
   - 清空 SelectedCardsContainer
   - 显示选中的卡牌副本（不交互）
   - 显示识别出的牌型名称
   - 显示预计得分
3. 牌型识别和得分计算：
   - 使用 HandClassifier.evaluate(selected_cards)
   - 使用 ScoreCalculator.calculate_score()

**验证**：
- [ ] 选中的牌正确显示在出牌区
- [ ] 显示正确的牌型名称（如 "对子", "顺子"）
- [ ] 显示正确的预计得分
- [ ] 未选牌时显示提示文字

---

### 步骤 5：实现信息栏显示

**目标**：显示关卡信息和实时状态

**指令**：
1. 创建信息栏节点：
   - StageLabel（关卡名称）
   - TargetScoreLabel（目标分数）
   - CurrentScoreLabel（当前累计分数）
   - RemainingTurnsLabel（剩余回合数）
   - BlindTypeLabel（盲注类型）
2. 实现 `update_info_display()`：
   - 从 StageConfig 读取关卡信息
   - 实时更新分数和回合数
3. 实现关卡加载：
   - `setup_stage(config: StageConfig)` - 加载关卡配置
   - 默认加载 stage_1.tres

**验证**：
- [ ] 显示正确的关卡名称
- [ ] 显示正确的目标分数
- [ ] 出牌后分数实时更新
- [ ] 出牌后回合数实时更新
- [ ] 显示正确的盲注类型

---

### 步骤 6：实现出牌按钮与流程

**目标**：完成完整的出牌交互流程

**指令**：
1. 创建按钮节点：
   - PlayButton（出牌按钮）
   - DiscardButton（弃牌按钮）
   - ResetButton（重置按钮）
2. 实现按钮状态控制：
   - 未选牌时禁用 PlayButton
   - 选 1-5 张牌时启用 PlayButton
3. 实现 `play_cards()` 出牌流程：
   - 识别牌型
   - 计算得分
   - 更新累计分数
   - 扣减回合数
   - 移除已出牌
   - 补充手牌
   - 检查过关
4. 实现按钮响应：
   - 点击 PlayButton → 调用 play_cards()
   - 点击 ResetButton → 调用 reset_stage()

**验证**：
- [ ] 未选牌时出牌按钮禁用（灰色）
- [ ] 选牌后出牌按钮启用（蓝色）
- [ ] 点击出牌后正确执行流程
- [ ] 出牌后分数增加
- [ ] 出牌后回合数减少
- [ ] 出牌后手牌补充

---

### 步骤 7：实现过关与失败判定

**目标**：实现胜利/失败判定和提示

**指令**：
1. 实现 `check_victory()` 过关判定：
   - 累计分数 ≥ 目标分数 → 胜利
   - 回合用尽且未达标 → 失败
2. 实现 `show_victory()` 胜利提示：
   - 显示 "过关！" 文字（绿色）
   - 禁用所有按钮
   - 显示最终得分
3. 实现 `show_defeat()` 失败提示：
   - 显示 "失败！" 文字（红色）
   - 禁用出牌按钮，启用重置按钮
4. 实现 `reset_stage()` 重置功能：
   - 重置所有状态
   - 重新开始当前关卡

**验证**：
- [ ] 达到目标分数显示胜利提示
- [ ] 回合用尽未达标显示失败提示
- [ ] 重置按钮能重新开始关卡
- [ ] 重置后状态完全恢复初始

---

### 步骤 8：创建主场景入口

**目标**：修改主场景以进入战斗场景

**指令**：
1. 修改 `scenes/main.tscn`：
   - 添加一个按钮"开始测试"
   - 点击后加载 battle.tscn
2. 修改 `scripts/main.gd`：
   - 实现 `_on_start_button_pressed()`
   - 使用 `change_scene_to_file("res://scenes/battle.tscn")`
3. 配置 autoload（可选）：
   - 创建 `scripts/autoload/events.gd` - 全局事件总线
   - 配置为 Events 单例

**验证**：
- [ ] 运行主场景显示"开始测试"按钮
- [ ] 点击按钮进入战斗场景
- [ ] 战斗场景正确加载 stage_1.tres
- [ ] 可以完整游玩一个关卡

---

## 六、完整测试流程

### 6.1 基础功能测试

**测试步骤**：
1. 运行主场景，点击"开始测试"
2. 进入战斗场景，检查：
   - [ ] 显示 8 张手牌
   - [ ] 信息栏显示正确的关卡信息
   - [ ] 出牌按钮初始为禁用状态

3. 点击一张卡牌：
   - [ ] 卡牌显示选中边框
   - [ ] 出牌区显示该卡牌
   - [ ] 显示牌型名称（如"高牌"）
   - [ ] 显示预计得分
   - [ ] 出牌按钮变为启用状态

4. 点击出牌按钮：
   - [ ] 出牌区清空
   - [ ] 信息栏分数增加
   - [ ] 信息栏回合数减少
   - [ ] 手牌补充至 8 张

5. 选择 5 张相同的牌面值（如两个对子）：
   - [ ] 显示正确的牌型名称
   - [ ] 显示正确的得分计算

6. 连续出牌直到：
   - [ ] 达到目标分数 → 显示胜利
   - [ ] 回合用尽 → 显示失败

7. 点击重置按钮：
   - [ ] 所有状态恢复初始
   - [ ] 可以重新游玩

---

### 6.2 边界情况测试

| 测试场景 | 预期行为 |
|---------|---------|
| 牌组抽完 | 无法补充手牌，手牌数量减少 |
| 手牌为空 | 无法出牌，按钮禁用 |
| 选择超过 5 张 | 第 6 张点击无响应 |
| 未选牌点击出牌 | 按钮禁用，无响应 |
| 连续快速点击卡牌 | 状态正确切换 |
| 重置后再次出牌 | 状态完全恢复 |

---

## 七、后续迭代方向

完成基础场景后，按以下顺序迭代：

### 优先级 P0（必须）
1. **手牌管理器** - 系统化的手牌管理类（阶段四）
2. **回合管理器** - 完整的回合流程控制（阶段四）
3. **牌组循环** - 弃牌堆洗牌成为新牌组

### 优先级 P1（重要）
4. **装备显示** - 在场景中显示已装备物品
5. **背包面板** - 可展开的背包 UI
6. **装备效果触发** - 在出牌流程中触发装备效果

### 优先级 P2（优化）
7. **卡牌悬停效果** - 悬停时放大显示
8. **出牌动画** - 卡牌移动动画
9. **音效** - 出牌、得分、过关音效
10. **商店场景** - 完整的商店 UI

---

## 八、关键设计决策

### 8.1 本次设计决策

| 决策项 | 结论 |
|--------|------|
| **场景类型** | Control（2D UI 场景） |
| **卡牌尺寸** | 100×140 px（标准比例） |
| **手牌数量** | 8 张（初始） |
| **选牌上限** | 5 张（扑克规则） |
| **关卡加载** | 默认加载 stage_1.tres |
| **牌型显示** | 实时识别，无需等待出牌 |
| **得分显示** | 预计得分 + 累计得分 |
| **卡牌点击** | 单击切换选中，无确认步骤 |
| **UI 颜色** | 深色主题（Balatro 风格） |
| **字体** | 使用系统默认字体，暂不加载自定义字体 |

### 8.2 推迟决策（后续迭代）

| 决策项 | 暂不实现 |
|--------|---------|
| **卡牌拖拽** | 拖拽选牌（复杂交互） |
| **卡牌排序** | 手牌自动排序 |
| **卡牌动画** | 移动、翻转动画 |
| **装备背包** | 背包网格显示 |
| **商店界面** | 商店场景 |
| **多关卡流程** | 关卡切换 |
| **存档系统** | 游戏进度保存 |

---

## 九、实现验收标准

### 完成条件

必须通过以下所有测试才算完成：

#### UI 显示
- [ ] 场景正确加载和显示
- [ ] 8 张手牌正确排列
- [ ] 卡牌显示正确的牌面值和花色
- [ ] 红色花色和黑色花色颜色正确区分
- [ ] 信息栏显示正确的关卡信息

#### 交互功能
- [ ] 点击卡牌能切换选中状态
- [ ] 最多只能选 5 张牌
- [ ] 出牌按钮状态正确（禁用/启用）
- [ ] 点击出牌按钮执行完整流程

#### 游戏逻辑
- [ ] 牌型识别正确
- [ ] 得分计算正确
- [ ] 分数和回合实时更新
- [ ] 手牌补充正确
- [ ] 过关判定正确

#### 状态管理
- [ ] 胜利/失败提示正确显示
- [ ] 重置功能完全恢复状态
- [ ] 无阻断性 bug

---

## 十、参考资料

### Godot UI 开发参考
- [Godot UI 系统介绍](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [Control 节点指南](https://docs.godotengine.org/en/stable/classes/class_control.html)
- [Container 节点指南](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)

### 项目内部参考
- `scripts/card/card_data.gd` - 卡牌数据定义
- `scripts/systems/hand_classifier.gd` - 牌型识别器
- `scripts/systems/score_calculator.gd` - 得分计算器
- `resources/stages/stage_1.tres` - 测试关卡配置

---

**文档版本**: v1.0  
**创建日期**: 2026-04-09  
**适用范围**: 战斗场景原型开发  
**依赖阶段**: 阶段一、二、三已完成