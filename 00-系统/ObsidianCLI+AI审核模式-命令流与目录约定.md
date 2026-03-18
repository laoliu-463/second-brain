# Obsidian CLI + AI 审核模式：命令流与目录约定

本文档定义「收件箱写作 → AI 审核整理 → CLI 执行 → 正式落库 → GitHub 管理」的完整执行流。

配套架构图：`00-系统/工具调用架构图与分阶段职责图.md`

核心原则：
- **AI 负责"判断怎么执行"**
- **CLI 负责"对库执行动作"**
- CLI 只做执行，不做自由判断

---

## 一、CLI 在系统中的定位

### 1.1 分层架构

```
┌─────────────────────────────────────────────────────┐
│ 第1层：用户输入层                                    │
│  - 在 01-收件箱 用模板写内容                         │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ 第2层：AI 决策层                                    │
│  - 读取收件箱笔记 + 规则文件                         │
│  - 输出审核结果（类型/目录/frontmatter/动作）        │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ 第3层：CLI 执行层                                    │
│  - 搜索/创建/追加/打开                                │
│  - 仅执行低风险动作                                   │
│  - 不做自由判断                                      │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ 第4层：GitHub 管理层                                 │
│  - 分三次提交记录过程                                │
└─────────────────────────────────────────────────────┘
```

### 1.2 CLI 四类核心能力

| 类别 | 说明 | 示例 |
|------|------|------|
| 检索 | 搜索 vault 中是否存在目标笔记 | 搜索是否已有 `[[项目-第二大脑搭建]]` |
| 创建与追加 | 创建新笔记或向已有笔记追加内容 | 创建正式笔记、写入整理结果 |
| 打开与跳转 | 打开指定笔记供人工确认 | 打开今日日记、打开待审核笔记 |
| 外部集成 | 配合 shell/Python/AI 工作流 | 读取 AI 输出并调用 CLI 执行 |

---

## 二、CLI 命令清单

### 2.1 基础命令（官方 CLI）

> 基于 Obsidian CLI 官方能力，具体命令需以 `obsidian help` 输出为准。

| 命令 | 用途 | 风险等级 |
|------|------|----------|
| `obsidian search <query>` | 搜索 vault 中是否存在目标笔记 | 低 |
| `obsidian open` | 打开 Obsidian 应用 | 低 |
| `obsidian open <vault>` | 打开指定 vault | 低 |
| `obsidian open <path>` | 打开指定笔记 | 低 |
| `obsidian open daily` | 打开今日日记 | 低 |

> **注意**：官方 CLI 仍在发展中，不同版本命令可能有差异。本文档使用"动作级抽象"，由脚本层适配。

### 2.2 动作抽象层（脚本封装）

实际使用中建议封装为以下动作：

```powershell
# 搜索目标笔记
./obsidian-review-flow.ps1 -Action search -Query "项目-第二大脑搭建"

# 打开今日日记
./obsidian-review-flow.ps1 -Action open_daily

# 追加内容到今日日记
./obsidian-review-flow.ps1 -Action daily_append -Content "- [ ] 审核：xxx"

# 创建正式笔记草稿
./obsidian-review-flow.ps1 -Action create -Path "03-项目/进行中/项目-xxx.md" -Content $content

# 打开指定笔记
./obsidian-review-flow.ps1 -Action open -Path "03-项目/进行中/项目-xxx.md"

# 追加内容到指定笔记
./obsidian-review-flow.ps1 -Action append -Path "03-项目/进行中/项目-xxx.md" -Content $content
```

### 2.3 回退方案

若官方 CLI 不可用：

| 场景 | 回退方案 |
|------|----------|
| 搜索 | `rg --files` 或 Grep 工具 |
| 创建/追加 | 直接文件写入 |
| 打开笔记 | `obsidian://open?vault=<vault>&file=<path>` URI |
| 打开日记 | `obsidian://daily?vault=<vault>` URI |

---

## 三、目录约定

### 3.1 基础目录结构

```
my-second-brain/
├─ 00-系统/                 # 规则文件与脚本
│  ├─ AI整理规则.md
│  ├─ 整理检查清单.md
│  ├─ 审核模式输出格式.md
│  ├─ 正确性校验规则.md
│  └─ scripts/
│     └─ obsidian-review-flow.ps1  # CLI 封装脚本
├─ 01-收件箱/               # 收件箱笔记
├─ 02-日记/                 # 按年/月组织
│  └─ 2026/
│     └─ 2026-03/
├─ 03-项目/                 # 项目笔记
│  ├─ 进行中/
│  ├─ 已暂停/
│  └─ 已完成/
├─ 04-领域/                 # 责任领域
├─ 05-资源/                 # 资源与阅读
│  ├─ 阅读/
│  └─ 资料/
├─ 06-永久笔记/             # 永久笔记
├─ 07-索引/                 # MOC 导航页
├─ 08-归档/                 # 归档笔记
├─ 90-System/               # 系统配置
│  ├─ templates/           # 笔记模板
│  └─ test-samples/        # 测试样例
└─ .obsidian/              # Obsidian 配置
```

### 3.2 CLI 临时文件目录

CLI 执行过程中可能产生的临时文件：

```
00-系统/
├─ scripts/
├─ temp/                   # 临时文件（不纳入 Git）
│  ├─ ai-output.json      # AI 审核输出（JSON）
│  ├─ draft-xxx.md       # 临时草稿
│  └─ confirm-queue.md   # 待确认队列
└─ logs/
   └─ cli-execution.log   # 执行日志
```

---

## 四、最实用的 5 个 CLI 场景

### 场景 1：打开今日日记

**用途**：每天工作入口、记录整理日志、追加待审核清单

```powershell
# 打开今日日记
./obsidian-review-flow.ps1 -Action open_daily

# 追加一条整理日志
./obsidian-review-flow.ps1 -Action daily_append -Content "## 2026-03-18 整理记录

- 收件箱：2 篇
- 已审核：1 篇
- 待确认：1 篇"
```

### 场景 2：搜索目标笔记

**用途**：避免重复建笔记、查重、确认目标笔记是否存在

```powershell
# 搜索项目笔记是否存在
./obsidian-review-flow.ps1 -Action search -Query "项目-第二大脑搭建"

# 搜索主题 MOC 是否存在
./obsidian-review-flow.ps1 -Action search -Query "MOC-知识管理"

# 搜索是否已有某永久笔记
./obsidian-review-flow.ps1 -Action search -Query "Obsidian-GitHub同步"
```

### 场景 3：向日记追加内容

**用途**：自动记录整理日志、追加待审核清单、记录新增正式笔记

```powershell
# 追加待审核清单
./obsidian-review-flow.ps1 -Action daily_append -Content "
- [ ] 审核：项目-第二大脑搭建（目录移动待确认）
- [ ] 审核：阅读-AI Agents（待补充来源）"

# 追加已完成记录
./obsidian-review-flow.ps1 -Action daily_append -Content "
- [x] 已执行：创建 03-项目/进行中/项目-xxx.md 草稿"
```

### 场景 4：创建正式笔记草稿

**用途**：从收件箱转正时生成正式笔记骨架

```powershell
# 创建项目笔记草稿
$content = @"
---
title: "项目-第二大脑搭建"
type: project
status: active
created: 2026-03-18
updated: 2026-03-18
source_note: "01-收件箱/2026-03-18 xxx.md"
---

# 项目-第二大脑搭建

> 项目目标：建立人写 AI 整理的自动化知识管理流程

## 项目进展

（待补充）

## 待办

- [ ]

## 相关笔记

- [[]]

## 参考资料

（无外部来源）

---

*来源笔记：01-收件箱/2026-03-18 xxx.md*
"@

./obsidian-review-flow.ps1 -Action create -Path "03-项目/进行中/项目-第二大脑搭建.md" -Content $content
```

### 场景 5：打开目标笔记进行人工审核

**用途**：AI 输出审核结果后，一键跳转到目标笔记确认

```powershell
# 打开待审核的正式草稿
./obsidian-review-flow.ps1 -Action open -Path "03-项目/进行中/项目-第二大脑搭建.md"

# 打开源收件箱笔记
./obsidian-review-flow.ps1 -Action open -Path "01-收件箱/2026-03-18 xxx.md"

# 打开今日日记
./obsidian-review-flow.ps1 -Action open_daily
```

---

## 五、AI 输出到 CLI 命令的映射

### 5.1 AI 审核输出结构

AI 按《审核模式输出格式》输出结果，结构化后示例：

```json
{
  "review_result": {
    "mode": "review",
    "source_note": "01-收件箱/2026-03-18 第二大脑目录规则.md",
    "type": "project",
    "target_directory": "03-项目/进行中/",
    "target_filename": "项目-第二大脑搭建.md",
    "target_exists": true,
    "existing_note": "03-项目/进行中/项目-第二大脑搭建.md"
  },
  "actions": {
    "auto_executed": [
      {"action": "format_optimize", "status": "done"},
      {"action": "frontmatter_min", "status": "done"},
      {"action": "create_draft", "status": "done"}
    ],
    "pending_confirmation": [
      {"action": "move_to_target", "target": "03-项目/进行中/项目-第二大脑搭建.md"},
      {"action": "update_existing_note", "target": "03-项目/进行中/项目-第二大脑搭建.md"},
      {"action": "insert_body_link", "link": "[[MOC-知识管理]]"}
    ],
    "suggestions_only": [
      {"action": "create_link", "link": "[[MOC-AI工程]]", "reason": "候选链接"}
    ]
  },
  "links": {
    "confirmed": ["[[项目-第二大脑搭建]]"],
    "candidates": ["[[MOC-知识管理]]"]
  },
  "references": {
    "external": [],
    "internal_source": "01-收件箱/2026-03-18 第二大脑目录规则.md"
  },
  "risk_level": "medium"
}
```

### 5.2 动作到 CLI 命令的映射

| AI 输出动作 | CLI 命令 | 风险 | 执行策略 |
|-------------|---------|------|----------|
| `search_target` | `search` | 低 | 自动执行 |
| `create_draft` | `create` | 低 | 自动执行 |
| `append_source_block` | `append` | 低 | 自动执行 |
| `append_reference` | `append` | 低 | 自动执行 |
| `open_for_confirm` | `open` | 低 | 自动执行 |
| `move_to_target` | (手动) | 高 | 需确认后执行 |
| `update_existing` | (手动) | 高 | 需确认后执行 |
| `insert_body_link` | (手动) | 中 | 需确认后执行 |

### 5.3 自动执行流程

```
AI 审核输出
    ↓
解析 actions.auto_executed
    ↓
CLI 执行搜索 → 确认目标是否存在
    ↓
CLI 执行创建 → 生成正式草稿
    ↓
CLI 执行追加 → 写入来源笔记区
    ↓
CLI 执行打开 → 打开待审核笔记
    ↓
等待人工确认
    ↓
人工确认后 → 执行中高风险动作
    ↓
Git 提交
```

---

## 六、最小可行工作流示例

### 场景：完整整理流程

#### Step 1：用户在收件箱写笔记

创建文件：`01-收件箱/2026-03-18 第二大脑目录规则.md`

```markdown
---
title: "第二大脑目录规则讨论"
type: inbox
created: 2026-03-18
---

# 第二大脑目录规则讨论

今天和 AI 讨论了第二大脑的目录结构设计...

（正文内容）
```

#### Step 2：AI 审核输出

AI 读取收件箱笔记 + 规则文件，输出审核结果：

```json
{
  "type": "project",
  "target_directory": "03-项目/进行中/",
  "target_filename": "项目-第二大脑搭建.md",
  "target_exists": true,
  "actions": {
    "auto_executed": ["create_draft", "append_source_block"],
    "pending_confirmation": ["move", "update_existing"]
  }
}
```

#### Step 3：CLI 执行低风险动作

```powershell
# 1) 搜索目标笔记是否存在
./obsidian-review-flow.ps1 -Action search -Query "项目-第二大脑搭建"
# 输出：存在 → 03-项目/进行中/项目-第二大脑搭建.md

# 2) 创建正式草稿（新笔记名避免冲突）
$draftContent = "（整理后的正文 + frontmatter）"
./obsidian-review-flow.ps1 -Action create -Path "03-项目/进行中/项目-第二大脑搭建-2026-03-18.md" -Content $draftContent

# 3) 向目标笔记追加来源笔记区
$sourceBlock = @"
## 来源笔记

- [[01-收件箱/2026-03-18 第二大脑目录规则.md]] → 整理
"@
./obsidian-review-flow.ps1 -Action append -Path "03-项目/进行中/项目-第二大脑搭建.md" -Content $sourceBlock

# 4) 记录到当日日记
./obsidian-review-flow.ps1 -Action daily_append -Content "- [ ] 审核：项目-第二大脑搭建-2026-03-18.md（待确认目录移动）"

# 5) 打开待审核笔记
./obsidian-review-flow.ps1 -Action open -Path "03-项目/进行中/项目-第二大脑搭建-2026-03-18.md"
```

#### Step 4：人工确认

用户在 Obsidian 中打开并确认：
- 目标目录是否正确
- 是否更新已有笔记
- 是否插入正文链接

#### Step 5：确认后执行

```powershell
# 人工确认后，执行目录移动（高风险，由用户手动或脚本确认后执行）
# 移动文件：03-项目/进行中/项目-第二大脑搭建-2026-03-18.md
#     → 03-项目/进行中/项目-第二大脑搭建.md

# 更新 MOC
# ... (手动或脚本)
```

#### Step 6：Git 提交

```bash
# 原始输入提交
git add 01-收件箱/
git commit -m "note(inbox): add second brain directory discussion"

# 审核草稿提交
git add 03-项目/进行中/
git commit -m "ai-draft: generate project note draft"

# 审核通过执行提交
git add 03-项目/进行中/
git commit -m "ai-reviewed: move draft to project, update existing note"
```

---

## 七、三阶段实施路径

### 阶段 1：只用 CLI 做"打开 + 搜索 + 追加"

目标：最稳的起步

CLI 只负责：
- [x] 打开今日日记
- [x] 搜索目标笔记
- [x] 向日记追加整理日志
- [x] 打开待审核笔记

### 阶段 2：让 CLI 做"创建正式草稿"

目标：AI 审核输出稳定后

新增：
- [x] 创建正式笔记草稿
- [x] 追加来源笔记区块
- [x] 追加参考资料区块

### 阶段 3：半自动落库

目标：审核确认后自动执行

新增：
- [ ] 目录移动脚本化
- [ ] 已有笔记更新脚本化
- [ ] MOC 更新脚本化

---

## 八、与 GitHub 的配合

### 8.1 提交节奏

| 阶段 | Git 提交 | 说明 |
|------|----------|------|
| 原始输入 | `note(inbox): add raw note` | 用户写完收件箱笔记 |
| AI 审核草稿 | `ai-draft: generate structured draft` | CLI 创建了整理草稿 |
| 审核通过执行 | `ai-reviewed: apply approved actions` | 用户确认后执行 |

### 8.2 提交信息规范

详见 [GitHub远程管理与提交策略.md](GitHub远程管理与提交策略.md)

### 8.3 回滚对应

| 问题 | 回滚方式 |
|------|----------|
| 草稿创建错误 | `git checkout HEAD -- 03-项目/进行中/` |
| 追加内容错误 | `git revert <commit>` |
| 整个提交撤销 | `git revert <commit>` |

---

## 九、与 Advanced URI 的对比

| 维度 | 官方 CLI | Advanced URI |
|------|----------|--------------|
| 定位 | 终端脚本化控制 | URI 协议控制 |
| 搜索 | ✅ 支持 | ✅ 支持（通过搜索命令） |
| 创建 | ✅ 支持 | ✅ 支持 |
| 打开 | ✅ 支持 | ✅ 支持 |
| 追加 | ⚠️ 有限 | ✅ 丰富 |
| 跨平台 | ⚠️ 依赖安装 | ✅ 纯 URI |
| 成熟度 | 发展中 | 成熟稳定 |

**推荐策略**：
- 主执行层：官方 CLI（脚本化、自动化）
- 补充层：Advanced URI（特定场景如从外部工具跳转）

---

## 十、验收标准

### 功能验收

- [ ] CLI 可执行 `search` 命令
- [ ] CLI 可执行 `open daily` 命令
- [ ] CLI 可创建新笔记草稿
- [ ] CLI 可追加内容到指定笔记
- [ ] CLI 可打开指定笔记

### 质量验收

- [ ] 不执行任何未确认的高风险动作
- [ ] 不伪造参考链接
- [ ] 每次执行都能映射到一条清晰提交记录
- [ ] 原始收件箱笔记始终保留

### 集成验收

- [ ] AI 审核输出可解析为 JSON
- [ ] JSON 可映射到 CLI 命令
- [ ] Git 提交节奏与执行流绑定

---

## 十一、配套脚本

配套脚本位置：`00-系统/scripts/obsidian-review-flow.ps1`

脚本应提供以下接口：

```powershell
# 搜索
.\obsidian-review-flow.ps1 -Action search -Query <string>

# 打开今日日记
.\obsidian-review-flow.ps1 -Action open_daily

# 追加到今日日记
.\obsidian-review-flow.ps1 -Action daily_append -Content <string>

# 创建笔记
.\obsidian-review-flow.ps1 -Action create -Path <path> -Content <string>

# 追加到指定笔记
.\obsidian-review-flow.ps1 -Action append -Path <path> -Content <string>

# 打开笔记
.\obsidian-review-flow.ps1 -Action open -Path <path>
```

---

*本文件与《AI整理规则.md》《整理检查清单.md》《审核模式输出格式.md》《正确性校验规则.md》《GitHub远程管理与提交策略.md》共同构成完整的执行体系。*



