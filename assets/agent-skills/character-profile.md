---
name: 书内角色档案维护
description: 为书架小说维护结构化的书内角色档案（companion/characters/<charId>/ 每角色一目录：meta.json + profile.md），供阅读器角色详情页/卡片工坊/角色图库消费；含 charId 规范、char_meta 脚本用法、增量更新纪律、xray.md 索引同步
---

# 书内角色档案维护

阅读器的「人物档案」体系有两层：总览 `companion/xray.md`（人物一览表）+ 每角色一个目录
`companion/characters/<charId>/`。本技能规定角色目录的维护规程。**阅读向导（防剧透）语境下，
一切内容只能来自读者已读范围。**

## 目录与文件

```
/foreverse/assets/worlds/<worldId>/companion/characters/char_<12hex>/
├── meta.json     # 结构化字段（禁止直接 write 这个文件！只能用 char_meta.py 脚本改）
└── profile.md    # 自由正文（你用 write/edit 工具维护）
```

- `charId` 不可变，由系统生成；**不要**自己编目录名。
- meta.json 字段：name / aliases / role（一句话身份）/ status（当前处境）/
  firstSeenChapter / snapshotChapter（档案更新到第几章）/ avatar / cardLibraryIds。

## 脚本用法（char_meta.py）

```
python char_meta.py --world <id> list                       # 列出全部角色（免确认）
python char_meta.py --world <id> ensure --name 克莱恩        # 确保存在，stdout 给 char_id= 和 profile 路径
python char_meta.py --world <id> get --char char_ab12cd34ef56   # 读 meta + 照片（免确认）
python char_meta.py --world <id> set --char char_... --role 值夜者新人 --status 刚通过面试 \
    --first-chapter 2 --snapshot-chapter 3 --add-alias 小克
```

- 新角色：先 `ensure` 拿 charId，再 `set` 补字段，再写 profile.md。
- 报「并发冲突」时：重新 `get` 后重试（别人刚更新过）。

## 定位人物出场（先搜再读，不要盲翻）

找某个人物在正文哪些章出现（尤其**很靠后才出场**的角色），用全文搜索一次拿到全书命中章清单，
再按章号精读——不要用 read 逐字节窗翻找（30MB 书要翻上百窗）：

```
python search_book.py --world <id> --q 人物名                 # 全书命中：章号 | 章题 | anchor | 片段
python search_book.py --world <id> --q 小名 --from-chapter 120  # 换别名/称呼分别搜；从某章起续搜
python read_chapter.py --world <id> --n <命中章号>             # 拿到章号后精读
```

- **更新已有档案**的标准序列：`char_meta.py get` 拿 snapshotChapter=K → `search_book.py --q 名字
  --from-chapter K+1` 拿增量出场章 → 逐章 `read_chapter` 精读 → edit profile.md → set 快照。
- 阅读向导语境下 search_book 自动按读者进度截断（进度线之后的章不会出现在结果里）；
  进度未知时会拒绝，先请读者到阅读页翻一页落盘进度。
- `--avatar` 只接受本书相对路径 `assets/images/<文件名>` 或 `assets/images/cast/<文件名>`
  （M41 标准像目录）；档案头像未设置时阅读器会自动回退显示 cast.json 的标准像。
- `get` 输出末尾的 `effective_avatar=`（生效头像）与 `gallery=`（该角色图库照片，新→旧）
  是这个角色**已有的视觉资产清单**；`list` 行尾的 `avatar=` / `photos=N` 是同一信息的速览。
  做卡 / 配图前先看这里，有现成照片直接复用（拼 `/foreverse/assets/worlds/<id>/<相对路径>`），
  不要重新生成或联网搜。

## profile.md 写作规程

1. 首行固定 `# <名字>`；之后建议小节：`## 外貌`、`## 性格`、`## 关系`、`## 关键事件`（按章排序）。
2. **增量纪律（防覆盖，硬性）**：文件已存在时先 read，用 edit 精确替换要更新的小节；
   **禁止 write 整文件覆盖**（会冲掉用户手工编辑）。新增事件追加到「关键事件」末尾。
3. 每次更新后：`char_meta.py set --snapshot-chapter <当前章>` 同步快照进度。
4. 阅读向导语境：内容只到读者进度线为止；「关键事件」不写后文。

## xray.md 索引同步

更新完角色文件后，同步 `companion/xray.md` 人物表格里该角色的行（一句话身份 + 当前状态），
保持 xray 是「可浏览的索引」，详情都在角色目录。xray 表格行格式：

```
| **名字** | 一句话身份 | 当前状态 | 首次出场章 |
```

## 与做卡的关系

用户要把某角色做成角色卡时：先 read 该角色的 meta.json + profile.md 复用已有档案
（没有档案先按本规程建档），再按「从小说创建角色卡」技能生成；入库成功后
`char_meta.py set --char <id> --add-card <library_id>` 写回关联。
卡头像优先复用档案照片（`get` 输出的 `effective_avatar=` / `gallery=`，见上），
`import_card --avatar /foreverse/assets/worlds/<id>/<相对路径>` 直接可用；
档案没有照片才考虑生成或联网搜。
