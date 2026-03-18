# GitHub 远程管理与提交策略

本文档规定 Obsidian 知识库接入 GitHub 后的仓库组织、提交规范、分支策略以及审计回滚机制。

---

## 1. 仓库组织结构

### 1.1 推荐仓库命名

```
my-second-brain
# 或
obsidian-vault
```

### 1.2 目录结构

```text
my-second-brain/
├─ 00-系统/                 # 系统文件（不纳入 AI 整理）
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
├─ 06-永久笔记/             # 常青笔记
├─ 07-索引/                 # MOC 导航页
├─ 08-归档/                 # 归档笔记
├─ 09-模板/                 # 笔记模板
├─ 10-附件/                 # 媒体附件
├─ .obsidian/               # Obsidian 配置（选择性纳入）
├─ .gitignore
└─ README.md
```

### 1.3 .gitignore 基础配置

```gitignore
# Obsidian 临时文件
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache/
.obsidian/graph.json
.obsidian/appearance.json
.obsidian/community-plugins.json
.obsidian/plugins/

# 系统临时文件
.DS_Store
Thumbs.db
*.tmp

# 附件目录（可选）
# 如果附件多且大，可选择不纳入版本控制
# 10-附件/
```

### 1.4 纳入版本控制的配置

```gitignore
# 基础设置需要纳入
!.obsidian/app.json
!.obsidian/core-plugins.json
!.obsidian/theme.json

# 插件配置按需纳入
!.obsidian/plugins/obsidian-git/data.json
```

---

## 2. 提交消息规范

### 2.1 提交类型前缀

| 类型 | 说明 | 示例 |
|------|------|------|
| `note:` | 新增或更新普通笔记 | `note: add reading notes about AI agents` |
| `daily:` | 每日日志 | `daily: add 2026-03-18 log` |
| `project:` | 项目相关更新 | `project: update project-xxx progress` |
| `moc:` | MOC/索引更新 | `moc: update knowledge index` |
| `review:` | 周/月复盘 | `review: add weekly review 2026-W12` |
| `chore:` | 维护性工作 | `chore: update template` |
| `fix:` | 错误修正 | `fix: correct typo in note` |

### 2.2 AI 整理相关提交

| 类型 | 说明 | 示例 |
|------|------|------|
| `ai-draft:` | AI 生成的初稿（待审核） | `ai-draft: generate reading note draft` |
| `ai-reviewed:` | 经审核后执行的 AI 整理 | `ai-reviewed: move note to project directory` |
| `ai-rejected:` | 审核拒绝的 AI 建议 | `ai-rejected: discard link suggestion` |

### 2.3 提交消息格式

```bash
# 基本格式
<type>: <简短描述>

# 带详细说明
<type>: <简短描述>

<详细说明（可选）>

Co-authored-by: Claude <noreply@anthropic.com>
```

### 2.4 提交消息示例

```bash
# 简单笔记更新
note: add meeting notes about system design

# 带有 AI 标注
note: add reading notes about prompt engineering
AI-Generated: true
AI-Mode: review

# 项目笔记更新
project: update second-brain progress

# 带详细说明
ai-reviewed: promote inbox note to permanent
- Moved "收件箱价值" to 06-永久笔记/
- Added link to MOC-知识管理
- Updated project note
```

---

## 3. 分支策略

### 3.1 推荐的简单分支模型

采用 `main` + 功能分支的简单模型：

```
main
├── feature/xxx       # 功能开发
├── ai-review/xxx     # AI 整理审核
└── hotfix/xxx        # 紧急修复
```

### 3.2 分支命名规范

```text
# 功能分支
feature/add-reading-template
feature/setup-github-sync

# AI 审核分支（推荐用于审核模式）
ai-review/note-2026-03-18-second-brain

# 修复分支
hotfix/fix-broken-link
```

### 3.3 推荐工作流

#### 方案 A：直接提交到 main（推荐初期）

```bash
# 适合：单人使用、审核模式
git add .
git commit -m "note: add new inbox note"
git push
```

#### 方案 B：PR 审核后合并（推荐稳定期）

```bash
# 创建分支
git checkout -b ai-review/note-xxx

# 开发/审核后提交
git add .
git commit -m "ai-reviewed: promote note to permanent"

# 推送到远程
git push -u origin ai-review/note-xxx

# 创建 PR（可选）
# 审核后合并到 main
```

---

## 4. 原始输入与 AI 整理区分策略

### 4.1 区分原则

| 类型 | 说明 | 提交方式 |
|------|------|----------|
| 原始输入 | 用户直接在收件箱创建的内容 | `note(inbox):` 或 `daily:` |
| AI 草稿 | AI 生成的初稿，未审核 | `ai-draft:` |
| AI 审核后 | 经人工审核通过的 AI 整理 | `ai-reviewed:` |
| 混合内容 | 原始 + AI 混合（审核后） | `ai-reviewed:` + 说明 |

### 4.2 如何标识 AI 生成内容

#### 方法 A：通过提交消息标识（推荐）

```bash
# AI 生成的笔记
git add 01-收件箱/新笔记.md
git commit -m "ai-draft: generate note from inbox input"
```

#### 方法 B：通过文件命名标识

```text
# 不推荐，容易混淆
01-收件箱/I-20260318-笔记名-AI.md
```

#### 方法 C：通过文件内容标识

在 frontmatter 中添加标记：

```yaml
---
title: "笔记标题"
type: reading
created: 2026-03-18
updated: 2026-03-18
ai_generated: false    # true = AI 生成, false = 人工输入
ai_reviewed: false    # true = 已审核, false = 待审核
---
```

### 4.3 推荐工作方式

#### 阶段 1：原始输入

用户在收件箱中创建笔记：

```bash
git add 01-收件箱/I-20260318-我的想法.md
git commit -m "note(inbox): add new idea"
```

#### 阶段 2：AI 草稿生成

AI 处理后生成草稿（未执行）：

```bash
# 标注为 AI 草稿，但仍在本地
# 不需要立即提交
```

#### 阶段 3：审核后执行

人工审核通过后：

```bash
git add 03-项目/进行中/项目-xxx.md
git commit -m "ai-reviewed: promote inbox note to project
- Moved from 01-收件箱/
- Added frontmatter
- Created link reference"
```

---

## 5. 可审计与回滚机制

### 5.1 审计策略

#### A. 提交历史审计

每次提交必须包含足够信息：

```bash
# 好：信息充分
git log --oneline
# a1b2c3d ai-reviewed: promote note to permanent
# x9y8z7w note(inbox): add new idea
# m3n6p9q daily: add 2026-03-18

# 每个提交都能追溯来源和目的
```

#### B. 提交分组规范

按"原子性"原则：一个提交只做一件事：

```bash
# 推荐：一个提交一件事
git commit -m "note: add reading note"
git commit -m "ai-reviewed: promote to project"
git commit -m "moc: update index"

# 不推荐：混合提交
git commit -m "note: add and promote to project and update moc"
```

#### C. 定期审计

建议每月进行一次提交审计：

```bash
# 查看本月所有提交
git log --since="2026-03-01" --until="2026-03-31" --oneline

# 查看 AI 相关提交
git log --grep="ai-" --oneline

# 查看特定目录的提交
git log -- 01-收件箱/ --oneline
```

### 5.2 回滚策略

#### A. 单文件回滚

```bash
# 回滚单个文件到上一个提交
git checkout HEAD -- 01-收件箱/某笔记.md

# 回滚到特定提交
git checkout abc1234 -- 01-收件箱/某笔记.md
```

#### B. 目录回滚

```bash
# 回滚整个收件箱目录
git checkout HEAD -- 01-收件箱/
```

#### C. 提交回滚（推荐用于错误 AI 整理）

```bash
# 创建新提交来撤销之前的提交（保留历史）
git revert abc1234

# 硬回滚（不推荐，会丢失历史）
git reset --hard abc1234
```

#### D. 使用 reflog 恢复误删

```bash
# 查看所有操作历史
git reflog

# 恢复到误删前的状态
git checkout HEAD@{2}
```

### 5.3 备份策略

#### A. 定期手动备份

```bash
# 导出完整仓库
git bundle create backup-2026-03-18.bundle --all
```

#### B. GitHub 远程备份

```bash
# 确保远程仓库是最新的
git push origin main

# 或推送到备份远程
git remote add backup https://github.com/username/backup.git
git push backup main
```

#### C. 使用 GitHub Releases

```bash
# 定期创建 Release 快照
gh release create v2026-03-18 -n "Monthly snapshot"
```

---

## 6. 推荐的日常工作流

### 每日工作流

```bash
# 1. 开始工作前拉取最新
git pull origin main

# 2. 在收件箱创建新笔记（原始输入）
# ... 在 Obsidian 中创建内容 ...

# 3. 提交原始输入
git add 01-收件箱/
git commit -m "note(inbox): add new ideas"

# 4. 使用 AI 处理（审核模式）
# ... AI 生成审核结果 ...

# 5. 审核通过后执行
git add 03-项目/
git commit -m "ai-reviewed: promote notes to project"

# 6. 推送到远程
git push origin main
```

### 审核模式工作流

```bash
# 1. AI 生成审核结果（不执行）
# 查看审核输出

# 2. 人工确认后，执行允许的动作
git add <目标文件>
git commit -m "ai-reviewed: execute approved actions"

# 3. 如果审核拒绝
git commit -m "ai-rejected: discard suggestions for note"
```

---

## 7. 常见问题处理

### Q1: 提交后发现问题怎么办？

```bash
# 撤销最后一个提交（保留修改）
git reset --soft HEAD~1

# 撤销并丢弃修改
git reset --hard HEAD~1
```

### Q2: 多人协作时如何处理冲突？

```bash
# 拉取远程
git pull origin main

# 手动解决冲突后
git add .
git commit -m "merge: resolve conflicts"
```

### Q3: 大文件如何处理？

```bash
# 使用 Git LFS
git lfs install
git lfs track "*.pdf"
git add .gitattributes

# 或者添加到 .gitignore
echo "*.pdf" >> .gitignore
```

### Q4: 敏感信息泄露怎么办？

```bash
# 从历史中移除文件
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch secrets.json' \
  --prune-empty --tag-name-filter cat -- --all

# 或使用 BFG Repo-Cleaner
bfg --delete-files secrets.json
```

---

## 8. 验收标准

### 第一版可用，满足以下条件：

- [ ] GitHub 仓库已创建并可访问
- [ ] 目录结构已按规范组织
- [ ] .gitignore 已正确配置
- [ ] 提交消息规范已落地
- [ ] 至少完成 10 次提交
- [ ] 掌握单文件/目录回滚方法
- [ ] 掌握查看提交历史方法

### 进阶目标：

- [ ] 每月进行一次提交审计
- [ ] 使用分支进行功能开发
- [ ] 使用 GitHub Releases 创建版本快照
- [ ] 制定远程备份策略
