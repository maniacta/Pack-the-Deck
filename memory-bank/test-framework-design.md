# Pack the Deck - 自动测试框架架构与实施方案

> **目标**：构建一套完整、可扩展、CI 友好的自动测试框架，覆盖从纯逻辑单元到端到端游戏流程的所有测试层次
> **版本**: v2.0 (新增人类模拟测试层)
> **创建日期**: 2026-05-13
> **状态**: 设计完成 ✓ — 人类模拟层已确认，等待实施

---

## 一、现状分析

### 1.1 当前测试基础设施

| 方面 | 现状 | 问题 |
|------|------|------|
| **测试框架** | GDUnit4 已安装但未使用 | 现有测试未迁移到 GDUnit4 TestCase 体系 |
| **测试格式** | 手动 `class_name TestXxx extends RefCounted` + 静态 `run_all_tests()` | 无断言库、无测试报告、无 IDE 集成 |
| **运行方式** | 主菜单 "运行测试" 按钮调用 `_run_tests()` | 纯手动，无命令行入口，无法 CI |
| **输出方式** | `print()` + `push_error()` | 无结构化结果，难以追踪失败 |
| **测试数量** | 7 个测试文件 | 覆盖良好但对某些系统不够深入 |
| **测试辅助** | 每个文件手写 `_create_card()` 工厂 | 工厂方法重复定义，无共享夹具 |

### 1.2 现有测试文件清单

| 测试文件 | 测试目标 | 方法数 |
|---------|---------|--------|
| `test_card_data.gd` | CardData + Deck | 6 |
| `test_hand_classifier.gd` | 10 种牌型识别 + 边界 + 分数 | 13 |
| `test_score_calculator.gd` | ScoreCalculator + BlindType | 8 |
| `test_stage_config.gd` | StageConfig + Boss 规则 | 7 |
| `test_rule_modifier.gd` | RuleModifier + EffectTrigger | 6 |
| `test_stage_manager.gd` | StageManager 关卡流程 | 5 |
| `test_boss_rules.gd` | Boss 规则完整测试 | 5 |

### 1.3 缺乏的测试覆盖

| 未覆盖系统 | 原因 | 风险 |
|-----------|------|------|
| EquipmentManager 背包放置/冲突 | 纯逻辑但未测试 | 形状冲突 Bug 回归 |
| ShopManager 商店生成/购买/刷新 | 有随机性，缺少种子控制 | 金币 Bug |
| HandManager / TurnManager | 已有类但无专门测试 | 回归风险 |
| GameManager 状态机 | 状态转换逻辑复杂 | 状态死锁 |
| BattleController 完整流程 | 依赖 UI 场景 | 集成问题难排查 |
| 装备效果组合 | 多装备叠加 | 规则冲突 Bug |
| UI 交互 | 需要渲染环境 | 点击/拖拽 Bug |
| 性能/压力 | 无基准 | 大量装备时的卡顿 |

---

## 二、框架总体架构

### 2.1 测试金字塔

```
         ┌──────────────────┐
         │ Human Simulation  │  ~2%: 真机 GUI 模式，模拟人类点击
         │  (本地运行)        │      开发完成后验证
         ├──────────────────┤
         │   Game Sim        │  ~5%: 无 UI 完整战斗流程
         │  (Headless CI)    │
         ├──────────────────┤
         │  集成测试          │  ~20%: 多系统协作
         │  (Headless CI)    │
         ├──────────────────┤
         │  单元测试          │  ~70%: 纯逻辑
         │  (Headless CI)    │
         └──────────────────┘
          性能基准测试 — 横向覆盖
```

### 2.2 框架分层

```
┌─────────────────────────────────────────────────────────┐
│                    CI/CD 层                              │
│  GitHub Actions (headless) / 本地终端 (GUI)              │
│  三层可 CI 运行(headless) + 一层本地运行(GUI 模式)       │
├─────────────────────────────────────────────────────────┤
│              测试编排层 (Test Runner)                     │
│  GdUnit4 TestSuite → 扫描/发现 → 执行 → 报告            │
│  HumanTester → 加载场景 → 模拟点击 → 文本验证 → 输出    │
├─────────────────────────────────────────────────────────┤
│              测试用例层 (Test Cases)                      │
│  ┌──────────┬──────────────┬──────────┬──────────────┐ │
│  │ 单元测试  │  集成测试     │ 模拟测试  │ 人类模拟测试  │ │
│  │ (Unit)   │ (Integration)│(Simulation│(HumanSim)    │ │
│  │ headless │  headless    │ headless │ GUI 模式     │ │
│  └──────────┴──────────────┴──────────┴──────────────┘ │
├─────────────────────────────────────────────────────────┤
│              测试工具层 (Test Utilities)                   │
│  ┌──────────┬──────────────┬──────────┬──────────────┐ │
│  │ 工厂方法  │  断言扩展     │ 种子控制  │ HumanTester  │ │
│  │Factories │  Matchers   │ Seeding  │ 人类操作模拟  │ │
│  └──────────┴──────────────┴──────────┴──────────────┘ │
├─────────────────────────────────────────────────────────┤
│              被测系统 (System Under Test)                  │
│  scripts/systems/  scripts/card/  scripts/equipment/    │
│  scenes/battle.tscn  scenes/shop.tscn                   │
└─────────────────────────────────────────────────────────┘
```

---

## 三、目录结构设计

```
tests/
├── test_suite.gd                     # 顶层 TestSuite，聚合所有测试
├── fixtures/                         # 共享测试夹具
│   ├── card_factory.gd               # 卡牌工厂方法
│   ├── equipment_factory.gd          # 装备工厂方法
│   ├── stage_factory.gd              # 关卡工厂方法
│   ├── hand_scenarios.gd             # 预定义牌型场景
│   └── seed_manager.gd              # 随机种子管理
├── unit/                             # 单元测试（镜像 scripts/ 结构）
│   ├── card/
│   │   ├── test_card_data.gd         # CardData 测试 (迁移)
│   │   ├── test_deck.gd              # Deck 测试 (迁移)
│   │   └── test_deck_generator.gd    # DeckGenerator 测试 (新增)
│   ├── equipment/
│   │   ├── test_equipment_data.gd    # EquipmentData 测试 (新增)
│   │   └── test_equipment_manager.gd # EquipmentManager 测试 (新增)
│   ├── systems/
│   │   ├── test_hand_type.gd         # HandType 测试 (新增)
│   │   ├── test_hand_classifier.gd   # HandClassifier 测试 (迁移)
│   │   ├── test_hand_manager.gd      # HandManager 测试 (新增)
│   │   ├── test_score_calculator.gd  # ScoreCalculator 测试 (迁移)
│   │   ├── test_blind_type.gd        # BlindType 测试 (迁移)
│   │   ├── test_stage_config.gd      # StageConfig 测试 (迁移)
│   │   ├── test_rule_modifier.gd     # RuleModifier 测试 (迁移)
│   │   ├── test_effect_trigger.gd    # EffectTrigger 测试 (迁移)
│   │   ├── test_turn_manager.gd      # TurnManager 测试 (新增)
│   │   ├── test_game_manager.gd      # GameManager 测试 (新增)
│   │   ├── test_shop_item.gd         # ShopItem/ShopConfig 测试 (新增)
│   │   └── test_shop_manager.gd      # ShopManager 测试 (新增)
│   └── ui/                           # UI 纯逻辑单元测试
│       ├── test_card_display_logic.gd    # CardDisplay 逻辑 (新增)
│       └── test_backpack_panel_logic.gd  # BackpackPanel 逻辑 (新增)
├── integration/                      # 集成测试
│   ├── test_classifier_with_modifiers.gd   # 牌型判断 + 规则改写
│   ├── test_score_with_equipment.gd        # 得分 + 装备效果
│   ├── test_battle_pipeline.gd             # 出牌完整管道
│   ├── test_shop_pipeline.gd               # 商店购买 + 装备放置
│   ├── test_stage_progression.gd           # 多关卡流程
│   ├── test_equipment_interactions.gd      # 多装备叠加/冲突
│   └── test_boss_rules_integration.gd      # Boss 规则端到端
├── simulation/                       # 游戏模拟测试 (无 UI, headless)
│   ├── battle_simulator.gd           # BattleSimulator 类
│   ├── test_full_battle.gd           # 完整战斗模拟
│   ├── test_game_loop.gd             # 战斗→商店→战斗循环
│   ├── test_balance_smoke.gd         # 平衡性冒烟测试
│   └── test_stress.gd               # 压力/边界测试
├── human/                            # 人类模拟测试 (GUI 模式)
│   ├── test_battle_flow.gd           # 完整战斗流程：选牌→出牌→过关
│   ├── test_shop_flow.gd             # 商店流程：购买→放置→继续
│   ├── test_backpack_flow.gd         # 背包放置交互
│   └── test_full_game.gd            # 端到端完整游戏
├── benchmark/                        # 性能基准测试
│   ├── test_hand_classifier_perf.gd  # 牌型判断性能
│   └── test_deck_perf.gd            # 牌组操作性能
└── output/                           # 测试输出 (gitignore)
    └── last_run.txt                  # 最近一次运行结果

# scripts/testing/ (HumanTester 类)
scripts/testing/
├── human_tester.gd                   # 核心人类操作模拟类
└── test_harness.gd                   # 测试场景入口脚本
```

---

## 四、核心测试基础设施

### 4.1 GDUnit4 迁移方案

GDUnit4 提供完整的 xUnit 风格测试框架，迁移步骤：

**旧格式 → 新格式对照：**

```gdscript
# 旧格式 (当前)
class_name TestHandClassifier
extends RefCounted

static func run_all_tests() -> bool:
    var all_passed := true
    all_passed = _test_one_pair() and all_passed
    return all_passed

static func _test_one_pair() -> bool:
    if result.hand_type != HandType.Type.ONE_PAIR:
        push_error("失败: 应为 ONE_PAIR")
        return false
    return true
```

```gdscript
# 新格式 (GDUnit4)
extends GdUnitTestSuite

func test_one_pair() -> void:
    var cards := CardFactory.create_pair(CardData.Rank.FIVE)
    var result := HandClassifier.evaluate(cards)

    assert_that(result.hand_type).is_equal(HandType.Type.ONE_PAIR)
    assert_that(result.multiplier).is_equal(2)
    assert_that(result.base_score).is_equal(10)
```

**关键变化：**
| 方面 | 旧格式 | 新格式 |
|------|--------|--------|
| 基类 | `RefCounted` | `GdUnitTestSuite` |
| 发现方式 | 手动调用 | 自动扫描 `test_*.gd` |
| 断言 | `push_error()` + 手动 `return false` | `assert_that().is_equal()` 等 |
| 生命周期 | 无 | `before()`, `after()`, `before_test()`, `after_test()` |
| 参数化 | 无 | `test_case()` + `@data` 注解 |
| 报告 | print 日志 | XML/JSON 结构化报告 |

### 4.2 顶层测试套件

```gdscript
# tests/test_suite.gd
extends GdUnitTestSuite

## 聚合所有测试套件，CI 入口
## 运行方式: godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -c run -a res://tests/

## 测试套件按金字塔层级配置超时和隔离要求：
## - unit/: 每个测试 ≤ 1s, 完全隔离
## - integration/: 每个测试 ≤ 5s, 可共享夹具
## - simulation/: 每个测试 ≤ 30s, 可使用随机种子
## - ui/: 每个测试 ≤ 10s, 需要渲染环境 (不可 headless)
```

### 4.3 项目配置

在 `project.godot` 中添加：

```toml
[gdunit4]
# GdUnit4 配置
settings/test_discovery="res://tests/"
settings/report_dir="res://tests/reports/"
settings/failure_stop=false
settings/timeout_per_test=30000
```

---

## 五、测试工具层 (Fixtures + Utilities)

### 5.1 卡牌工厂 (`tests/fixtures/card_factory.gd`)

统一管理卡牌创建，消除重复的 `_create_card()` 方法：

```gdscript
# tests/fixtures/card_factory.gd
class_name CardFactory
extends RefCounted

## 创建单张卡牌
static func card(rank: CardData.Rank, suit: CardData.Suit = CardData.Suit.SPADES) -> CardData:
    var c := CardData.new()
    c.rank = rank
    c.suit = suit
    return c

## 创建对子（2张同值）
static func pair(rank: CardData.Rank) -> Array[CardData]:
    return [card(rank, CardData.Suit.SPADES), card(rank, CardData.Suit.HEARTS)]

## 创建三条（3张同值）
static func three_of_a_kind(rank: CardData.Rank) -> Array[CardData]:
    return [
        card(rank, CardData.Suit.SPADES),
        card(rank, CardData.Suit.HEARTS),
        card(rank, CardData.Suit.DIAMONDS)
    ]

## 创建四条（4张同值）
static func four_of_a_kind(rank: CardData.Rank) -> Array[CardData]:
    return [
        card(rank, CardData.Suit.SPADES),
        card(rank, CardData.Suit.HEARTS),
        card(rank, CardData.Suit.DIAMONDS),
        card(rank, CardData.Suit.CLUBS)
    ]

## 创建标准顺子（从 start_rank 开始，5张连续）
static func straight(start_rank: CardData.Rank = CardData.Rank.TWO) -> Array[CardData]:
    var cards: Array[CardData] = []
    var suits := [CardData.Suit.SPADES, CardData.Suit.HEARTS, CardData.Suit.DIAMONDS,
                  CardData.Suit.CLUBS, CardData.Suit.SPADES]
    var rank_val := int(start_rank)
    for i in range(5):
        if rank_val + i > CardData.Rank.ACE:
            break
        cards.append(card(rank_val + i, suits[i]))
    return cards

## 创建同花（5张同花色）
static func flush(suit: CardData.Suit = CardData.Suit.HEARTS) -> Array[CardData]:
    var ranks := [CardData.Rank.TWO, CardData.Rank.FIVE, CardData.Rank.SEVEN,
                  CardData.Rank.TEN, CardData.Rank.KING]
    var cards: Array[CardData] = []
    for r in ranks:
        cards.append(card(r, suit))
    return cards

## 创建葫芦（3+2）
static func full_house(triple_rank: CardData.Rank, pair_rank: CardData.Rank) -> Array[CardData]:
    return three_of_a_kind(triple_rank) + pair(pair_rank)

## 创建皇家同花顺
static func royal_flush(suit: CardData.Suit = CardData.Suit.SPADES) -> Array[CardData]:
    var ranks := [CardData.Rank.TEN, CardData.Rank.JACK, CardData.Rank.QUEEN,
                  CardData.Rank.KING, CardData.Rank.ACE]
    var cards: Array[CardData] = []
    for r in ranks:
        cards.append(card(r, suit))
    return cards

## 创建完整 52 张牌组
static func full_deck() -> Deck:
    var d := Deck.new()
    d.shuffle()
    return d

## 创建带种子的牌组（可复现）
## 通过调用全局 seed() 确保 Deck 的 shuffle() 产生确定结果
static func seeded_deck(seed_val: int) -> Deck:
    seed(seed_val)  # 固定全局随机种子，使后续 shuffle 可复现
    var d := Deck.new()
    d.shuffle()
    return d
```

### 5.2 装备工厂 (`tests/fixtures/equipment_factory.gd`)

```gdscript
# tests/fixtures/equipment_factory.gd
class_name EquipmentFactory
extends RefCounted

## 创建最小装备 (1×1, 无效果)
static func dummy(name: String = "TestEq") -> EquipmentData:
    var eq := EquipmentData.new()
    eq.display_name = name
    eq.shape = [Vector2i(0, 0)]
    eq.category = EquipmentData.Category.GENERIC
    eq.effect_type = EquipmentData.EffectType.SCORE_MODIFY
    eq.effect_params = {"score_bonus": 0}
    return eq

## 创建规则改写装备 — 顺子最少牌数
## effect_params 必须使用 RuleModifier.add_equipment_rules() 实际检查的键名
static func straight_lens(min_cards: int = 4) -> EquipmentData:
    var eq := EquipmentData.new()
    eq.display_name = "StraightLens"
    eq.category = EquipmentData.Category.OPTICAL
    eq.effect_type = EquipmentData.EffectType.RULE_MODIFY
    eq.trigger_timing = EquipmentData.TriggerTiming.ON_SCORE
    eq.shape = [Vector2i(0, 0)]
    eq.effect_params = {
        "straight_min_cards": min_cards  # RuleModifier 检查此键
    }
    eq.priority = 10
    return eq

## 创建倍率修改装备
## effect_params 必须包含 "hand_type_multiplier" (truthy)、"target_hand_type" (HandType.Type int值)、"multiplier_factor" (float)
static func multiplier_mod(hand_type: HandType.Type, multiplier: float = 2.0) -> EquipmentData:
    var eq := EquipmentData.new()
    eq.display_name = "MultiplierMod"
    eq.category = EquipmentData.Category.MAGICAL
    eq.effect_type = EquipmentData.EffectType.RULE_MODIFY
    eq.trigger_timing = EquipmentData.TriggerTiming.ON_SCORE
    eq.shape = [Vector2i(0, 0)]
    eq.effect_params = {
        "hand_type_multiplier": true,       # 触发键，值需为 truthy
        "target_hand_type": int(hand_type), # RuleModifier 读取此键作为目标牌型
        "multiplier_factor": multiplier     # 倍率系数 (RuleModifier 读取)
    }
    eq.priority = 5
    return eq

## 创建形状装备（用于背包测试）
static func shaped(shape: Array, category: EquipmentData.Category = EquipmentData.Category.GENERIC) -> EquipmentData:
    var eq := EquipmentData.new()
    eq.display_name = "Shaped"
    eq.category = category
    eq.effect_type = EquipmentData.EffectType.STRUCTURE
    eq.shape = shape
    return eq

## 创建 2×2 装备
static func large_2x2() -> EquipmentData:
    return shaped([
        Vector2i(0, 0), Vector2i(0, 1),
        Vector2i(1, 0), Vector2i(1, 1)
    ], EquipmentData.Category.MECHANICAL)

## 创建 L 形装备
static func l_shaped() -> EquipmentData:
    return shaped([
        Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)
    ])
```

### 5.3 关卡工厂 (`tests/fixtures/stage_factory.gd`)

```gdscript
# tests/fixtures/stage_factory.gd
class_name StageFactory
extends RefCounted

## 创建基础关卡配置
static func stage(
    target: int = 100,
    turns: int = 3,
    blind: BlindType.Type = BlindType.Type.SMALL_BLIND,
    boss_rule: StageConfig.BossRule = StageConfig.BossRule.NONE
) -> StageConfig:
    var s := StageConfig.new()
    s.stage_id = "test_stage"
    s.display_name = "测试关卡"
    s.base_target_score = target
    s.max_turns = turns
    s.blind_type = blind
    s.boss_rule = boss_rule
    return s

## 创建 Boss 关卡（含花色排除规则）
static func boss_with_suit_exclusion(excluded_suit: CardData.Suit) -> StageConfig:
    var s := stage(500, 4, BlindType.Type.BOSS_BLIND, StageConfig.BossRule.SUIT_EXCLUDED)
    s.boss_rule_param = {"suit": excluded_suit}
    return s

## 创建 Boss 关卡（含牌型排除规则）
static func boss_with_hand_exclusion(hand_type: HandType.Type) -> StageConfig:
    var s := stage(500, 4, BlindType.Type.BOSS_BLIND, StageConfig.BossRule.HAND_TYPE_EXCLUDED)
    s.boss_rule_param = {"hand_type": hand_type}
    return s

## 创建 Boss 关卡（含出牌次数限制）
static func boss_with_play_limit(limit: int = 3) -> StageConfig:
    var s := stage(500, 4, BlindType.Type.BOSS_BLIND, StageConfig.BossRule.PLAY_LIMIT)
    s.boss_rule_param = {"limit": limit}
    return s
```

### 5.4 牌型场景库 (`tests/fixtures/hand_scenarios.gd`)

预定义常见测试场景，供所有测试用例引用：

```gdscript
# tests/fixtures/hand_scenarios.gd
class_name HandScenarios
extends RefCounted

## 所有 10 种标准牌型场景
const PAIR_5: Array = [[CardData.Rank.FIVE, CardData.Suit.SPADES],
                        [CardData.Rank.FIVE, CardData.Suit.HEARTS]]
const TWO_PAIR_3_7: Array = [[CardData.Rank.THREE, CardData.Suit.SPADES], ...]
const STRAIGHT_2_6: Array = [...]
const STRAIGHT_10_A: Array = [...]
const STRAIGHT_ACE_LOW: Array = [...]
const FLUSH_SPADES: Array = [...]
const FULL_HOUSE_K_5: Array = [...]
const FOUR_OF_A_KIND_Q: Array = [...]
const STRAIGHT_FLUSH_HEARTS: Array = [...]
const ROYAL_FLUSH_SPADES: Array = [...]

## 边界场景
const EMPTY: Array = []
const SINGLE_CARD: Array = [[CardData.Rank.ACE, CardData.Suit.SPADES]]
const FOUR_CARDS: Array = [...]  # 4 张 (不可成顺子/同花)
const SIX_FLUSH: Array = [...]   # 6 张同花
```

### 5.5 种子管理器 (`tests/fixtures/seed_manager.gd`)

控制随机性以实现可复现测试：

```gdscript
# tests/fixtures/seed_manager.gd
class_name SeedManager
extends RefCounted

## 固定种子用于确定性测试
const SEED_REPRODUCIBLE: int = 12345

## 为 RNG 设置固定种子
static func seed_rng(rng: RandomNumberGenerator, seed: int = SEED_REPRODUCIBLE) -> void:
    rng.seed = seed

## 为所有随机系统设置全局种子
static func set_global_seed(seed: int) -> void:
    seed(seed)  # Godot 内置函数
```

---

## 六、单元测试设计模式

### 6.1 标准测试模式

```gdscript
# tests/unit/systems/test_hand_classifier.gd
extends GdUnitTestSuite

## 牌型识别器单元测试
## 覆盖: 10 种牌型识别 + 边界情况 + 分数验证

# ─── 生命周期 ─────────────────────────────────────────────

func before() -> void:
    # 每个测试文件运行前执行一次
    pass

func after() -> void:
    # 每个测试文件运行后执行一次
    pass

func before_test() -> void:
    # 每个测试用例前执行
    pass

func after_test() -> void:
    # 每个测试用例后执行
    pass

# ─── 对子测试 ──────────────────────────────────────────────

func test_one_pair_valid() -> void:
    var cards := CardFactory.pair(CardData.Rank.FIVE)
    var result := HandClassifier.evaluate(cards)

    assert_that(result.hand_type).is_equal(HandType.Type.ONE_PAIR)
    assert_that(result.multiplier).is_equal(2)
    assert_that(result.base_score).is_equal(10)
    assert_that(result.is_valid).is_true()

func test_one_pair_invalid_wrong_count() -> void:
    var cards := CardFactory.three_of_a_kind(CardData.Rank.FIVE)
    var result := HandClassifier.evaluate(cards)

    assert_that(result.hand_type).is_not_equal(HandType.Type.ONE_PAIR)

func test_one_pair_invalid_different_ranks() -> void:
    var cards := [CardFactory.card(CardData.Rank.FIVE), CardFactory.card(CardData.Rank.SIX)]
    var result := HandClassifier.evaluate(cards)

    assert_that(result.hand_type).is_not_equal(HandType.Type.ONE_PAIR)

# ─── 参数化测试: 顺子 ───────────────────────────────────────

enum StraightParam { NORMAL, ACE_LOW, HIGH }

func test_straight_detection(
    param: StraightParam = StraightParam.NORMAL
) -> void:
    var cards: Array[CardData]
    match param:
        StraightParam.NORMAL:
            cards = CardFactory.straight(CardData.Rank.TWO)
        StraightParam.ACE_LOW:
            cards = CardFactory.straight_ace_low()
        StraightParam.HIGH:
            cards = CardFactory.straight(CardData.Rank.TEN)

    var result := HandClassifier.evaluate(cards)
    assert_that(result.hand_type).is_equal(HandType.Type.STRAIGHT)
    assert_that(result.multiplier).is_equal(30)

# ─── 边界测试 ──────────────────────────────────────────────

func test_empty_hand_returns_invalid() -> void:
    var result := HandClassifier.evaluate([])
    assert_that(result.is_valid).is_false()

func test_single_card_is_high_card() -> void:
    var result := HandClassifier.evaluate([CardFactory.card(CardData.Rank.ACE)])
    assert_that(result.hand_type).is_equal(HandType.Type.HIGH_CARD)

func test_six_card_flush_uses_best_five() -> void:
    # 6 张同花应识别为同花且只用最大的 5 张计分
    var cards := CardFactory.flush(CardData.Suit.SPADES)
    cards.append(CardFactory.card(CardData.Rank.THREE, CardData.Suit.SPADES))
    var result := HandClassifier.evaluate(cards)
    assert_that(result.hand_type).is_equal(HandType.Type.FLUSH)
    assert_that(result.cards.size()).is_equal(5)
```

### 6.2 EquipmentManager 背包单元测试 (新增，关键)

```gdscript
# tests/unit/equipment/test_equipment_manager.gd
extends GdUnitTestSuite

var _manager: EquipmentManager

func before_test() -> void:
    _manager = EquipmentManager.new()

# ─── 基础放置 ──────────────────────────────────────────────

func test_place_1x1_equipment() -> void:
    var eq := EquipmentFactory.dummy()
    var placed := _manager.place_equipment(eq, Vector2i(0, 0))
    assert_that(placed).is_true()
    assert_that(_manager.get_equipment_anchor(eq)).is_equal(Vector2i(0, 0))

func test_place_2x2_equipment() -> void:
    var eq := EquipmentFactory.large_2x2()
    var placed := _manager.place_equipment(eq, Vector2i(1, 1))
    assert_that(placed).is_true()
    # 所有 4 个格子应被占用

func test_cannot_place_on_occupied_cell() -> void:
    var eq1 := EquipmentFactory.dummy()
    var eq2 := EquipmentFactory.dummy()
    _manager.place_equipment(eq1, Vector2i(0, 0))
    var placed := _manager.place_equipment(eq2, Vector2i(0, 0))
    assert_that(placed).is_false()

func test_cannot_place_out_of_bounds() -> void:
    var eq := EquipmentFactory.large_2x2()
    var placed := _manager.place_equipment(eq, Vector2i(4, 3))  # 会越界
    assert_that(placed).is_false()

# ─── 卸下装备 ──────────────────────────────────────────────

func test_unequip_frees_cells() -> void:
    var eq := EquipmentFactory.dummy()
    _manager.place_equipment(eq, Vector2i(2, 1))
    var removed := _manager.unequip(eq)
    assert_that(removed).is_true()
    # 原位置应可再次放置
    var eq2 := EquipmentFactory.dummy()
    assert_that(_manager.place_equipment(eq2, Vector2i(2, 1))).is_true()

# ─── 相邻检测 ──────────────────────────────────────────────

func test_detect_adjacent_equipment() -> void:
    var eq1 := EquipmentFactory.dummy()
    var eq2 := EquipmentFactory.dummy()
    _manager.place_equipment(eq1, Vector2i(0, 0))
    _manager.place_equipment(eq2, Vector2i(0, 1))
    var adj := _manager.get_adjacent_equipment(Vector2i(0, 0))
    assert_that(adj.size()).is_equal(1)
    assert_that(adj[0]).is_equal(eq2)
```

### 6.3 状态机测试 (GameManager)

```gdscript
# tests/unit/systems/test_game_manager.gd
extends GdUnitTestSuite

var _gm: GameManager
var _state_history: Array[GameManager.GameState]

func before_test() -> void:
    _gm = GameManager.new()
    _state_history.clear()
    _gm.state_changed.connect(_on_state_change)

func _on_state_change(old: GameManager.GameState, new: GameManager.GameState) -> void:
    _state_history.append(new)

func test_initial_state_is_title() -> void:
    assert_that(_gm.current_state).is_equal(GameManager.GameState.TITLE)

func test_start_game_transitions_to_battle() -> void:
    _gm.start_game()
    assert_that(_gm.current_state).is_equal(GameManager.GameState.BATTLE)
    assert_that(_state_history).contains(GameManager.GameState.BATTLE)

func test_same_state_no_reentry() -> void:
    _gm.start_game()  # TITLE → BATTLE
    var before_count := _state_history.size()
    _gm.change_state(GameManager.GameState.BATTLE)  # 重复
    assert_that(_state_history.size()).is_equal(before_count)

func test_game_over_transitions() -> void:
    _gm.start_game()  # BATTLE
    _gm.on_game_lost()
    assert_that(_gm.current_state).is_equal(GameManager.GameState.GAME_OVER)

func test_full_game_cycle() -> void:
    _gm.start_game()              # BATTLE
    _gm.enter_shop()              # SHOP
    _gm.enter_battle()            # BATTLE (下一关)
    _gm.on_stage_cleared(3, 3, true)  # 全部通关
    assert_that(_gm.current_state).is_equal(GameManager.GameState.VICTORY)

func test_cannot_play_outside_battle() -> void:
    assert_that(_gm.can_play_cards()).is_false()
    _gm.start_game()
    assert_that(_gm.can_play_cards()).is_true()
```

---

## 七、集成测试设计

### 7.1 牌型判断 + 规则改写集成

```gdscript
# tests/integration/test_classifier_with_modifiers.gd
extends GdUnitTestSuite

## 验证 HandClassifier + RuleModifier 的正确交互
## 关键集成点: evaluate_with_modifiers()

func test_straight_4_cards_with_lens() -> void:
    # 无装备: 4 张连续牌不是顺子
    var cards := CardFactory.straight(CardData.Rank.THREE).slice(0, 4)
    var without_mod := HandClassifier.evaluate(cards)
    assert_that(without_mod.hand_type).is_not_equal(HandType.Type.STRAIGHT)

    # 装备完美镜片后: 4 张连续牌识别为顺子
    var modifier := RuleModifier.new()
    var eq := EquipmentFactory.straight_lens(4)
    modifier.add_equipment_rules(eq)

    var with_mod := HandClassifier.evaluate_with_modifiers(cards, modifier)
    assert_that(with_mod.hand_type).is_equal(HandType.Type.STRAIGHT)

func test_multiple_modifiers_stack() -> void:
    # 同时装备: 顺子4张 + 顺子倍率翻倍
    var modifier := RuleModifier.new()
    modifier.add_equipment_rules(EquipmentFactory.straight_lens(4))
    modifier.add_equipment_rules(EquipmentFactory.multiplier_mod(HandType.Type.STRAIGHT, 2))

    var cards := CardFactory.straight(CardData.Rank.THREE).slice(0, 4)
    var result := HandClassifier.evaluate_with_modifiers(cards, modifier)

    assert_that(result.hand_type).is_equal(HandType.Type.STRAIGHT)
    # 基础倍率 30 × 修改数 2 = 60
    assert_that(result.multiplier).is_equal(60)

func test_modifier_priority_override() -> void:
    # 装备 A: 顺子需 4 张 (高优先级 100)
    # 装备 B: 顺子需 5 张 (低优先级 10)
    # 预期: 应用高优先级规则 (顺子需 4 张)
    var modifier := RuleModifier.new()

    var eq_a := EquipmentFactory.straight_lens(4)
    eq_a.priority = 100
    var eq_b := EquipmentFactory.straight_lens(5)
    eq_b.priority = 10

    modifier.add_equipment_rules(eq_a)
    modifier.add_equipment_rules(eq_b)

    var cards := CardFactory.straight(CardData.Rank.THREE).slice(0, 4)
    var result := HandClassifier.evaluate_with_modifiers(cards, modifier)
    assert_that(result.hand_type).is_equal(HandType.Type.STRAIGHT)
```

### 7.2 得分 + 装备效果集成

```gdscript
# tests/integration/test_score_with_equipment.gd
extends GdUnitTestSuite

func test_score_gem_adds_flat_bonus() -> void:
    # 得分宝石: 出牌 +20 基础分
    var cards := CardFactory.pair(CardData.Rank.FIVE)  # 基础分=10, 倍率2, 总20
    var hand_result := HandClassifier.evaluate(cards)

    # ScoreCalculator.calculate_score_with_modifiers 接受 Dictionary
    var final_score := ScoreCalculator.calculate_score_with_modifiers(
        hand_result, BlindType.Type.SMALL_BLIND,
        {"score_bonus": 20}
    )

    # 基础分(10) + 加成(20) = 30, 倍率2, 小盲注×1 = 60
    assert_that(final_score).is_equal(60)

func test_multiple_score_sources_combine() -> void:
    # 得分宝石 +20 + 对子倍率翻倍
    var cards := CardFactory.pair(CardData.Rank.FIVE)
    var hand_result := HandClassifier.evaluate(cards)

    var modifier := RuleModifier.new()
    modifier.add_equipment_rules(
        EquipmentFactory.multiplier_mod(HandType.Type.ONE_PAIR, 2.0)
    )
    hand_result = HandClassifier.evaluate_with_modifiers(cards, modifier)

    var final := ScoreCalculator.calculate_score_with_modifiers(
        hand_result, BlindType.Type.SMALL_BLIND,
        {"score_bonus": 20}
    )

    # (10 + 20) × (2 × 2) × 1 = 120
    assert_that(final).is_equal(120)
```

### 7.3 Boss 规则集成

```gdscript
# tests/integration/test_boss_rules_integration.gd
extends GdUnitTestSuite

func test_suit_exclusion_filters_diamonds() -> void:
    # Boss 规则: 方块不计分 → 对子 [方块5, 黑桃5] 只有黑桃5计分
    var stage := StageFactory.boss_with_suit_exclusion(CardData.Suit.DIAMONDS)
    var cards := [CardFactory.card(CardData.Rank.FIVE, CardData.Suit.DIAMONDS),
                  CardFactory.card(CardData.Rank.FIVE, CardData.Suit.SPADES)]

    var hand_result := HandClassifier.evaluate(cards)

    # 模拟 BattleController 的花色排除逻辑
    var filtered_cards: Array[CardData] = []
    for c in cards:
        if c.suit != stage.boss_rule_param["suit"]:
            filtered_cards.append(c)

    var filtered_result := HandClassifier.evaluate(filtered_cards)
    var score := ScoreCalculator.calculate_score(filtered_result, stage.blind_type)
    # 只有黑桃5: 高牌, 基分5, 倍率1, Boss×3 = 15
    assert_that(score).is_equal(15)
```

---

## 八、游戏模拟测试 (Headless E2E)

此类测试是框架的核心创新——在无 UI 的环境下运行完整游戏逻辑：

### 8.1 战斗模拟基础类

```gdscript
# tests/simulation/battle_simulator.gd
class_name BattleSimulator
extends RefCounted

## 无 UI 战斗模拟器
## 模拟完整战斗过程：抽牌→选牌→出牌→计分→重复→判定

var deck: Deck
var hand_manager: HandManager
var turn_manager: TurnManager
var stage_config: StageConfig
var equipment_manager: EquipmentManager
var effect_trigger: EffectTrigger
var rule_modifier: RuleModifier
var stage_manager: StageManager

var current_score: int = 0
var play_history: Array[Dictionary] = []


func setup(config: StageConfig, equipment: Array[EquipmentData] = [], fixed_seed: int = 12345) -> void:
    stage_config = config

    # 固定随机种子，确保 Deck.shuffle() 结果可复现
    seed(fixed_seed)

    deck = Deck.new()
    deck.shuffle()

    hand_manager = HandManager.new()
    hand_manager.set_capacity(10, 5)

    turn_manager = TurnManager.new()
    turn_manager.setup(config)

    # ⚠️ 顺序重要：EquipmentManager 必须在 EffectTrigger 之前创建
    # 因为 EffectTrigger._init(equipment_manager) 需要 EquipmentManager 引用
    equipment_manager = EquipmentManager.new()
    effect_trigger = EffectTrigger.new(equipment_manager)
    rule_modifier = RuleModifier.new()

    # 放置初始装备
    for eq in equipment:
        var slot := _find_free_slot(eq)
        if slot.x >= 0:
            equipment_manager.place_equipment(eq, slot)
            rule_modifier.add_equipment_rules(eq)

    stage_manager = StageManager.new()

    # 初始抽牌
    _draw_to_fill()


func _draw_to_fill() -> void:
    var needed := hand_manager.max_hand_size - hand_manager.get_hand().size()
    if needed > 0:
        var new_cards := deck.draw_cards(needed)
        hand_manager.add_to_hand(new_cards)


func auto_select_best() -> Array[CardData]:
    ## 自动选择最佳牌型（用于模拟测试）
    ## 遍历手牌的所有 1-5 张组合，返回得分最高的
    var best_score: int = -1
    var best_combo: Array[CardData] = []
    var hand := hand_manager.get_hand()

    # 简化版：尝试常见模式
    var combos := _generate_combinations(hand, 1, 5)
    for combo in combos:
        var result := HandClassifier.evaluate_with_modifiers(combo, rule_modifier)
        var score := ScoreCalculator.calculate_score(result, stage_config.blind_type)
        if score > best_score:
            best_score = score
            best_combo = combo

    return best_combo


func play_turn(cards: Array[CardData]) -> Dictionary:
    ## 执行一次出牌并返回结果
    var info := {}

    # 触发回合开始效果
    effect_trigger.trigger_turn_start(turn_manager.current_turn, 0)

    # 选牌
    hand_manager.clear_selection()
    for c in cards:
        hand_manager.toggle_selection(c)

    # 出牌
    turn_manager.record_play()

    # 牌型识别 + 规则改写
    var hand_result := HandClassifier.evaluate_with_modifiers(cards, rule_modifier)

    # 触发得分效果 → 返回 Array[EffectResult]
    var score_effects: Array = effect_trigger.trigger_score_effects(
        hand_result, 0, stage_config.blind_type
    )

    # ⚠️ 将 Array[EffectResult] 转换为 ScoreCalculator 需要的 Dictionary 格式
    var total_score_bonus: int = 0
    var total_multiplier_bonus: float = 1.0
    for effect in score_effects:
        if effect is EffectTrigger.EffectResult:
            total_score_bonus += effect.score_bonus
            total_multiplier_bonus *= effect.multiplier_bonus

    var modifiers := {
        "score_bonus": total_score_bonus,
        "multiplier_bonus": total_multiplier_bonus
    }

    # 计算最终得分
    var score := ScoreCalculator.calculate_score_with_modifiers(
        hand_result, stage_config.blind_type, modifiers
    )
    current_score += score

    # 移除已出牌
    hand_manager.remove_from_hand(cards)
    for c in cards:
        deck.discard(c)

    # 补充手牌
    _draw_to_fill()

    # 记录
    info["hand_type"] = hand_result.hand_type
    info["score"] = score
    info["current_total"] = current_score
    info["remaining_turns"] = turn_manager.remaining_turns
    play_history.append(info)

    return info


func is_victory() -> bool:
    return current_score >= stage_config.get_target_score()


func is_defeat() -> bool:
    return turn_manager.is_turns_exhausted() and not is_victory()


func _generate_combinations(arr: Array, min_len: int, max_len: int) -> Array[Array]:
    var result: Array[Array] = []
    var n := arr.size()
    for size in range(min_len, min(max_len, n) + 1):
        var indices := range(size)
        while true:
            var combo: Array = []
            for i in indices:
                combo.append(arr[i])
            result.append(combo)
            # 移动到下一个组合
            var j := size - 1
            while j >= 0 and indices[j] == j + n - size:
                j -= 1
            if j < 0:
                break
            indices[j] += 1
            for k in range(j + 1, size):
                indices[k] = indices[k - 1] + 1
    return result


func _find_free_slot(eq: EquipmentData) -> Vector2i:
    for y in range(EquipmentManager.GRID_HEIGHT):
        for x in range(EquipmentManager.GRID_WIDTH):
            var pos := Vector2i(x, y)
            if equipment_manager.can_place(eq, pos):
                return pos
    return Vector2i(-1, -1)  # 无处可放
```

### 8.2 完整战斗模拟测试

```gdscript
# tests/simulation/test_full_battle.gd
extends GdUnitTestSuite

func test_complete_battle_stage_1() -> void:
    ## 模拟关卡 1 的完整战斗
    var config := StageFactory.stage(150, 4, BlindType.Type.SMALL_BLIND)
    var sim := BattleSimulator.new()
    sim.setup(config)

    var turns_played := 0
    while not sim.is_defeat() and not sim.is_victory():
        if not sim.turn_manager.can_play():
            break
        var best := sim.auto_select_best()
        if best.is_empty():
            break
        var info := sim.play_turn(best)
        turns_played += 1

        # 验证每次出牌有效
        assert_that(info["score"]).is_greater(0)
        assert_that(info["hand_type"]).is_not_null()

    # 验证游戏结果
    assert_that(sim.is_victory()).is_true()
    assert_that(sim.current_score).is_greater_equal(config.get_target_score())
    assert_bool(turns_played <= config.max_turns).is_true()

    # 打印战斗日志
    print("=== 模拟战斗结果 ===")
    print("总分: %d, 目标: %d, 回合: %d/%d" % [
        sim.current_score, config.get_target_score(),
        turns_played, config.max_turns
    ])
    for i in range(sim.play_history.size()):
        var h := sim.play_history[i]
        print("  回合 %d: 牌型=%s, 得分=%d" % [
            i + 1,
            HandType.get_display_name_cn(h["hand_type"]),
            h["score"]
        ])


func test_battle_with_equipment() -> void:
    ## 带装备的战斗模拟
    var config := StageFactory.stage(150, 4, BlindType.Type.SMALL_BLIND)
    var equipment := [EquipmentFactory.straight_lens(4)]
    var sim := BattleSimulator.new()
    sim.setup(config, equipment)

    # 验证顺子规则被改写
    assert_that(sim.rule_modifier.get_straight_min_cards()).is_equal(4)

    # 运行几回合
    for i in range(2):
        if sim.is_defeat() or sim.is_victory():
            break
        var best := sim.auto_select_best()
        if not best.is_empty():
            sim.play_turn(best)

    assert_that(sim.play_history.size()).is_greater(0)
```

### 8.3 压力测试

```gdscript
# tests/simulation/test_stress.gd
extends GdUnitTestSuite

func test_100_battles_with_random_seeds() -> void:
    ## 用 100 个随机种子运行战斗，确保无崩溃
    for seed in range(100):
        var config := StageFactory.stage(150, 4, BlindType.Type.SMALL_BLIND)
        var sim := BattleSimulator.new()
        sim.setup(config)

        # 设置种子（如果 Deck 支持）
        if sim.deck.has_method("set_seed"):
            sim.deck.set_seed(seed)

        var turns := 0
        while not sim.is_defeat() and not sim.is_victory() and turns < config.max_turns:
            var best := sim.auto_select_best()
            if best.is_empty():
                break
            sim.play_turn(best)
            turns += 1

        # 验证无崩溃
        assert_that(sim.current_score).is_greater_equal(0)
        assert_that(sim.play_history.size()).is_equal(turns)

    print("100 场随机种子战斗全部完成，无崩溃")


func test_deck_exhaustion_handling() -> void:
    ## 测试牌组抽空的情况
    var config := StageFactory.stage(10000, 10, BlindType.Type.BOSS_BLIND)  # 极高目标
    var sim := BattleSimulator.new()
    sim.setup(config)

    var max_iterations := 20  # 52 张牌最多 10 次出牌（每次用 5 张补 5 张）
    for i in range(max_iterations):
        if sim.is_defeat():
            break
        var best := sim.auto_select_best()
        if best.is_empty():
            break

        # 不应抛出异常
        sim.play_turn(best)

    # 牌组抽空后应能正确处理（依赖 Deck 的弃牌堆洗牌逻辑）
    assert_that(sim.play_history.size()).is_greater(0)
```

---

## 九、人类模拟测试 (Human Simulation)

此类测试的核心思路：**完全模拟人类玩家操作**——加载真实游戏场景，通过 `Input.parse_input_event()` 注入鼠标点击事件，读取 UI 标签文字验证结果。不可 headless 运行（Godot 引擎在 headless 模式下不处理 `InputEvent`），但不需要截图，纯文本验证即可。

### 9.1 HumanTester 类设计

```gdscript
# scripts/testing/human_tester.gd
class_name HumanTester
extends Node

## 人类操作模拟器
## 通过 Input.parse_input_event() 注入真实的鼠标事件，
## 等价于人类在屏幕上点击按钮、选择卡牌。

## 当前加载的游戏场景根节点
var _scene_root: Node

# ═══════════════════════════════════════════════════════════
# 场景管理
# ═══════════════════════════════════════════════════════════

## 加载游戏场景并等待就绪
func load_scene(path: String) -> Node:
    var packed := load(path) as PackedScene
    if not packed:
        push_error("无法加载场景: " + path)
        return null
    _scene_root = packed.instantiate()
    add_child(_scene_root)
    await get_tree().process_frame
    await get_tree().process_frame  # 两帧确保 _ready() 完成
    return _scene_root

## 卸载当前场景
func unload_scene() -> void:
    if _scene_root:
        _scene_root.queue_free()
        _scene_root = null
        await get_tree().process_frame

# ═══════════════════════════════════════════════════════════
# 节点查找
# ═══════════════════════════════════════════════════════════

## 递归查找指定名称的节点
func find_named(name: String) -> Node:
    if not _scene_root:
        return null
    return _scene_root.find_child(name, true, false)

# ═══════════════════════════════════════════════════════════
# 点击操作 (模拟人类鼠标点击)
# ═══════════════════════════════════════════════════════════

## 点击指定名称的 UI 节点 (按钮、卡牌等)
func click_node(node_name: String) -> Dictionary:
    var node := find_named(node_name)
    if not node:
        return _fail("节点未找到: " + node_name)
    if not node is Control:
        return _fail("节点不是 Control: " + node_name)

    var rect := (node as Control).get_global_rect()
    var pos := rect.position + rect.size / 2.0
    _inject_click(pos)
    return {"ok": true}

## 点击手牌中的第 N 张牌 (0-indexed)
func click_card(index: int) -> Dictionary:
    var container := find_named("HandContainer")
    if not container:
        return _fail("HandContainer 未找到")

    var children := container.get_children()
    if index < 0 or index >= children.size():
        return _fail("手牌索引 %d 超出范围 (共 %d 张)" % [index, children.size()])

    var card := children[index]
    if not card is Control:
        return _fail("手牌子节点不是 Control")
    var rect := (card as Control).get_global_rect()
    _inject_click(rect.position + rect.size / 2.0)
    return {"ok": true}

## 核心：注入鼠标点击事件到 Godot 输入系统
func _inject_click(screen_pos: Vector2) -> void:
    Input.warp_mouse(screen_pos)

    # 按下
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_LEFT
    press.position = screen_pos
    press.pressed = true
    Input.parse_input_event(press)

    # 释放 (模拟完整点击)
    var release := InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.position = screen_pos
    release.pressed = false
    Input.parse_input_event(release)

# ═══════════════════════════════════════════════════════════
# 文本读取 (模拟人类"看"屏幕)
# ═══════════════════════════════════════════════════════════

## 读取指定节点的显示文字
func read_text(node_name: String) -> Dictionary:
    var node := find_named(node_name)
    if not node:
        return _fail("节点未找到: " + node_name)
    if node is Label:
        return {"ok": true, "text": (node as Label).text}
    elif node is Button:
        return {"ok": true, "text": (node as Button).text}
    else:
        return _fail("节点不是 Label/Button: " + node_name)

## 验证节点文字包含预期内容
func verify_contains(node_name: String, expected: String) -> Dictionary:
    var result := read_text(node_name)
    if not result.ok:
        result["expected_contains"] = expected
        return result

    var actual: String = result.text
    if expected in actual:
        return {"ok": true, "text": actual}
    return {
        "ok": false,
        "error": "文字不匹配",
        "node": node_name,
        "expected_contains": expected,
        "actual": actual
    }

## 验证节点文字完全匹配
func verify_exact(node_name: String, expected: String) -> Dictionary:
    var result := read_text(node_name)
    if not result.ok:
        return result
    if result.text == expected:
        return {"ok": true, "text": result.text}
    return {
        "ok": false,
        "error": "文字不匹配",
        "node": node_name,
        "expected": expected,
        "actual": result.text
    }

## 读取所有手牌的牌面文字
func read_hand_cards() -> Dictionary:
    var container := find_named("HandContainer")
    if not container:
        return _fail("HandContainer 未找到")

    var cards: Array[String] = []
    for child in container.get_children():
        var rank := child.find_child("RankLabel", true, false)
        var suit := child.find_child("SuitLabel", true, false)
        if rank and suit:
            cards.append(rank.text + suit.text)

    return {"ok": true, "cards": cards}

# ═══════════════════════════════════════════════════════════
# 等待与辅助
# ═══════════════════════════════════════════════════════════

func wait_seconds(t: float) -> void:
    await get_tree().create_timer(t).timeout

func wait_frames(n: int = 1) -> void:
    for i in range(n):
        await get_tree().process_frame

func _fail(msg: String) -> Dictionary:
    return {"ok": false, "error": msg}
```

### 9.2 测试入口 — TestHarness 场景

```gdscript
# scripts/testing/test_harness.gd
extends Node

## 测试入口：自动加载被测场景，逐步执行测试，输出结果

func _ready() -> void:
    var total := 0
    var passed := 0
    var failures: Array[Dictionary] = []

    var tester := HumanTester.new()
    add_child(tester)

    # ── 测试1: 战斗流程 ──────────────────────────────────
    total += 1
    tester.load_scene("res://scenes/battle.tscn")
    await tester.wait_frames(3)

    # 手牌应至少有 5 张
    var hand := tester.read_hand_cards()
    if hand.ok and hand.cards.size() >= 5:
        passed += 1
        print("PASS: 手牌数量检查 (%d 张)" % hand.cards.size())
    else:
        failures.append({
            "test": "手牌数量检查",
            "expected": ">= 5 张",
            "actual": str(hand.get("cards", []) if hand.ok else hand.error)
        })
        print("FAIL: 手牌数量检查")

    # 选两张牌
    tester.click_card(0)
    tester.click_card(1)
    await tester.wait_frames(1)

    # 验证得分预览有显示
    var preview := tester.read_text("ScorePreviewLabel")
    if preview.ok and preview.text.length() > 0 and preview.text != "0 分":
        passed += 1
        print("PASS: 得分预览显示 (%s)" % preview.text)
    else:
        failures.append({
            "test": "得分预览显示",
            "expected": "非空非零",
            "actual": str(preview)
        })
        print("FAIL: 得分预览显示")

    # 点击出牌
    tester.click_node("PlayButton")
    await tester.wait_frames(2)

    # 验证分数已变化
    var score := tester.read_text("CurrentScoreLabel")
    if score.ok:
        passed += 1
        print("PASS: 出牌后分数更新 (%s)" % score.text)
    else:
        failures.append({"test": "出牌后分数更新", "expected": "有显示", "actual": str(score)})
        print("FAIL: 出牌后分数更新")

    # ── 汇总 ─────────────────────────────────────────────
    print("\n===== 测试结果: %d/%d 通过 =====" % [passed, total])
    if not failures.is_empty():
        print("失败详情:")
        for f in failures:
            print("  - %s: 期望=%s, 实际=%s" % [f.test, f.expected, f.actual])
        get_tree().quit(1)  # 非零退出码表示失败
    else:
        print("全部通过 ✓")
        get_tree().quit(0)
```

### 9.3 启动脚本 (外部终端)

```powershell
# run_human_tests.ps1
# 从另一个终端启动 Godot GUI 模式并运行人类模拟测试

$godot = "godot4"  # 或完整路径
$project = "D:\Code\Pack-the-Deck"

Write-Host "启动人类模拟测试..." -ForegroundColor Cyan

$proc = Start-Process -FilePath $godot `
    -ArgumentList "--path `"$project`" res://scripts/testing/test_harness.tscn" `
    -Wait -NoNewWindow -PassThru

if ($proc.ExitCode -eq 0) {
    Write-Host "✓ 所有人类模拟测试通过" -ForegroundColor Green
} else {
    Write-Host "✗ 人类模拟测试失败 (退出码: $($proc.ExitCode))" -ForegroundColor Red
}
exit $proc.ExitCode
```

### 9.4 失败输出格式

每个测试步骤输出以下格式，方便 AI 定位和修复：

```
FAIL: 出牌后分数更新
  步骤: click_node("PlayButton") → read_text("CurrentScoreLabel")
  期望: 非空非零
  实际: {"ok": false, "error": "节点未找到: CurrentScoreLabel"}
  文件: tests/human/test_battle_flow.gd:52
```

AI 从失败输出中可获取：
- 哪个步骤失败了
- 期望值 vs 实际值
- 哪个文件哪一行
- 然后自动修改代码并重新运行直到通过

### 9.5 与 headless 三层的关系

| 层级 | 运行模式 | 速度 | 用途 |
|------|---------|------|------|
| Unit / Integration / Simulation | `--headless` (CI) | 快 (< 30s) | 每次代码变更自动运行 |
| Human Simulation | GUI 模式 (本地) | 慢 (~ 1-2min) | 开发完成后人工或 AI 运行验证 |

Human Simulation 不替代下面三层，而是作为**最终真实验证**——当所有 headless 测试都通过后，再用"真人视角"跑一遍关键游戏流程，确保 UI 交互无问题。

## 十、性能基准测试

```gdscript
# tests/benchmark/test_hand_classifier_perf.gd
extends GdUnitTestSuite

func test_hand_classifier_performance() -> void:
    ## 验证 10000 次牌型判断在 1 秒内完成
    var test_cases := [
        CardFactory.pair(CardData.Rank.FIVE),
        CardFactory.straight(CardData.Rank.TWO),
        CardFactory.flush(),
        CardFactory.full_house(CardData.Rank.KING, CardData.Rank.FIVE),
        CardFactory.four_of_a_kind(CardData.Rank.QUEEN),
        CardFactory.royal_flush(),
    ]

    var iterations := 10000
    var start_time := Time.get_ticks_msec()

    for i in range(iterations):
        for cards in test_cases:
            HandClassifier.evaluate(cards)

    var elapsed := Time.get_ticks_msec() - start_time
    var avg_ms := float(elapsed) / float(iterations * test_cases.size())

    print("牌型判断性能: %d 次 × %d 种 = %.2fms 平均/次" % [
        iterations, test_cases.size(), avg_ms
    ])

    # 断言: 平均每次判断 < 0.05ms (10000 × 6 应在 3000ms 内)
    assert_that(elapsed).is_less(3000)
```

---

## 十一、CI/CD 集成

### 11.1 GitHub Actions 配置

```yaml
# .github/workflows/test.yml
name: Run Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.3  # Godot 4.3 Docker 镜像

    steps:
      - uses: actions/checkout@v4

      - name: Run Unit Tests
        run: |
          godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
            -c run -a res://tests/unit/ \
            --report-dir res://tests/reports/ \
            --report-format xml

      - name: Run Integration Tests
        run: |
          godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
            -c run -a res://tests/integration/ \
            --report-dir res://tests/reports/

      - name: Run Simulation Tests
        run: |
          godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
            -c run -a res://tests/simulation/ \
            --report-dir res://tests/reports/

      - name: Upload Test Reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-reports
          path: tests/reports/

      - name: Test Summary
        if: always()
        run: |
          echo "Tests completed. Check artifacts for detailed reports."
```

### 11.2 本地运行命令

```bash
# === Headless 三层 (CI 可运行) ===

# 运行所有单元测试
godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -c run -a res://tests/unit/

# 运行特定测试目录
godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -c run -a res://tests/integration/

# 运行单个测试文件
godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -c run -a res://tests/unit/systems/test_hand_classifier.gd

# 生成 HTML 报告
godot --headless --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -c run -a res://tests/ --report-format html

# === 人类模拟测试 (GUI 模式，不可 CI) ===

# 从另一个终端启动 (PowerShell)
.\run_human_tests.ps1

# 或直接命令行 (需要 Godot GUI 模式，不可 --headless)
godot --path "." res://scripts/testing/test_harness.tscn

# 在编辑器中运行（需要 GUI）
# 项目 → 工具 → GDUnit4 → 运行所有测试
```

---

## 十二、实施路线图

### 阶段 A：基础设施搭建（优先级 P0）

| 步骤 | 任务 | 预计工作量 | 产出 |
|------|------|-----------|------|
| A.1 | 创建 `tests/fixtures/` 目录和 5 个工厂类 | 1h | CardFactory, EquipmentFactory, StageFactory, HandScenarios, SeedManager |
| A.2 | 创建 `tests/test_suite.gd` 顶层套件 | 0.5h | 聚合入口 |
| A.3 | 配置 GDUnit4 项目设置 | 0.5h | project.godot 配置 |
| A.4 | 验证 `godot --headless` 命令行工作 | 0.5h | 可命令行运行 |

### 阶段 B：现有测试迁移（优先级 P0）

| 步骤 | 任务 | 迁移文件 |
|------|------|---------|
| B.1 | 迁移 test_card_data → unit/card/ | 使用工厂方法重写断言 |
| B.2 | 迁移 test_hand_classifier → unit/systems/ | 使用工厂方法 + 参数化顺子测试 |
| B.3 | 迁移 test_score_calculator → unit/systems/ | 提取 BlindType 测试到独立文件 |
| B.4 | 迁移 test_stage_config → unit/systems/ | 使用 StageFactory |
| B.5 | 迁移 test_rule_modifier → unit/systems/ | 添加优先级覆盖测试 |
| B.6 | 迁移 test_stage_manager → unit/systems/ | 保持逻辑不变，换断言 |
| B.7 | 迁移 test_boss_rules → unit/systems/ | 拆分为 Unit + Integration |

### 阶段 C：新增单元测试（优先级 P1）

| 步骤 | 任务 | 新文件 |
|------|------|--------|
| C.1 | EquipmentData 单元测试 | `unit/equipment/test_equipment_data.gd` |
| C.2 | EquipmentManager 单元测试 | `unit/equipment/test_equipment_manager.gd` |
| C.3 | HandType 单元测试 | `unit/systems/test_hand_type.gd` |
| C.4 | HandManager 单元测试 | `unit/systems/test_hand_manager.gd` |
| C.5 | TurnManager 单元测试 | `unit/systems/test_turn_manager.gd` |
| C.6 | GameManager 单元测试 | `unit/systems/test_game_manager.gd` |
| C.7 | ShopItem/ShopConfig 单元测试 | `unit/systems/test_shop_item.gd` |
| C.8 | ShopManager 单元测试 | `unit/systems/test_shop_manager.gd` |

### 阶段 D：集成测试（优先级 P1）

| 步骤 | 任务 | 新文件 |
|------|------|--------|
| D.1 | 牌型判断 + 规则改写集成 | `integration/test_classifier_with_modifiers.gd` |
| D.2 | 得分 + 装备效果集成 | `integration/test_score_with_equipment.gd` |
| D.3 | 出牌完整管道 | `integration/test_battle_pipeline.gd` |
| D.4 | 商店购买 + 装备放置集成 | `integration/test_shop_pipeline.gd` |
| D.5 | 多装备叠加/冲突 | `integration/test_equipment_interactions.gd` |
| D.6 | Boss 规则端到端 | `integration/test_boss_rules_integration.gd` |

### 阶段 E：模拟测试（优先级 P2）

| 步骤 | 任务 | 新文件 |
|------|------|--------|
| E.1 | 实现 BattleSimulator | `tests/simulation/battle_simulator.gd` |
| E.2 | 完整战斗模拟测试 | `simulation/test_full_battle.gd` |
| E.3 | 战斗→商店→战斗循环 | `simulation/test_game_loop.gd` |
| E.4 | 压力/边界测试 | `simulation/test_stress.gd` |

### 阶段 F：CI/CD 与人类模拟测试（优先级 P2）

| 步骤 | 任务 |
|------|------|
| F.1 | GitHub Actions workflow 配置（headless 三层 CI） |
| F.2 | 性能基准测试 |
| F.3 | 实现 `HumanTester` 类 (`scripts/testing/human_tester.gd`) |
| F.4 | 实现 `TestHarness` 入口场景 |
| F.5 | 编写人类模拟测试场景 (战斗/商店/背包) |
| F.6 | 创建 `run_human_tests.ps1` 启动脚本 |
| F.7 | 集成到 AI 开发循环：测试失败 → 自动分析 → 修复 → 重跑 |

> **注**: 人类模拟测试在 GUI 模式下运行，不入 CI。通过外部 PowerShell 终端启动。

---

## 十三、测试编写约定

### 13.1 命名规范

```
文件命名: test_{module_name}.gd
类命名:   不设 class_name (GDUnit4 自动发现)
函数命名: test_{what}_{condition}()
         例如: test_one_pair_valid, test_one_pair_invalid_different_ranks
```

### 13.2 测试结构 (AAA 模式)

```gdscript
func test_example() -> void:
    # Arrange (准备)
    var cards := CardFactory.pair(CardData.Rank.FIVE)

    # Act (执行)
    var result := HandClassifier.evaluate(cards)

    # Assert (断言)
    assert_that(result.hand_type).is_equal(HandType.Type.ONE_PAIR)
    assert_that(result.multiplier).is_equal(2)
```

### 13.3 每个测试只测一件事

```gdscript
# ❌ 不好：一个测试测多个独立逻辑
func test_hand_classifier() -> void:
    # 测对子 + 测顺子 + 测同花 ...

# ✅ 好：每个测试独立
func test_one_pair_valid() -> void:
func test_one_pair_invalid_different_ranks() -> void:
func test_straight_normal() -> void:
```

### 13.4 测试隔离原则

- 每个测试**独立于**其他测试，不依赖执行顺序
- 使用 `before_test()` / `after_test()` 重置状态
- 不修改全局状态（除非显式在 `after_test()` 中恢复）
- 工厂方法创建全新对象，不共享可变对象

### 13.5 优先测试行为，不测试实现

```gdscript
# ❌ 测试实现细节
func test_internal_array_size() -> void:
    assert_that(hand_manager._hand.size()).is_equal(0)

# ✅ 测试可观察行为
func test_initial_hand_is_empty() -> void:
    assert_that(hand_manager.get_hand().size()).is_equal(0)
```

### 13.6 工厂方法优先

```gdscript
# ❌ 手写构造
var card := CardData.new()
card.rank = CardData.Rank.ACE
card.suit = CardData.Suit.SPADES

# ✅ 工厂方法
var card := CardFactory.card(CardData.Rank.ACE, CardData.Suit.SPADES)
```

---

## 十四、风险与缓解

| 风险 | 影响 | 缓解策略 |
|------|------|---------|
| GDUnit4 与 Godot 4.5 兼容性 | 测试框架不可用 | 锁定 GDUnit4 版本，优先使用 `assert_that` API |
| 现有测试迁移工作量大 | 开发进度延迟 | 分批迁移，旧测试保持可用，新测试用新格式 |
| BattleSimulator 覆盖不全 | 模拟测试不可靠 | 先用简单策略（随机选牌），逐步增加最优策略 |
| Headless 模式不处理 InputEvent | `Input.parse_input_event()` 在 headless 下无效 | HumanTester 必须在 GUI 模式下运行，不入 CI，通过外部 PowerShell 终端启动 |
| UI 节点重命名导致测试断裂 | HumanTester 按名称查找节点失败 | 使用稳定的节点名称，重构时同步更新测试 |
| 工厂方法膨胀 | 维护成本增加 | 严格限定工厂只创建最常用组合，复杂场景在测试内组合 |
| 随机性导致偶发失败 | CI 不稳定 | 使用 SeedManager 固定种子，随机测试独立标记 |

---

## 十五、度量标准

### 测试覆盖目标

| 层级 | 覆盖目标 | 验收标准 |
|------|---------|---------|
| 单元测试 | ≥90% 纯逻辑类 | 每个 public 方法至少 1 个正常 + 1 个边界测试 |
| 集成测试 | 核心流程 100% | 牌型+装备、得分+装备、Boss规则覆盖 |
| 模拟测试 | 所有关卡可完整模拟 | 3 个现有关卡无崩溃通关 |
| 性能测试 | 关键路径基准 | 10000 次牌型判断 < 1s |

### CI 质量门禁

- [ ] 所有单元测试通过 → 允许合并
- [ ] 所有集成测试通过 → 允许合并
- [ ] 模拟测试无崩溃 → 允许合并
- [ ] 无新增的 `push_error` 调用（旧测试迁移后）
- [ ] 新代码必须包含对应测试

---

## 十六、决策确认 (已确认)

### 测试框架整体决策

| 问题 | 确认结果 | 实施指令 |
|------|---------|---------|
| Q1: 迁移策略 | **直接替换** | 旧测试文件删除，全部迁移为 GDUnit4 格式 |
| Q2: GDUnit4 兼容性 | **已验证兼容** | GDUnit4 v6.1.2 + Godot 4.5，插件 `plugin.gd` 行35 检查 `>= 0x40500` |
| Q3: Deck 随机种子 | **无需改 Deck** | 使用全局 `seed(fixed_int)` 在 BattleSimulator.setup() 中固定随机性 |
| Q4: 自动选牌策略 | **贪心算法** | `auto_select_best()` 穷举所有 1-5 张组合，选得分最高者 |

### 人类模拟测试决策

| 问题 | 确认结果 | 实施指令 |
|------|---------|---------|
| H1: 嵌入方式 | **独立 TestHarness 场景** | 加载游戏场景为子节点，不修改源码 |
| H2: 测试编写 | **GDScript 函数** | 直接调用 HumanTester API，最灵活 |
| H3: 失败处理 | **立即停止 + 自动分析修复** | 失败时打印期望/实际差异，AI 自动修复后重跑直到通过 |
| H4: 截图 | **不需要** | 纯文本验证（read_text / verify_contains） |
| H5: 运行方式 | **Godot 单进程驱动** | 所有测试逻辑在 Godot 内部，外部 PowerShell 仅启动 |
| H6: 测试内容 | **关键流程覆盖** | 战斗流程、商店流程、背包交互 — 非穷举所有 UI 细节 |

---

## 十七、可行性验证报告

> 本章记录对设计方案中所有 API 调用的逐项验证结果。

### 验证环境

| 组件 | 版本 |
|------|------|
| Godot | 4.5 (project.godot → `config/features=PackedStringArray("4.5", "Forward Plus")`) |
| GDUnit4 | 6.1.2 (`addons/gdUnit4/plugin.cfg`) |
| 兼容性检查 | `plugin.gd` line 35: `Engine.get_version_info().hex >= 0x40500` ✓ |

### API 逐项验证

| 设计中的调用 | 实际 API | 状态 |
|------------|---------|------|
| `extends GdUnitTestSuite` | `class_name GdUnitTestSuite extends Node` (文件: `src/GdUnitTestSuite.gd`) | ✅ |
| `assert_that(value).is_equal(x)` | `GdUnitTestSuite.assert_that()` → auto-dispatches to typed assert (文件: line 582) | ✅ |
| `assert_that(result.hand_type).is_equal(...)` | enum 值自动分派到 `GdUnitIntAssert` (GDScript enum = int) | ✅ |
| `scene_runner("res://scenes/battle.tscn")` | `GdUnitTestSuite.scene_runner()` → `GdUnitSceneRunner` (文件: line 241) | ✅ |
| `_runner.simulate_mouse_button_pressed(...)` | `GdUnitSceneRunner.simulate_mouse_button_pressed()` | ✅ |
| `EquipmentFactory.straight_lens(4)` → `effect_params` 被 `RuleModifier` 解析 | `RuleModifier.add_equipment_rules()` 检查键 `"straight_min_cards"`、`"hand_type_multiplier"` 等 (文件: line 131-184) | ✅ (已修正) |
| `ScoreCalculator.calculate_score_with_modifiers(r, b, dict)` | 接受 `Dictionary`，键: `"score_bonus"`(int) + `"multiplier_bonus"`(float) (文件: line 21-42) | ✅ |
| `EffectTrigger.new(equipment_manager)` | `_init(manager: EquipmentManager = null)` (文件: line 99) | ✅ (已修正顺序) |
| `effect_trigger.trigger_score_effects(...)` → `Array[EffectResult]` | 返回 `Array[EffectResult]`，含 `.score_bonus` + `.multiplier_bonus` (文件: line 327) | ✅ (已修正转换) |
| `seed(fixed_int)` + `Deck.shuffle()` | Godot 全局 `seed()` → `Array.shuffle()` 使用全局 RNG | ✅ |
| GDUnit4 CLI: `godot --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/` | `GdUnitCmdTool.gd extends SceneTree` (文件: `bin/GdUnitCmdTool.gd`) | ✅ |
| `Deck.draw_cards()` 在牌组空时洗入弃牌堆 | `draw_card()` → `_reshuffle_discard()` (文件: line 53-62) | ✅ |

### 已修正的设计错误

| # | 位置 | 错误 | 修正 |
|---|------|------|------|
| 1 | EquipmentFactory.straight_lens | `effect_params = {"modify_type": ..., "value": 4}` | `{"straight_min_cards": 4}` |
| 2 | EquipmentFactory.multiplier_mod | `effect_params = {"modify_type": ..., "hand_type": ..., "value": ...}` | `{"hand_type_multiplier": true, "target_hand_type": int(hand_type), "multiplier_factor": float(multiplier)}` |
| 3 | BattleSimulator.setup | `EffectTrigger.new()` (无参数) | `EffectTrigger.new(equipment_manager)` + 调整创建顺序 |
| 4 | BattleSimulator.play_turn | `calculate_score_with_modifiers(..., score_effects.get("modifiers", []))` | 遍历 `Array[EffectResult]` 转换为 `Dictionary` |
| 5 | BattleSimulator.setup | `d.set_seed(seed)` (Deck 无此方法) | `seed(seed_val)` 全局调用 |
| 6 | UI 测试 | `simulate_mouse_button_press()` | `simulate_mouse_button_pressed()` |
| 7 | 集成测试 | `calculate_score_with_modifiers(..., [{"score_bonus": 20}])` | `calculate_score_with_modifiers(..., {"score_bonus": 20})` |

### HumanTester API 验证

| 设计中的调用 | 实际 API | 状态 |
|------------|---------|------|
| `Input.parse_input_event(event)` | GdUnitSceneRunnerImpl 第 570 行，注入 InputEvent 到引擎 | ✅ (GUI 模式) / ❌ (headless 无效) |
| `Input.warp_mouse(pos)` | GdUnitSceneRunnerImpl 第 569 行，移动鼠标位置 | ✅ |
| `node.get_global_rect()` | Godot Control 节点标准 API，返回屏幕矩形 | ✅ |
| `scene.find_child("PlayButton", true, false)` | Godot Node 标准 API，递归查找子节点 | ✅ |
| `label.text` / `button.text` | Godot Label/Button 标准属性 | ✅ |
| `get_tree().quit(exit_code)` | Godot SceneTree 标准 API，设置进程退出码 | ✅ |
| `--path "project_dir" scene.tscn` | Godot CLI 标准调用方式 | ✅ |
| 7 | 集成测试 | `calculate_score_with_modifiers(..., [{"score_bonus": 20}])` | `calculate_score_with_modifiers(..., {"score_bonus": 20})` |

---

**文档版本**: v1.1
**创建日期**: 2026-05-13
**作者**: Sisyphus (AI)
**状态**: 可行性已验证 ✓ — 等待实施
