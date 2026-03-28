# 开发进度记录

> 记录项目开发过程中完成的关键里程碑

---

## 当前状态

**当前阶段**: 阶段二（牌型判断系统）- ✅ 完成

**下一阶段**: 阶段三（得分计算系统）

---

## 完成记录

### 2025-03-28 - 阶段二：牌型判断系统

#### 步骤 2.1：实现牌型类型枚举 ✅
- [x] 创建 HandType 类 (scripts/systems/hand_type.gd)
- [x] 定义牌型枚举 Type（HIGH_CARD 到 ROYAL_FLUSH）
- [x] 定义牌型倍率映射（1-100）
- [x] 定义牌型显示名称（中英文）
- [x] 创建 HandResult 结果类

#### 步骤 2.2-2.11：实现牌型判断逻辑 ✅
- [x] 创建 HandClassifier 类 (scripts/systems/hand_classifier.gd)
- [x] 实现 evaluate() 统一入口方法
- [x] 实现对子判断（2张相同牌面值）
- [x] 实现两对判断（4张，2组对子）
- [x] 实现三条判断（3张相同牌面值）
- [x] 实现顺子判断（5张连续，A可作1或14）
- [x] 实现同花判断（5张相同花色）
- [x] 实现葫芦判断（3+2共5张）
- [x] 实现四条判断（4张相同牌面值）
- [x] 实现同花顺判断（顺子+同花）
- [x] 实现皇家同花顺判断（10-J-Q-K-A同花）
- [x] 创建测试文件 (tests/test_hand_classifier.gd)

#### 文档更新 ✅
- [x] 更新 architecture.md - 记录牌型系统结构
- [x] 更新 progress.md - 本文件

---

### 2025-03-26 - 阶段一：项目骨架与数据结构

#### 步骤 1.1：创建 Godot 项目与基础目录 ✅
- [x] 初始化 Godot 4.3 项目
- [x] 创建目录结构：scenes/, scripts/, resources/, assets/, addons/, tests/
- [x] 创建 project.godot 配置文件
- [x] 创建 .gitignore 文件
- [x] 创建基础主场景 (main.tscn) 和脚本 (main.gd)
- [x] 创建项目图标 (icon.svg)

#### 步骤 1.2：定义卡牌数据结构 ✅
- [x] 创建 CardData 类 (scripts/card/card_data.gd)
- [x] 定义 Suit 枚举（SPADES, HEARTS, DIAMONDS, CLUBS）
- [x] 定义 Rank 枚举（TWO 到 ACE）
- [x] 实现基础分数计算（数字牌=面值，J/Q/K=10，A=11）
- [x] 实现显示方法（get_rank_display, get_suit_display, get_suit_color）
- [x] 实现排序方法（sort_by_rank_desc）
- [x] 创建 Deck 类 (scripts/card/deck.gd) - 52 张牌管理
- [x] 创建 DeckGenerator 工具类 - 生成卡牌资源
- [x] 创建测试文件 (tests/test_card_data.gd)

#### 步骤 1.3：定义装备数据结构 ✅
- [x] 创建 EquipmentData 类 (scripts/equipment/equipment_data.gd)
- [x] 定义 Category 枚举（OPTICAL, MECHANICAL, MAGICAL, GENERIC）
- [x] 定义 EffectType 枚举（RULE_MODIFY, STRUCTURE, RESOURCE, SCORE_MODIFY）
- [x] 定义 TriggerTiming 枚举（触发时机）
- [x] 实现形状系统（shape: Array[Vector2i]）
- [x] 实现效果参数系统（effect_params: Dictionary）
- [x] 创建 EquipmentManager 类 (scripts/equipment/equipment_manager.gd)
- [x] 创建 3 个测试装备资源：
  - [x] lucky_coin.tres - 幸运硬币（1×1，每回合+1金币）
  - [x] perfect_lens.tres - 完美镜片（1×1，顺子只需4张）
  - [x] reinforced_anvil.tres - 强化铁砧（2×2，相邻联动）

#### 文档更新 ✅
- [x] 更新 implementation-plan.md - 添加设计决策记录
- [x] 更新 architecture.md - 记录文件结构和职责
- [x] 创建 progress.md - 本文件

---

## 待办事项

### 阶段三：得分计算系统（下一步）
- [ ] 步骤 3.1：实现基础分数计算
- [ ] 步骤 3.2：实现盲注倍率系统
- [ ] 步骤 3.3：实现目标分数与过关判定

---

## 设计决策记录

### 2025-03-26 - 初始设计决策

| 决策项 | 结论 |
|--------|------|
| 牌型选择模式 | 玩家手动选牌（最多选 5 张） |
| 盲注倍率含义 | 目标分数门槛提高，奖励提高 |
| Boss 特殊规则 | 某些花色不计分、某些牌型不计分、出牌数量限制等 |
| 装备形状旋转 | MVP 阶段不需要 |
| 规则改写实现 | 规则栈叠加 |
| 装备冲突规则 | 同类装备不能同时装备 |
| 牌组规模 | 标准 52 张，动态管理 |
| 商店系统 | MVP 包含 |
| 卡牌视觉 | 占位符 + 花色符号 |

---

**文档版本**: v1.0  
**最后更新**: 2025-03-26