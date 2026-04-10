# 架构文档

> 记录项目中每个文件的作用和职责

---

## 项目结构

```
Pack-the-Deck/
├── project.godot           # Godot 项目配置文件
├── icon.svg                # 项目图标
├── scenes/                 # 场景文件 (.tscn)
│   └── main.tscn           # 主场景入口
├── scripts/                # GDScript 脚本文件
│   ├── main.gd             # 主场景脚本，游戏入口
│   ├── autoload/           # 全局单例脚本
│   ├── card/               # 卡牌相关脚本
│   ├── equipment/          # 装备相关脚本
│   ├── systems/            # 核心游戏系统
│   └── ui/                 # UI 组件脚本
├── resources/              # 数据资源文件
│   ├── cards/              # 卡牌数据资源
│   └── equipment/          # 装备数据资源
├── assets/                 # 静态资源
│   ├── sprites/            # 图片和纹理
│   └── audio/              # 音效和音乐
├── addons/                 # Godot 插件
├── tests/                  # 测试文件
└── memory-bank/            # 设计文档（不参与游戏运行）
```

---

## 核心脚本文件

### 卡牌系统 (scripts/card/)

#### card_data.gd
**类型**: `class_name CardData extends Resource`

**职责**: 定义单张扑克牌的数据结构

**主要属性**:
- `suit: Suit` - 花色（黑桃、红心、方块、梅花）
- `rank: Rank` - 牌面值（2-14，其中 14=A）
- `_cached_base_score: int` - 缓存的基础分数

**主要方法**:
- `get_base_score() -> int` - 获取基础分数（数字牌=面值，J/Q/K=10，A=11）
- `get_rank_display() -> String` - 获取牌面显示文本（如 "A", "K", "5"）
- `get_suit_display() -> String` - 获取花色符号（如 "♠", "♥"）
- `get_suit_color() -> Color` - 获取花色颜色（红/黑）
- `get_id() -> String` - 获取唯一标识符
- `sort_by_rank_desc(cards) -> Array[CardData]` - 静态方法，按牌面值降序排序

**枚举**:
- `Suit` - SPADES, HEARTS, DIAMONDS, CLUBS
- `Rank` - TWO(2) 到 ACE(14)

---

#### deck.gd
**类型**: `class_name Deck extends RefCounted`

**职责**: 管理一副 52 张标准扑克牌，提供洗牌和抽牌功能

**主要属性**:
- `_cards: Array[CardData]` - 牌组中的卡牌
- `_discarded: Array[CardData]` - 弃牌堆
- `_rng: RandomNumberGenerator` - 随机数生成器

**主要方法**:
- `shuffle()` - 洗牌
- `draw_card() -> CardData` - 抽一张牌
- `draw_cards(count: int) -> Array[CardData]` - 抽多张牌
- `discard(card: CardData)` - 弃牌
- `reset()` - 重置牌组

---

#### deck_generator.gd
**类型**: `class_name DeckGenerator extends RefCounted`

**职责**: 工具类，用于生成标准 52 张牌的资源文件

**主要方法**:
- `generate_all_cards() -> Array[CardData]` - 生成所有卡牌并保存为资源文件
- `load_all_cards() -> Array[CardData]` - 加载所有卡牌资源

---

#### generate_cards_editor.gd
**类型**: `extends EditorScript`

**职责**: 编辑器脚本，在 Godot 编辑器中运行以生成卡牌资源

---

### 装备系统 (scripts/equipment/)

#### equipment_data.gd
**类型**: `class_name EquipmentData extends Resource`

**职责**: 定义装备的数据结构，包括形状、效果和分类

**主要属性**:
- `display_name: String` - 装备名称
- `description: String` - 装备描述
- `category: Category` - 装备分类（光学类、机械类、魔法类、通用）
- `effect_type: EffectType` - 效果类型（规则改写、结构触发、资源流、分数修改）
- `trigger_timing: TriggerTiming` - 触发时机
- `shape: Array[Vector2i]` - 占用形状（相对坐标数组）
- `effect_params: Dictionary` - 效果参数
- `priority: int` - 规则叠加优先级

**主要方法**:
- `get_cell_count() -> int` - 获取占用格数
- `get_bounds() -> Vector2i` - 获取边界框大小
- `get_absolute_positions(anchor: Vector2i) -> Array[Vector2i]` - 获取绝对位置
- `conflicts_with(other: EquipmentData) -> bool` - 检查是否与另一装备冲突

**枚举**:
- `Category` - OPTICAL, MECHANICAL, MAGICAL, GENERIC
- `EffectType` - RULE_MODIFY, STRUCTURE, RESOURCE, SCORE_MODIFY
- `TriggerTiming` - ON_TURN_START, ON_TURN_END, ON_PLAY, ON_SCORE, ON_EQUIP, ON_ADJACENT

---

#### equipment_manager.gd
**类型**: `class_name EquipmentManager extends RefCounted`

**职责**: 管理玩家的装备库存和背包放置

**主要属性**:
- `_inventory: Array[EquipmentData]` - 未装备的物品
- `_grid: Dictionary` - 背包网格（位置 -> 装备）
- `_equipment_positions: Dictionary` - 装备位置映射

**主要方法**:
- `add_to_inventory(equipment)` - 添加到库存
- `can_place(equipment, anchor) -> bool` - 检查是否可放置
- `place_equipment(equipment, anchor) -> bool` - 放置装备
- `unequip(equipment) -> bool` - 卸下装备
- `get_adjacent_equipment(pos) -> Array[EquipmentData]` - 获取相邻装备

**常量**:
- `GRID_WIDTH: int = 5` - 背包宽度
- `GRID_HEIGHT: int = 4` - 背包高度

---

### 测试文件 (tests/)

#### test_card_data.gd
**类型**: `class_name TestCardData extends RefCounted`

**职责**: CardData 和 Deck 类的测试用例

**主要方法**:
- `run_all_tests() -> bool` - 运行所有测试

---

## 资源文件

### 测试装备 (resources/equipment/)

#### lucky_coin.tres
**名称**: Lucky Coin（幸运硬币）
**分类**: GENERIC
**效果**: 每回合开始 +1 金币
**形状**: 1×1

#### perfect_lens.tres
**名称**: Perfect Lens（完美镜片）
**分类**: OPTICAL
**效果**: 顺子只需 4 张牌（规则改写）
**形状**: 1×1

#### reinforced_anvil.tres
**名称**: Reinforced Anvil（强化铁砧）
**分类**: MECHANICAL
**效果**: 与相邻装备产生联动
**形状**: 2×2

---

## 设计决策

### 规则改写实现方式
采用**规则栈叠加**方式：每个装备是一个规则层，按优先级依次应用。后获得的装备优先生效（可覆盖之前的规则）。

### 装备冲突规则
MVP 阶段：同类装备不能同时装备。

### 牌组规模
标准 52 张扑克牌，装备效果可能改变牌组（动态管理）。

---

### 牌型判断系统 (scripts/systems/)

#### hand_type.gd
**类型**: `class_name HandType extends RefCounted`

**职责**: 定义扑克牌型枚举和牌型结果类

**主要枚举**:
- `Type` - 牌型类型（HIGH_CARD, ONE_PAIR, TWO_PAIR, THREE_OF_A_KIND, STRAIGHT, FLUSH, FULL_HOUSE, FOUR_OF_A_KIND, STRAIGHT_FLUSH, ROYAL_FLUSH）
- 倍率映射（HIGH_CARD=1, ONE_PAIR=2, ..., ROYAL_FLUSH=100）

**主要方法**:
- `get_multiplier(hand_type) -> int` - 获取牌型倍率
- `get_display_name_cn(hand_type) -> String` - 获取中文显示名
- `get_display_name_en(hand_type) -> String` - 获取英文显示名

**内嵌类 HandResult**:
- `hand_type: Type` - 识别出的牌型
- `multiplier: int` - 牌型倍率
- `cards: Array[CardData]` - 组成牌型的卡牌
- `base_score: int` - 基础分数总和
- `is_valid: bool` - 是否有效
- `get_total_score() -> int` - 获取总分（基础分×倍率）

---

#### hand_classifier.gd
**类型**: `class_name HandClassifier extends RefCounted`

**职责**: 牌型识别器，判断玩家选出的卡牌是什么牌型

**主要方法**:
- `evaluate(cards: Array[CardData]) -> HandResult` - 评估卡牌并返回最佳牌型
- `_check_one_pair(cards) -> HandResult` - 对子判断
- `_check_two_pair(cards) -> HandResult` - 两对判断
- `_check_three_of_a_kind(cards) -> HandResult` - 三条判断
- `_check_straight(cards) -> HandResult` - 顺子判断（支持A作1或14）
- `_check_flush(cards) -> HandResult` - 同花判断
- `_check_full_house(cards) -> HandResult` - 葫芦判断
- `_check_four_of_a_kind(cards) -> HandResult` - 四条判断
- `_check_straight_flush(cards) -> HandResult` - 同花顺判断
- `_check_royal_flush(cards) -> HandResult` - 皇家同花顺判断

**辅助方法**:
- `_count_ranks(cards) -> Dictionary` - 统计各牌面值出现次数
- `_count_suits(cards) -> Dictionary` - 统计各花色出现次数
- `_is_consecutive(values) -> bool` - 检查数组是否连续

---

### 得分计算系统 (scripts/systems/)

#### blind_type.gd
**类型**: `class_name BlindType extends RefCounted`

**职责**: 定义盲注类型枚举和倍率映射

**主要枚举**:
- `Type` - 盲注类型（SMALL_BLIND, BIG_BLIND, BOSS_BLIND）
- 目标分数倍率映射（SMALL=1, BIG=2, BOSS=3）
- 奖励倍率映射（SMALL=1, BIG=2, BOSS=3）

**主要方法**:
- `get_target_multiplier(blind_type) -> int` - 获取目标分数倍率
- `get_reward_multiplier(blind_type) -> int` - 获取奖励倍率
- `get_display_name_cn(blind_type) -> String` - 获取中文显示名
- `is_boss(blind_type) -> bool` - 检查是否为 Boss 盲注

---

#### score_calculator.gd
**类型**: `class_name ScoreCalculator extends RefCounted`

**职责**: 得分计算器，整合牌型分数、盲注倍率和装备效果

**主要方法**:
- `calculate_score(hand_result, blind_type) -> int` - 计算最终得分
- `calculate_score_with_modifiers(hand_result, blind_type, modifiers) -> int` - 带装备修正的计算
- `check_victory(current_score, target_score) -> bool` - 过关判定
- `calculate_reward(blind_type, base_reward) -> int` - 计算奖励金币
- `format_score_display(hand_result, blind_type) -> String` - 格式化得分显示

**内嵌类 ScoreBreakdown**:
- 分数详细分解（卡牌基础分、牌型倍率、盲注倍率、装备加成）
- 支持装备效果应用
- 提供详细显示字符串

---

#### stage_config.gd
**类型**: `class_name StageConfig extends Resource`

**职责**: 关卡配置，定义目标分数、回合数、盲注类型和 Boss 规则

**主要属性**:
- `stage_id: String` - 关卡 ID
- `display_name: String` - 关卡名称
- `base_target_score: int` - 基础目标分数
- `max_turns: int` - 最大回合数
- `blind_type: BlindType.Type` - 盲注类型
- `boss_rule: BossRule` - Boss 特殊规则
- `boss_rule_param: Dictionary` - Boss 规则参数
- `base_reward: int` - 基础奖励金币

**主要方法**:
- `get_target_score() -> int` - 获取实际目标分数（基础×盲注倍率）
- `get_reward() -> int` - 获取实际奖励金币
- `has_boss_rule() -> bool` - 检查是否有 Boss 规则
- `get_boss_rule_description() -> String` - 获取 Boss 规则描述
- `get_full_description() -> String` - 获取完整关卡描述
- `is_valid() -> bool` - 验证配置有效性

**枚举 BossRule**:
- NONE - 无特殊规则
- SUIT_EXCLUDED - 某花色不计分
- HAND_TYPE_EXCLUDED - 某牌型不计分
- PLAY_LIMIT - 出牌次数限制
- CARD_LIMIT - 手牌数量限制

---

### 关卡资源 (resources/stages/)

#### stage_1.tres
**名称**: 第一关 - 入门
**目标分数**: 100（小盲注 ×1）
**回合限制**: 3
**奖励**: 10 金币

#### stage_2.tres
**名称**: 第二关 - 进阶
**目标分数**: 600（大盲注 ×2）
**回合限制**: 3
**奖励**: 30 金币

#### stage_3.tres
**名称**: 第三关 - Boss
**目标分数**: 1500（Boss 盲注 ×3）
**回合限制**: 4
**奖励**: 75 金币
**特殊规则**: 方块不计分

---

### 测试文件 (tests/)

#### test_hand_classifier.gd
**类型**: `class_name TestHandClassifier extends RefCounted`

**职责**: HandClassifier 类的测试用例

**测试覆盖**:
- 高牌识别
- 对子识别（有效/无效）
- 两对识别
- 三条识别
- 顺子识别（包括A低顺子）
- 同花识别
- 葫芦识别
- 四条识别
- 同花顺识别
- 皇家同花顺识别
- 边界情况（空数组、单张、4张）
- 分数计算验证

---

#### test_score_calculator.gd
**类型**: `class_name TestScoreCalculator extends RefCounted`

**职责**: ScoreCalculator 和 BlindType 类的测试用例

**测试覆盖**:
- 盲注倍率验证（小/大/Boss）
- 基础分数计算
- 盲注分数计算
- 过关判定
- 奖励计算
- 装备修正器效果
- ScoreBreakdown 类测试
- 显示格式测试

---

#### test_stage_config.gd
**类型**: `class_name TestStageConfig extends RefCounted`

**职责**: StageConfig 类的测试用例

**测试覆盖**:
- 关卡创建
- 目标分数计算（盲注倍率）
- 奖励计算
- Boss 特殊规则
- 关卡描述
- 配置验证
- 工厂方法

---

## 待实现系统

以下系统尚未实现，将在后续阶段开发：

- [x] 牌型判断系统 (scripts/systems/hand_classifier.gd) ✅
- [x] 得分计算系统 (scripts/systems/score_calculator.gd) ✅
- [x] 关卡配置 (scripts/systems/stage_config.gd) ✅
- [ ] 手牌管理 (scripts/systems/hand_manager.gd)
- [ ] 回合管理 (scripts/systems/turn_manager.gd)
- [ ] 商店系统 (scripts/systems/shop_manager.gd)
- [ ] 游戏状态机 (scripts/systems/game_manager.gd)

---

## 设计文档 (memory-bank/)

### battle-scene-design.md
**类型**: 设计开发文档

**职责**: 战斗场景（Battle Scene）的设计与开发指南

**主要内容**:
- **场景目标**: 创建可运行的游戏场景来测试已完成功能
- **场景架构**: 战斗场景的完整节点树结构
- **核心组件**:
  - Card.gd - 卡牌显示组件（选择交互、选中边框、动画占位）
  - BattleController.gd - 战斗场景控制器（牌组管理、选牌、出牌、得分）
  - HandArea.gd - 手牌区域组件（动态更新、排序）
  - PlayArea.gd - 出牌区域组件（牌型显示、得分预览）
  - InfoPanel.gd - 信息面板（目标分数、累计分数、回合数、盲注类型）
  - ActionBar.gd - 操作按钮区（出牌、重置、重试）
- **系统整合**: 如何调用已完成的核心类（Deck, HandClassifier, ScoreCalculator, StageConfig）
- **UI 规格**: 卡牌尺寸、间距、字体大小、颜色等详细参数
- **测试流程**: 验收标准清单

**目标用户**: 开发者需要按照此文档实现战斗场景

---

**文档版本**: v1.3  
**最后更新**: 2026-04-09  
**已完成阶段**: 阶段一（项目骨架与数据结构）、阶段二（牌型判断系统）、阶段三（得分计算系统）  
**新增文档**: battle-scene-design.md（战斗场景设计开发文档）