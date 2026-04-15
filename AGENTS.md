# AGENTS.md - Pack the Deck

> 基于 Godot 4 + GDScript 的规则改写型 Roguelike 卡牌游戏

## 项目概述

**Pack the Deck** 是一款策略 Roguelike 游戏，玩家通过装备改写游戏规则。核心系统：
- **扑克牌型计分** - 标准扑克牌型排名（对子、顺子、同花等）
- **装备系统** - 修改游戏规则的道具（改变牌型要求、倍率等）
- **背包网格** - 5x4 格背包空间，支持空间放置机制

**灵感来源**：Balatro（扑克 Roguelike）+ Backpack Battles（背包乱斗）

---

## 构建/检查/测试命令

### 运行游戏
```bash
# 在 Godot 编辑器中打开项目（开发必需）
godot4 --editor .

# 从命令行运行游戏
godot4 .

# 运行特定场景进行测试
godot4 scenes/battle.tscn
```

### 运行测试
```bash
# GDUnit4 是推荐的测试插件
# 通过 Godot 编辑器运行所有测试：项目 > 工具 > GDUnit4 > 运行所有测试

# 运行指定测试目录
godot4 --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -c run -a res://tests/

# 运行单个测试文件
godot4 --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -c run -a res://tests/test_hand_classifier.gd
```

### 代码检查
```bash
# GDScript 没有外部 linter - 使用 Godot 编辑器的内置验证
# 在编辑器中打开脚本查看错误/警告

# 可选：GDScript 格式化工具（如已安装 gdformat）
gdformat scripts/
```

### 导出/构建
```bash
# 导出 Windows 版本（先配置导出模板）
godot4 --headless --export-release "Windows Desktop" build/game.exe

# 导出调试版本
godot4 --headless --export-debug "Windows Desktop" build/game_debug.exe
```

---

## 项目结构

```
Pack-the-Deck/
├── scenes/              # Godot 场景文件 (.tscn)
│   ├── main.tscn        # 主游戏场景
│   ├── battle.tscn      # 战斗阶段场景
│   ├── shop.tscn        # 商店阶段场景
│   └── inventory.tscn   # 背包/物品栏场景
├── scripts/             # GDScript 脚本文件 (.gd)
│   ├── autoload/        # 全局单例 (AutoLoad)
│   ├── card/            # 卡牌相关脚本
│   ├── equipment/       # 装备相关脚本
│   ├── systems/         # 核心游戏系统
│   └── ui/              # UI 组件脚本
├── resources/           # 数据资源 (.tres)
│   ├── cards/           # 卡牌定义
│   └── equipment/       # 装备定义
├── assets/              # 静态资源
│   ├── sprites/         # 图片和纹理
│   └── audio/           # 音效和音乐
├── addons/              # Godot 插件
│   └── gdUnit4/         # 测试框架
├── tests/               # 测试文件（镜像 scripts/ 结构）
└── memory-bank/         # 设计文档（不参与游戏运行）
```

---

## 代码风格指南

### GDScript 规范

遵循官方 [GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)。

#### 命名规范
```gdscript
# 类名：PascalCase
class_name HandClassifier
class_name CardData

# 函数：snake_case
func calculate_score(cards: Array) -> int:
func get_hand_type() -> HandType:

# 变量：snake_case
var current_score: int = 0
var max_hand_size: int = 8

# 常量：SCREAMING_SNAKE_CASE
const MAX_HAND_SIZE: int = 8
const BASE_PAIR_MULTIPLIER: float = 2.0

# 枚举：类型用 PascalCase，值用 SCREAMING_SNAKE
enum HandType {
    HIGH_CARD,
    ONE_PAIR,
    TWO_PAIR,
    THREE_OF_A_KIND,
    STRAIGHT,
    FLUSH,
    FULL_HOUSE,
    FOUR_OF_A_KIND,
    STRAIGHT_FLUSH,
    ROYAL_FLUSH
}

# 信号：过去式 snake_case
signal card_played(card: CardData)
signal hand_selected(cards: Array)
signal score_updated(new_score: int)
```

#### 类型注解（必须）
```gdscript
# 始终为函数参数和返回值添加类型注解
func evaluate_hand(cards: Array[CardData]) -> HandResult:
    var score: int = 0
    var hand_type: HandType = HandType.HIGH_CARD
    return HandResult.new(hand_type, score)

# 使用类型化数组
var hand: Array[CardData] = []
var equipment_slots: Array[EquipmentSlot] = []
```

#### 类结构顺序
```gdscript
# 1. class_name（如果定义全局类）
class_name CardData extends Resource

# 2. 信号
signal changed()

# 3. 枚举
enum Suit { SPADES, HEARTS, DIAMONDS, CLUBS }

# 4. 常量
const FACE_CARD_VALUE: int = 10

# 5. 导出变量
@export var card_name: String = ""
@export var suit: Suit = Suit.SPADES
@export var rank: int = 2

# 6. 公共变量
var is_selected: bool = false

# 7. 私有变量（前缀 _）
var _cached_value: int = -1

# 8. 虚函数（_ready, _process 等）
func _ready() -> void:
    pass

# 9. 公共函数
func get_value() -> int:
    pass

# 10. 私有函数
func _calculate_value() -> int:
    pass
```

---

## 导入风格

```gdscript
# 预加载常用场景和资源
const CardScene = preload("res://scenes/card.tscn")
const CardData = preload("res://scripts/card/card_data.gd")

# 使用类型推断配合预加载资源
@onready var hand_container: HBoxContainer = $HandContainer
@onready var score_label: Label = $UI/ScoreLabel

# 单例/autoload 直接通过名称引用
# GameManager 是一个 autoload
func get_current_stage() -> StageConfig:
    return GameManager.current_stage
```

---

## 架构模式

### 数据驱动设计
```gdscript
# 装备和卡牌定义为 Resource 文件 (.tres)
# 不要在脚本中硬编码

# equipment/fire_lens.tres 定义装备数据
# scripts/equipment/equipment_data.gd 定义数据结构
class_name EquipmentData extends Resource

@export var display_name: String
@export var description: String
@export var shape: Array[Vector2i]  # 占用的网格位置
@export var effect_type: EffectType
@export var effect_params: Dictionary
```

### 基于信号的通信
```gdscript
# 使用信号实现系统间解耦通信
# 在专用事件总线 autoload 中定义

# events.gd（autoload 单例）
extends Node

signal card_selected(card: CardData)
signal card_deselected(card: CardData)
signal hand_played(cards: Array[CardData])
signal score_changed(new_total: int)
signal turn_started()
signal turn_ended()

# 在其他脚本中使用
Events.score_changed.connect(_on_score_changed)
Events.score_changed.emit(150)
```

### 游戏流程状态机
```gdscript
# 游戏状态
enum GameState { TITLE, BATTLE, SHOP, INVENTORY, GAME_OVER, VICTORY }

var _current_state: GameState = GameState.TITLE

func change_state(new_state: GameState) -> void:
    _exit_state(_current_state)
    _current_state = new_state
    _enter_state(new_state)

func _enter_state(state: GameState) -> void:
    match state:
        GameState.BATTLE:
            _start_battle()
        GameState.SHOP:
            _open_shop()

func _exit_state(state: GameState) -> void:
    match state:
        GameState.BATTLE:
            _end_battle()
```

---

## 错误处理

```gdscript
# 使用 assert 进行开发时检查（发布版本会移除）
assert(cards.size() <= 5, "不能打出超过 5 张牌")

# 使用 push_error 处理运行时问题（记录日志但不崩溃）
if not card:
    push_error("卡牌数据为空")
    return

# 使用 push_warning 处理非关键问题
if score < 0:
    push_warning("检测到负分: %d" % score)

# 失败时提前返回默认值
func get_card_value(card: CardData) -> int:
    if not card:
        push_error("get_card_value 收到空卡牌")
        return 0
    return card.get_value()

# 在函数边界验证输入
func place_equipment(equipment: EquipmentData, slot: Vector2i) -> bool:
    if not equipment:
        push_error("装备为空")
        return false
    if not _is_valid_slot(slot):
        push_warning("无效槽位: %s" % slot)
        return false
    # ... 实际放置逻辑
    return true
```

---

## 测试规范

```gdscript
# 测试文件放在 tests/，镜像 scripts/ 的结构
# tests/card/test_card_data.gd 测试 scripts/card/card_data.gd

# 使用 GDUnit4 断言
func test_pair_detection() -> void:
    var cards := [
        CardData.new().setup(CardData.Rank.FIVE, CardData.Suit.SPADES),
        CardData.new().setup(CardData.Rank.FIVE, CardData.Suit.HEARTS)
    ]
    var result := HandClassifier.evaluate(cards)
    assert_int(result.hand_type).is_equal(HandType.ONE_PAIR)
    assert_int(result.multiplier).is_equal(2)

# 明确测试边界情况
func test_empty_hand_returns_high_card() -> void:
    var result := HandClassifier.evaluate([])
    assert_int(result.hand_type).is_equal(HandType.HIGH_CARD)

func test_ace_can_be_low_in_straight() -> void:
    var cards := _create_cards([Rank.ACE, Rank.TWO, Rank.THREE, Rank.FOUR, Rank.FIVE])
    var result := HandClassifier.evaluate(cards)
    assert_bool(result.is_straight).is_true()
```

---

## Git 规范

```bash
# Godot 项目 .gitignore 要点
.import/
*.import
export/
.mono/
.godot/

# 提交信息格式
type(scope): 简短描述

# 类型：feat, fix, refactor, test, docs, chore
# 示例：
feat(card): 添加同花顺检测
fix(backpack): 防止装备放置重叠
test(hand): 添加 A 作顺子低牌的边界测试
refactor(score): 提取倍率计算为独立函数
```

---

## 关键实现要点

1. **规则改写系统** - 装备可以改变扑克牌型检测规则。这是核心机制。修改 `HandClassifier` 以接受规则修改器。

2. **网格背包系统** - 装备有形状（1x1, 2x2, L形）。放置时验证网格边界和已占用槽位。

3. **数据资源** - 所有卡牌和装备应为 `.tres` 资源文件，便于无需修改代码即可编辑。

4. **无多人模式** - 仅单人游戏。优化单线程性能。

5. **MVP 范围** - 保持功能最小化。专注核心循环：出牌 → 计分 → 用装备改写规则。

---

## 重要提示：
- 写任何代码前必须完整阅读 memory-bank/@architecture.md（用于记录每个文件的作用）
- 写任何代码前必须完整阅读 memory-bank/@game-design-document.md
- 每完成一个重大功能或里程碑后，必须更新 memory-bank/@architecture.md 和 memory-bank/@progress.md（记录已完成步骤）
- 必须使用中文回答，代码中的注释/日志等信息使用中文

---

## 参考资料

- [Godot 4 文档](https://docs.godotengine.org/en/stable/)
- [GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [GDUnit4 测试框架](https://github.com/MikeSchulze/gdUnit4)