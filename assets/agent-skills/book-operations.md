---
name: book-operations
description: 正文草稿展示与确认后采用（写入旧书、存成新书）、整理书架、修复导入小说章序和编辑世界书；用户要保存已有草稿、改名、删书、调整章序或查改 lore 时使用
---

# 书架、章节次序与世界书操作

用户要展示或采用已有正文草稿、整理书架、修复章序或编辑世界书时使用。已有草稿采用走下方票据流程；书内阅读定位仍用 `list_chapters.py`、`read_chapter.py` 等专用原语，不用通用编辑绕过确认与任务账。

## 0. 普通会话正文草稿采用

用户只要写正文时，必须直接输出闭合的 `fv-draft` 正文围栏，保留自然段；不要为了展示而创建书籍。这是 App 显示正文卡的协议，不是工具调用或额外解释；用户要求“只要正文、不要标题、不要解释、不要工具、先不创建书”时同样使用，不把这段协议说明展示给用户。普通问答、分析和引用示例不包装成正文卡，专用身份已有的输出约定不变。原生正文卡可复制、写入旧书或存成新书，关闭后仍回原聊天。

用户明确要求采用已生成稿件时，不重新调用模型改写。普通主会话可将既有完整正文原样写入 `/workspace/draft.md`，先 `list_books.py` 找到准确目标，再：

```text
python /foreverse/scripts/writer_open.py --world <id> --file /workspace/draft.md
python /foreverse/scripts/writer_apply.py --world <同一id> --ticket <返回的ticketId>
```

open 只准备预览；apply 经过原有写入确认才执行，成功以回执为准。插在指定段后用 open 的 `--mode insert_after --anchor aN`，替换单段用 `--mode replace --anchor aN`，须先读到准确位置。不通过 write/edit 整本正文绕过任务账。取消用 `writer_cancel.py --ticket <id>`，不删除原稿；已提交内容通过书中最近执笔任务撤销。

源稿、目标或账号变化以及票据过期时重新预览；结果不明不能换票重写。票据仅当前任务有效，不扩大子 Agent、伴侣或专用向导权限。存新书走正文卡的明确用户操作与现有导入准入，不伪称脚本已创建书籍。

## 1. 先找准书

```text
python /foreverse/scripts/list_books.py
```

所有 `--world` 都必须使用返回的单段 id，不要拿书名代替，也不要拼路径。

## 2. 导入小说章序检查与修复

用户说「第十章跑到第九章前」「导入后章节顺序颠倒」「目录编号乱了」时，先只读检查：

```text
python /foreverse/scripts/chapter_order.py check --world <id>
```

检查按**结构章题里的显式序号**判断，不读正文猜剧情。输出会给 `status`、相邻倒序对、重复号、
缺号/跨度、疑似分卷重置和 `proposed_moves`。只有 `status=needs_reorder` 且出现
`apply_hint` 才能进入重排：

```text
python /foreverse/scripts/chapter_order.py apply --world <id>
```

- `check` 纯只读、免确认；`apply` 改正文，普通确认并打版本快照。
- 重排单位是完整 byte range：章标题、正文、anchor、图片/视频/连环画注释一起移动，不拆章、不改字。
- 无编号标题（卷名、序章、番外、自定义标题）是硬边界，各边界之间分别判断，避免跨卷混排。
- 连续编号段有重复章号、编号跨度过大或疑似隐式重置时，`apply` 整体拒绝且原文不动；不要绕过工具自写脚本强排。
- `apply` 执行前会在文件锁内重新扫描，暂存文件也会再验一遍；已排好时幂等跳过。
- 本工具只支持已解析的标准 Reader 布局 `chats/main.md`；显示「待解析」的书先跑 `parse_book.py`。

## 3. 书架预览、改名、删除

删除前必须先对完全相同的一组 id 做预览：

```text
python /foreverse/scripts/shelf.py info --world <id1,id2>
```

预览会列书名、类型、正文是否存在、体量和最后修改时间。不存在或受保护的书不会进入删除建议。

改名一次只改一本，只改 `_world.md` 的书名元数据，不动正文和设定：

```text
python /foreverse/scripts/shelf.py rename --world <id> --name "<新书名>"
```

永久删除（单次最多 20 本）：

```text
python /foreverse/scripts/shelf.py delete --world <id1,id2>
```

- 删除是 STRONG 确认，即使会话是自动模式也必须让用户看卡。
- 整个书目录都会消失：正文、聊天、世界书、插图和其它书内资产一起删除。
- 版本快照不覆盖整书目录，不能从版本历史恢复；找回只能重新导入。
- 任一 id 不存在、非法或受保护时整批拒绝，一本也不删。

## 4. 世界书结构化原语

不要用通用 write/edit 手拼 `lore/*.json`。本工具通过 `StLoreFileFormat` 往返，保留未知扩展字段。

```text
python /foreverse/scripts/lore.py list --world <id>
python /foreverse/scripts/lore.py get --world <id> --id <entryId>
python /foreverse/scripts/lore.py add --world <id> --title "<标题>" --keys "<词1,词2>" --content "<正文>" [--constant] [--disabled]
python /foreverse/scripts/lore.py update --world <id> --id <entryId> [--title "<标题>"] [--keys "<词1,词2>"] [--content "<正文>"] [--enable|--disable] [--constant|--triggered]
python /foreverse/scripts/lore.py remove --world <id> --id <entryId>
```

- `list/get` 只读免确认；`add/update` 普通确认。
- `remove` 删除单条设定，属 STRONG 确认；lore 目录很小且会打版本快照，可从版本历史找回。
- 世界书是 world 级资产，改动会影响这本书的全部聊天时间线，不是只改当前 session。
- `--keys` 支持逗号分隔；常驻条目用 `--constant`，改回关键词触发用 `--triggered`，
  建好先停用可用 `--disabled`。
- 报「条目不存在」时先重新 `list`，不要猜 entryId；报损坏 JSON 时先 `get` 取证，本工具不会覆盖坏档。

