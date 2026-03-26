# 技术栈推荐文档

## 一、核心推荐

### 推荐技术栈：Godot 4 + GDScript

| 组件 | 推荐方案 | 理由 |
|------|---------|------|
| **游戏引擎** | Godot 4.x | 开源免费、2D原生支持、学习曲线平缓 |
| **编程语言** | GDScript | Python风格语法、热重载、社区主流 |
| **卡牌系统** | Card Framework 插件 | 成熟的卡牌游戏框架 |
| **背包系统** | GridContainer + 自定义拖拽 | 原生支持、灵活可控 |
| **发布平台** | Steam (Windows) | Godot 原生导出支持 |

---

## 二、游戏引擎对比分析

### Godot 4.x — 最佳选择 ⭐

| 评估维度 | 评分 | 说明 |
|---------|------|------|
| **许可证** | ⭐⭐⭐⭐⭐ | 完全开源免费，无版税风险 |
| **2D支持** | ⭐⭐⭐⭐⭐ | 原生2D引擎，非3D改编 |
| **学习曲线** | ⭐⭐⭐⭐⭐ | 对零基础开发者最友好 |
| **卡牌游戏生态** | ⭐⭐⭐⭐ | 有成熟的卡牌框架插件 |
| **社区支持** | ⭐⭐⭐⭐ | 快速增长，教程丰富 |

**核心优势：**
- ✅ 永久免费，无定价争议风险（对比Unity的定价风波）
- ✅ 轻量级引擎，适合每天2小时开发节奏
- ✅ 原生2D支持，专为2D游戏设计
- ✅ GDScript语法简洁，类似Python
- ✅ 热重载功能，无需编译等待

**成功案例：**
- **Brotato** (2022) — Godot开发的Roguelike，销量百万+

---

### Unity — 备选方案

| 评估维度 | 评分 | 说明 |
|---------|------|------|
| **许可证** | ⭐⭐⭐ | 个人版免费（收入<$100K），但有定价争议史 |
| **2D支持** | ⭐⭐⭐⭐ | 良好，需配合2D Toolkit |
| **学习曲线** | ⭐⭐⭐ | 中等，C#需要一定基础 |
| **卡牌游戏生态** | ⭐⭐⭐⭐⭐ | Asset Store有完整卡牌游戏模板 |
| **社区支持** | ⭐⭐⭐⭐⭐ | 行业标准，资源最多 |

**核心优势：**
- ✅ Asset Store 有成熟的卡牌游戏模板（$99可买完整TCG引擎）
- ✅ 行业标准，Hearthstone、MTG Arena均用Unity开发
- ✅ C#生态成熟，适合大型项目

**核心劣势：**
- ❌ 引擎较重，迭代速度慢于Godot
- ❌ 近期定价争议影响独立开发者信任
- ❌ 学习曲线较陡峭

---

### GameMaker — 快速原型选择

| 评估维度 | 评分 | 说明 |
|---------|------|------|
| **许可证** | ⭐⭐⭐⭐ | 免费版功能有限，付费版$99/年 |
| **2D支持** | ⭐⭐⭐⭐⭐ | 纯2D引擎，极致优化 |
| **学习曲线** | ⭐⭐⭐⭐⭐ | 拖拽式开发+简单脚本 |
| **卡牌游戏生态** | ⭐⭐⭐ | 社区较小，资源有限 |
| **社区支持** | ⭐⭐⭐ | 社区小于Godot/Unity |

**适用场景：**
- 极速原型开发
- 对编程要求最低
- 不需要复杂系统

**不适合本项目原因：**
- 构筑系统复杂度高，GameMaker扩展性不足
- 社区资源少于Godot/Unity

---

### 不推荐引擎

| 引擎 | 不推荐原因 |
|------|-----------|
| **Unreal Engine** | 对2D卡牌游戏过于重型，学习曲线极陡 |
| **Bevy** | 虽然Rust生态，但对初学者不友好 |
| **libGDX** | Java生态，配置繁琐，不适合快速开发 |

---

## 三、编程语言选择

### GDScript — 首选推荐

```gdscript
# 示例：卡牌数据定义
class_name CardData
extends Resource

@export var card_name: String = ""
@export var mana_cost: int = 1
@export var description: String = ""
@export var effects: Array[Effect] = []
```

**选择理由：**
- ✅ **语法简洁** — 类Python语法，可读性极高
- ✅ **社区主流** — 84% Godot开发者使用GDScript
- ✅ **热重载** — 无需编译，改代码立即生效
- ✅ **教程丰富** — 大部分Godot教程使用GDScript
- ✅ **学习曲线平缓** — 适合零基础开发者

**性能对比：**

| 语言 | 执行速度 | 学习曲线 | 最佳用途 |
|------|---------|---------|---------|
| **GDScript** | 中等 | 最简单 | 初学者、原型开发 |
| **C#** | 快（3-5倍） | 中等 | 大型项目、性能关键 |
| **Lua** | 快 | 简单 | 移动端优先 |

**本项目选择GDScript理由：**
- 6个月开发周期，学习成本是关键因素
- 卡牌游戏为回合制，非实时，性能要求不高
- 规则系统为主，GDScript完全够用

---

### C# — 备选方案

**适用情况：**
- 已有C#编程经验
- 需要高性能计算（复杂AI、大量物理模拟）
- 项目规模扩大后重构

**本项目不首选原因：**
- 学习曲线陡峭，增加开发成本
- Godot的C#支持不如GDScript成熟
- 对卡牌游戏而言性能冗余

---

## 四、专用工具与库

### 卡牌游戏框架

#### Godot Card Framework

| 属性 | 详情 |
|------|------|
| **项目地址** | [GitHub - card-framework](https://github.com/chun92/card-framework) |
| **Star数** | 303+ |
| **维护状态** | 活跃维护 |
| **许可证** | 开源免费 |

**功能特性：**
- ✅ 完整的牌组构建系统
- ✅ 卡牌拖拽、出牌动画
- ✅ 手牌管理
- ✅ 回合系统
- ✅ 效果触发系统

**学习资源：**
- [SlashSkill教程](https://www.slashskill.com/how-to-build-a-card-game-in-godot-4-deckbuilder-systems-from-scratch/) — 完整的卡组构建器教程
- GDQuest免费视频教程

---

#### Unity TCG Engine（备选）

| 属性 | 详情 |
|------|------|
| **价格** | $99 |
| **功能** | 完整Roguelike卡牌构建器 |
| **包含** | 地图生成、存档系统、卡牌系统 |

**适合情况：**
- 选择Unity引擎
- 预算允许购买资产
- 想快速搭建原型

---

### 背包/网格库存系统

#### Godot实现方案

```gdscript
# GridContainer 背包系统核心代码示例
extends GridContainer

var slots: Array[InventorySlot] = []
const GRID_SIZE = 20  # 5x4网格

func _ready():
    columns = 4  # 4列布局
    for i in range(GRID_SIZE):
        var slot = InventorySlot.new()
        slots.append(slot)
        add_child(slot)

# 装备拖拽放置逻辑
func place_equipment(equipment: Equipment, slot_index: int) -> bool:
    if can_place(equipment, slot_index):
        slots[slot_index].set_equipment(equipment)
        return true
    return false

# 冲突检测（不同形状装备）
func can_place(equipment: Equipment, slot_index: int) -> bool:
    # 检查空间占用和装备类型冲突
    return true
```

**实现要点：**
1. **GridContainer** — 原生网格布局容器
2. **拖拽系统** — Godot内置`_get_drag_data`、`_can_drop_data`、`_drop_data`
3. **形状系统** — 不同装备占用不同格数（1x1, 1x2, 2x2等）
4. **冲突检测** — 检查装备类型是否兼容

**参考资源：**
- [Godot Inventory System Tutorial](https://godotengine.org/article/introduction-godot-ui-system/)
- [Grid-based Inventory Design Patterns](https://github.com/topics/inventory-system)

---

## 五、开发最佳实践（2024-2025）

### 架构设计模式

#### 1. 数据驱动架构

**核心思想：** 卡牌定义为数据，而非硬编码

```json
// cards/fireball.json
{
  "id": "fireball",
  "name": "火球术",
  "cost": 2,
  "type": "spell",
  "effects": [
    {"type": "damage", "value": 6},
    {"type": "aoe", "radius": 1}
  ],
  "description": "造成6点伤害，范围内敌人各受3点伤害"
}
```

**优势：**
- 无需改代码即可添加新卡牌
- 方便平衡调整
- 支持热更新内容

---

#### 2. 状态机模式

**游戏流程状态：**
```
TITLE → MAP → BATTLE → REWARD → MAP → ... → VICTORY/DEFEAT
```

```gdscript
# 游戏状态机示例
enum GameState {TITLE, MAP, BATTLE, REWARD, GAME_OVER}
var current_state: GameState

func change_state(new_state: GameState):
    exit_state(current_state)
    current_state = new_state
    enter_state(new_state)
```

**优势：**
- 避免复杂if-else嵌套
- 状态转换逻辑清晰
- 易于调试和扩展

---

#### 3. 设计模式应用

| 模式 | 应用场景 | 收益 |
|------|---------|------|
| **命令模式** | 卡牌效果、撤销/重做 | 可撤销操作、效果队列 |
| **对象池** | 卡牌特效、粒子系统 | 性能优化，减少GC |
| **事件总线** | 系统间通信 | 松耦合，易维护 |

```gdscript
# 事件总线示例
extends Node

signal card_played(card: Card)
signal equipment_equipped(equipment: Equipment)
signal turn_started()
signal turn_ended()
```

---

### 开发流程建议

#### 6个月开发计划拆解

| 阶段 | 时长 | 目标 | 关键产出 |
|------|------|------|---------|
| **原型阶段** | 1个月 | 可玩战斗循环 | 基础出牌、得分系统 |
| **核心系统** | 2个月 | 牌组构建、背包、地图 | 完整玩法框架 |
| **内容填充** | 2个月 | 卡牌、敌人、物品 | 30张卡、8个Boss |
| **打磨发布** | 1个月 | UI、音效、平衡 | 可发布版本 |

---

### 成功独立游戏案例参考

| 游戏 | 引擎 | 语言 | 发行年 | 启示 |
|------|------|------|--------|------|
| **Slay the Spire** | libGDX | Java | 2019 | Roguelike卡牌构建可行性验证 |
| **Balatro** | LÖVE | Lua | 2024 | 扑克题材可以成功 |
| **Brotato** | Godot | GDScript | 2022 | Godot适合Roguelike |

**关键启示：**
- 引擎选择不如设计质量重要
- 小团队可以用任何主流引擎成功
- 玩法深度 > 图形表现

---

## 六、技术栈配置建议

### 开发环境配置

```
项目结构建议：
Pack-the-Deck/
├── scenes/           # 场景文件
│   ├── battle.tscn
│   ├── shop.tscn
│   └── inventory.tscn
├── scripts/          # GDScript脚本
│   ├── card/
│   ├── equipment/
│   └── systems/
├── resources/        # 数据资源
│   ├── cards/
│   └── equipment/
├── assets/           # 美术资源
│   ├── sprites/
│   └── audio/
└── addons/           # 插件
    └── card_framework/
```

---

### Git版本控制策略

```bash
# .gitignore 关键项
.import/
*.import
export/
.mono/
```

**提交策略：**
- 每完成一个可玩功能点提交一次
- 使用语义化提交信息
- 每周打标签备份

---

### 测试与调试

**Godot内置工具：**
- **Remote Debugger** — 实时变量监控
- **Profiler** — 性能分析
- **Unit Testing** — GDUnit4插件

**测试优先级：**
1. 牌型判断逻辑
2. 装备规则改写
3. 背包空间冲突
4. 存档/读档

---

## 七、风险与缓解策略

### 技术风险

| 风险 | 影响 | 缓解策略 |
|------|------|---------|
| **Godot版本升级** | API变化破坏项目 | 锁定Godot 4.x版本，不频繁升级 |
| **插件停止维护** | 依赖的插件失效 | 选择活跃维护的开源插件，保留自己修改能力 |
| **性能瓶颈** | 大量卡牌时卡顿 | 使用对象池，优化数据结构 |

---

### 学习曲线风险

| 风险 | 影响 | 缓解策略 |
|------|------|---------|
| **GDScript学习成本** | 前1-2周效率低 | 先做官方教程项目，边学边做 |
| **游戏开发概念陌生** | 场景、节点理解困难 | 观看GDQuest基础教程系列 |
| **调试困难** | 逻辑错误难定位 | 学会使用Godot调试器，打印日志 |

---

## 八、最终推荐总结

### 推荐技术栈组合

```
┌─────────────────────────────────────┐
│  Godot 4.3 LTS (稳定版)              │
│  + GDScript 2.0                      │
│  + Card Framework 插件               │
│  + Git 版本控制                      │
└─────────────────────────────────────┘
```

### 为什么这是最佳选择

| 约束条件 | Godot方案契合度 |
|---------|---------------|
| 零基础开发者 | ⭐⭐⭐⭐⭐ GDScript最易学 |
| 每天2小时开发 | ⭐⭐⭐⭐⭐ 热重载、快速迭代 |
| 6个月周期 | ⭐⭐⭐⭐⭐ 学习+开发刚好够用 |
| 专注逻辑而非美术 | ⭐⭐⭐⭐⭐ 2D原生支持，UI系统完善 |
| PC/Steam发布 | ⭐⭐⭐⭐⭐ 原生导出支持 |
| 预算有限 | ⭐⭐⭐⭐⭐ 完全免费，无版税 |

---

## 九、后续行动建议

### 第一步：环境准备（1-2天）
1. 下载安装 Godot 4.3 LTS
2. 完成 GDQuest "Your First 2D Game" 教程
3. 熟悉 Godot 编辑器界面

### 第二步：原型开发（1个月）
1. 创建项目结构
2. 实现基础卡牌显示
3. 实现简单出牌逻辑
4. 完成可玩原型

### 第三步：集成框架（2-4周）
1. 集成 Card Framework 插件
2. 改造适配项目需求
3. 实现背包网格系统

---

**技术栈选择的本质：** 不是选"最强"的工具，而是选"最适合"的工具。

对于本项目的约束条件（零基础、有限时间、逻辑驱动、独立开发），**Godot 4 + GDScript** 提供了最佳的学习曲线、开发速度和长期可行性的平衡。开源属性消除了许可风险，活跃的社区确保了持续支持。