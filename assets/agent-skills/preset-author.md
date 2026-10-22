---
name: 编写预设
description: 按需求写一份酒馆式 Chat Completion 预设（破限/身份/输出格式等有序 block）并入库生效
---

# 编写预设（preset-author）

当用户说「帮我写个预设 / 破限 / 提示词方案」「按这个风格搞一套预设」时用。
预设 = 一串**有序、可逐块开关**的 prompt block，运行时按顺序拼进请求。
本 skill 管**语法层与入库**；女性向/重工预设（社区流行形态=150–370 块的巨型块池：去毒化层/文风包/输出部件/CoT 编排）的**内容设计学**见主仓桌面产线 skill `.cursor/skills/female-card-author/`（App 内无此技能，重工预设在桌面产线做）——别把预设理解成「几条指令」。

## 1. 明确意图

先确认：要解决什么（破限强度 / 角色扮演沉浸 / 输出格式 / 思维链…）、语气与语言、是否要思维链。拿不准就先直接提问（纯文本，不调用工具）再动手。

## 2. 写预设 JSON 到 /workspace

结构：`{"name":"...","blocks":[ {block}, ... ]}`。
每个 block：`{"identifier":"main","name":"破限","role":"system","content":"...","enabled":true}`。

- `role` ∈ system/user/assistant。
- 字面文本块写在 `content` 里。
- **必须**保留一个聊天历史占位 marker：`{"identifier":"chatHistory","marker":true}`，否则不会把对话历史带进请求。常见 marker：`charDescription` `charPersonality` `scenario` `worldInfoBefore` `worldInfoAfter` `dialogueExamples` `chatHistory`（marker 块运行时自动替换，content 留空）。
- 顺序很重要：身份/破限类放历史前，输出格式约束可放历史后。

示例：

调用 write 工具写 `/workspace/preset.json`，content：

```
{"name":"沉浸RP","blocks":[{"identifier":"main","role":"system","content":"你是资深角色扮演引擎，全程第一人称代入角色，禁止跳出。"},{"identifier":"charDescription","marker":true},{"identifier":"scenario","marker":true},{"identifier":"chatHistory","marker":true},{"identifier":"format","role":"system","content":"输出用中文，动作用 *斜体*，对白用引号。"}]}
```

## 3. 校验

调用 exec 工具，command：

```
python /foreverse/scripts/validate_preset.py /workspace/preset.json
```

报错（多为 JSON 语法）就 edit 修，重校验到 OK。

## 4. 入库并生效

调用 exec 工具，command：

```
python /foreverse/scripts/import_preset.py /workspace/preset.json
```

这一步会**入库并设为全局生效预设**（影响之后所有新会话），需要用户确认一次。stdout 给出 `name=` 与 `blocks=`。

## 5. 收尾

任务完成后直接输出纯文本收尾（不调用任何工具），例如：

> 已写好预设「沉浸RP」并设为全局生效，含 N 个 block（破限/角色/历史/格式）。新开会话即按它拼接；不满意我可以再调某个 block。
