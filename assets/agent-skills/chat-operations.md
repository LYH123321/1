---
name: chat-operations
description: 搜索长聊天、创建群聊及增删群成员；查旧话与拉群操作时按需读取
---

# 聊天检索与群聊操作

## 1. 搜聊天历史

用户问「TA 哪次提过 X」「我们什么时候聊过 Y」时，不要 read 整份转录：

```text
python /foreverse/scripts/search_chat.py --world <id> --q "<关键词>" [--session <branch>] [--speaker <slug>] [--limit N]
```

- 默认 session 是 `main`，默认显示 20 条，上限 100；匹配是大小写不敏感的纯子串，不是正则。
- 返回 `anchor | speaker | 片段`。拿到 anchor 后再精读：

```text
python /foreverse/scripts/export_chat_window.py --world <id> --session <branch> --from <anchor> --to <anchor>
```

- hidden 消息、未选 swipe、reasoning 和图片不进入检索；只搜聊天页当前可见的 active 文本。
- 零命中时先换人名别称/地点/原句片段，再去掉 `--speaker` 扩大范围，不要退回自写 Python 扫文件。
- `--world` 必须来自 `list_books.py`，受保护 world 会拒绝读取。

## 2. 创建群聊

先用 `list_cards.py` 找到角色库 id；同名卡先向用户消歧。

```text
python /foreverse/scripts/group.py create --members <libId1,libId2,...> --name "<群名>"
```

- 需要 2–8 张有效角色库卡；成员按正式 UI 同源装配链进入新 world，源库卡不改。
- 成功回 `world_id`，收尾用 `[[book:<world_id>|群名]]`；要定玩法再读 group-director 技能。

## 3. 查看、添加、移除成员

动既有群前先看当前成员：

```text
python /foreverse/scripts/group.py members --world <worldId>
```

加入一张角色库卡（一次一名，普通确认）：

```text
python /foreverse/scripts/group.py add --world <worldId> --member <libraryId>
```

移除一名当前成员（`--member` 使用 members 返回的 slug）：

```text
python /foreverse/scripts/group.py remove --world <worldId> --member <slug>
```

- remove 是破坏性 STRONG 确认，即使自动模式也必须让用户看卡；群里至少保留 1 人。
- remove 会删该群内的成员副本、成员世界书、library link 与 disabled 项；历史消息保留删除时的名字。
- 源角色库卡仍在时可重新 add，但会按源卡重新装配，不是版本回滚，也不还原群内旧改动。
- 成员变化后已有 `group_director.md` 可能过期；回执提示 stale 时再读 group-director 技能更新群规。
- 非群聊、重复成员、路径非法、角色卡缺档或受保护内容都会在写盘前拒绝；按错误里指向的
  `list_cards.py` / `group.py members` 重新核对，不要改用通用文件工具硬写 cast。

