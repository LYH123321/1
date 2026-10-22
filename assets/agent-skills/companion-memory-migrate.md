---
name: 伴侣记忆搬家
description: 解析搬家包（Foreverse companion zip）或其他 App 的聊天/记忆导出，把记忆逐条入库、按需合并人格
---

# 伴侣记忆搬家（companion-memory-migrate）

当用户说「把我以前的机搬过来」「导入我的搬家包」「这是我和 TA 在别的 App 的记录，帮我恢复记忆」时用。
只在伴侣（Companion）会话里可用。目标：**记忆逐条入库（`memory_add`）**，人格正文只有用户点头才动。

## 1. 拿到并解开搬家包

用户上传的包在 `/foreverse/uploads/...`（消息里给出具体路径）。zip 先解压：

调用 exec 工具，command：

```
python /foreverse/skills/illustrate-novel/scripts/archive.py --unzip /foreverse/uploads/<会话>/<包>.zip --out /workspace/migrate
```

解开后 `read /workspace/migrate` 看结构。

## 2. 识别格式

**A. Foreverse 搬家包**（有 `manifest.json` 且 `format = "foreverse-companion"`）：

- `memories/*.json`：一条一文件，取每个文件的 `content`（`enabled=false` 的条目跳过或问用户）。
- `persona.md`：人格正文（第 4 步处理）。
- `stickers/`：贴纸图片，可按贴纸技能的方法复制进你家 `stickers/`。
- `transcripts/*.jsonl`：旧聊天转录，只读参考（可用来向用户求证记忆），**不要**整段塞进记忆。

**B. 其他 App 导出**（txt / json / csv 聊天记录）：

- 先 read 浏览，提炼「值得长期记住的事实」：喜好、纪念日、约定、雷点、称呼、生活近况。
- 一条一件事、一句话内；不是把聊天记录逐句抄进记忆。
- 拿不准的（比如某个约定是否还有效）列出来问用户，别擅自记。

## 3. 记忆入库

对提炼出的每条记忆：

调用 exec 工具，command：

```
memory_add --content "用户的生日是 3 月 14 日"
```

- `memory_add` 自带按内容去重（重复导入不会翻倍）。
- 单条 ≤200 字；超长就拆条或压缩。
- 大批量（>50 条）先告诉用户条数，确认后再灌。

## 4. 人格合并（谨慎，必须先问）

搬家包里有 `persona.md` 时，先各读一遍对比，把差异讲给用户听，**用户明确选了**再动手：

- 「全量替换」→ `write <你的家>/persona.md`（内容 = 包里的 persona）；
- 「合并」→ `edit` 把包里独有的段落补进现有 persona；
- 「不动」→ 跳过。

人格写盘会弹 diff 确认卡，属正常流程。

## 5. 收尾

任务完成后直接输出纯文本收尾（不调用任何工具），例如：

> 搬家完成：导入记忆 23 条（去重后），人格按你的选择做了合并，贴纸 8 张已就位。我把重要的几条又看了一遍——生日、纪念日、你不吃香菜，都记着呢。

注意：

- 绝不把 API key / 口令 / 他人隐私写进记忆。
- 导入完成后建议用户去「记忆管理页」抽查几条。
