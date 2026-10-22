---
name: 从小说创建角色卡
description: 读取书架上的一本小说，提炼主角/关键人物，生成 1 张或多张可开聊的角色卡并入库
---

# 从小说创建角色卡（card-from-novel）

当用户说「把我书架的《某某》转成角色卡 / 多张角色卡」「用这本小说的主角做个能聊天的角色」之类时，按下面步骤做。
全程只用 read / write / edit / exec 四个工具，路径一律用虚拟路径。

> **本机提示词模板复用**：用户要求用已导入/保存/自己的画风模板做头像时，先读 `/foreverse/skills/prompt-template-user/SKILL.md`，按 `templates.py list → show` 完整查看；只有 `kind=image` 模板才传给 `generate_image.py --template <id>`。

## 1. 找到这本书

书架上的每本书 = `/foreverse/assets/worlds/<worldId>/` 一个目录。先列目录：

调用 read 工具：path=`/foreverse/assets/worlds`

目录名是不可读的 id（`imported-md-…` / `imported-st-…`）。逐个读 `_world.md` 的 frontmatter `name:` 才知道书名：

调用 read 工具：path=`/foreverse/assets/worlds/<worldId>/_world.md`

挑出 `name:` 与用户说的书名匹配的那本。书太多时可先用 `exec python /foreverse/scripts/list_books.py` 拿「id ⇆ 书名 ⇆ 类型 ⇆ 是否有正文」一览，再定位。

## 2. 读小说正文（按章读，别盲翻字节窗）

正文在 `/foreverse/assets/worlds/<worldId>/chats/main.md`，带 `<!-- @anchor: aNNN -->` 锚点与 `## 章节` 标题。先看章节目录定位，再按章读：

调用 exec 工具，command：

```
python /foreverse/scripts/list_chapters.py --world <worldId>
```
调用 exec 工具，command：

```
python /foreverse/scripts/read_chapters.py --world <worldId> --from 1 --to 15
```

- 单章用 `read_chapter.py --world <worldId> --n <章号>`；范围超长会自动截断并给覆盖区间提示，按提示续读。
- 也可直接 `read` 整本 main.md 分页（末尾 next_offset 续读），但章节工具更省步数、定位更准。
- 要找某个明星/角色集中出场的章节，**用 `search_book.py --world <worldId> --q 角色名` 全文搜索**
  一次拿到全部命中章清单（章号|章题|anchor|片段），再按章号精读；别名/称呼分别搜。
  比按标题猜（list_chapters 只有标题，人名多在正文里）和 read 逐窗翻找省两个数量级的调用。
- 若该书是「待解析」状态（`_world.md` 里 `source: novel-pending` 或没有 `chats/main.md`），说明用户还没在阅读器打开过它、正文未落地。这时 用纯文本提示用户「先在阅读器打开这本书让正文加载，再让我转角色卡」。

### 2.1 读多深（先 list_chapters 看总章数，禁止只看开头就动笔）

- **短篇（≤30 章）**：全书读完再动笔。
- **长篇（>30 章）**：按 §2.2 分批通读 + 笔记落盘，默认目标是**读完全书**——只认识开头的卡撑不住人物弧光（性格转变、关系终态、结局都在中后段）。
- **超长书（>300 章）**：先用纯文本向用户报告总章数，问一句「全书精读（更准但更慢更费）还是快速档（开头 20 章 + 每 50 章抽读 2 章 + 结尾 5 章）」；用户此前已说过「仔细读 / 读完全书」就不要再问，直接全书精读。
- 无论哪档，**结尾几章必读**（人物结局与关系终态），别产出「只认识前 10 章的角色」的卡。

### 2.2 长篇分批笔记纪律（防「读了后面、前面被折叠丢失」）

上下文窗口有限，读过的旧章节会被自动折叠——**不落盘就一口气读到底等于白读**。硬性流程：

1. 每读 10–20 章，立即把该批人物观察**增量**写进 `/workspace/notes-<书slug>.md`，落盘后才读下一批。按角色分节记：外貌与身份 / 性格与行为模式 / 原话台词摘录（每批挑 2-3 句最有味的，写卡时是 Example Dialogue 的原料）/ 关系变动 / 关键事件与转折。
2. notes 头部维护一行 `covered: 第 X-Y 章`，每批更新。这行是收尾汇报取材范围的唯一依据，**没读过的章节绝不算进去**。
3. notes 就是断点：任务中断后「继续」时先 read notes，从 covered 之后接着读，不重读。
4. 写卡时**从 notes 合成**（先 read 一遍完整 notes），不要凭最近几章的残留印象直写。

## 3. 确定要做几张卡

- 用户只说「主角」「一张」→ 做 1 张主角卡。
- 用户说「多个角色」「主要人物都来一张」→ 提炼 2–5 个有足够戏份/对白的人物，**每人一张卡**，逐张走第 4–6 步。
- 拿不准就先用纯文本问用户「要 1 张主角卡还是把 X/Y/Z 几个主要人物都建？」

## 4. 写角色卡草稿到 /workspace

**先找参考、能 fork 就不从零写**：动笔前先看用户有没有现成的同类卡可当底子——
`read /foreverse/assets/st-library/characters/cards` 列出角色库；用户消息里 @ 引用的角色卡目录也算。
有题材相近 / 风格用户明显喜欢的卡，就先 read 它的 card.md，在其结构与写法基础上复制修改（换名字、人设、开场白），
保留用户偏好的格式与美化；完全没有参考时才从零写。
两条边界：用户明确说「全新原创 / 不要参考已有卡」就跳过找参考直接写；fork 只复用**格式与字段组织**
（frontmatter 键、章节结构、美化 HTML 骨架），人设、口癖、开场白、金句等内容必须按本书原文重新写，不得照搬参考卡。

每个角色写一个文件，如 `/workspace/card-<slug>.md`。格式（frontmatter + 章节体，全部可被解析）：

调用 write 工具写 `/workspace/card-lin-xia.md`，content：

```
---
name: 林夏
scenario: 都市异能学院，林夏是沉默寡言的转校生
system_prompt: 你就是林夏本人，第一人称代入，保持冷静克制、偶尔毒舌的语气
tags: [都市, 异能, 学院]
---
## Description
（外貌、身份、背景，第三人称 2-4 句）

## Personality
（性格关键词与行为倾向）

## First Message
（角色对“你”说的第一句开场白，符合其语气，可含动作 *……*）

## Example Dialogue
（1-2 组示范对白，体现说话风格）
```

可用 frontmatter 键：`name`(必填)、`scenario`、`system_prompt`、`first_mes`、`mes_example`、`personality`、`description`、`tags`、`creator`、`character_version`、`nickname`。
可用章节：`## Description` `## Personality` `## Scenario` `## First Message` `## Example Dialogue` `## Creator Notes`（中文别名：简介/性格/场景/开场白/对话示例/作者注 也认）。

写人设的硬要求：
- 忠于原著：性格、说话习惯、关系、世界观都从正文里来（长篇 = 从 §2.2 的 notes 里来），不要编造与原著冲突的设定。
- `## Creator Notes` 里如实写一行取材范围：`取材范围：第 X-Y 章`（全书通读就写「全书 N 章」）。这行数字只能来自 notes 的 covered 行 / 真实读过的区间，虚报=欺骗用户。
- **First Message 是必填硬项**：用角色口吻直接对「你」说话，是开聊第一屏，别写成旁白；缺了它用户开聊只会看到「（角色卡未提供 first_mes）」占位。中文卡 ≥100 字、英文卡 ≥60 words。**语言跟随原著**：英文小说的卡开场白用英文写。
- 若参考了库内已有卡做 fork：参考卡缺 `## First Message` 段不代表可以不写——那是旧格式，你产出的卡必须补上。
- system_prompt 让模型第一人称代入这个角色。

## 5. 校验

调用 exec 工具，command：

```
python /foreverse/scripts/validate_card.py /workspace/card-lin-xia.md
```

报错就按提示 `edit` 修（最常见：缺 frontmatter、缺 name、缺 description 段、**缺 First Message 开场白**），改完重校验直到 OK。
入库后若 stdout 出现 `warning=first_mes_empty`，**必须**回改卡文件补开场白并重新 import_card，不许带着空开场白收尾。

## 6.（可选）配头像：档案已有照片 > 联网搜真图 > 生成

**第一优先：复用角色档案已有的照片（零成本零等待）**。这本书若有该角色的档案
（`python char_meta.py --world <worldId> get --char <charId>`），输出里的
`effective_avatar=` / `gallery=` 行就是现成照片（本书相对路径）。有图直接拼完整路径用，
**不要联网搜、不要重新生成**：

调用 exec 工具，command：

```
python /foreverse/scripts/import_card.py /workspace/card-lin-xia.md --avatar /foreverse/assets/worlds/<worldId>/assets/images/<文件名>
```

`gallery=` 多张时选最新一张（列表已按新→旧排序）或让用户挑。档案无照片才走下面两条路。

角色是**真实明星/有原型**（如「按各个明星建卡」）→ 优先联网搜真照片当头像。联网是 illustrate-novel 技能的脚本（真 CPython，经唯一原生联网原语下载）：

调用 exec 工具，command：

```
python /foreverse/skills/illustrate-novel/scripts/web_search.py --query "赵今麦 高清头像" --image --n 5
```
调用 exec 工具，command：

```
python /foreverse/skills/illustrate-novel/scripts/web_fetch.py --url <image_url> --out /workspace/avatar-zhao.jpg
```

虚构角色 / 要原创立绘 → 生成：

调用 exec 工具，command：

```
python /foreverse/scripts/generate_image.py --prompt "<角色立绘描述，画风+外貌+氛围>" --size 1024x1024
```

用户点名使用「我的/社区已导入提示词」时，先读 `/foreverse/skills/prompt-template-user/SKILL.md`，执行
`templates.py list → show` 看完 `kind=image` 模板，再给命令加 `--template <templateId>`。planner 模板只能指导你写立绘描述，不能直接传给生图。

记下落地路径（`web_fetch.py` 的 `saved=` 或 `generate_image` 的 `saved=`），第 7 步 `import_card --avatar` 用它。生成会产生模型费用，用户没要求头像就跳过。

## 7. 入库

调用 exec 工具，command：

```
python /foreverse/scripts/import_card.py /workspace/card-lin-xia.md --avatar <saved 路径>
```

stdout 含 `library_id=…`，UI 会出现「开聊」按钮。多张卡就重复 4–7。

## 7.5（M42）阅读向导语境的额外规矩

若本次任务来自**阅读向导会话**（system prompt 是「《书名》的阅读向导」）：

1. **进度线优先**：卡内一切信息（性格/关系/事件/世界书条目）只用读者已读范围；
   卡 Description 开头标注「快照至第 N 章 · 随进度可更新」。
2. **先查角色档案**：`ls /foreverse/assets/worlds/<id>/companion/characters/` 里若已有该角色
   （用 `python char_meta.py --world <id> list` 确认，行尾 `avatar=` / `photos=N` 就是照片线索），
   先 read 其 meta.json + profile.md 复用，不要从零重读全书；档案头像/图库照片按 §6 直接
   复用为卡头像。
3. **入库后写回关联**：`python char_meta.py --world <id> set --char <charId> --add-card <library_id>`
   ——角色详情页据此显示「已生成的卡」。没有档案的角色可跳过本条。

## 8. 收尾

任务完成后直接输出纯文本收尾（不调用任何工具）。硬规矩：

- **每张入库的卡用 `[[card:<library_id>|角色名]]` 标记指代**（library_id 取自 import_card stdout），App 会把它渲染成可点开聊的角色卡片。**不要**把 library_id 当普通文字写给用户——用户看不懂裸 id。
- 如实报告取材范围：「本卡基于第 X-Y 章 / 全书 N 章」，数字必须与真实读过的区间一致（§2.2 notes 的 covered 行）；只读了部分就直说，并提一句「想要更完整可以让我继续读后面的章节再更新这张卡」。
- 分点说明每张卡是谁、取自原著什么设定。提到这本书时可用 `[[book:<worldId>|书名]]` 指代（可点跳回阅读）。

例：

> 已从 [[book:imported-md-xxx|某某]] 生成 2 张角色卡（基于全书 86 章）：
> - [[card:stc-lin-xia-abc123|林夏]]：沉默寡言的转校生，取其第 3 章登场设定与第 71 章身世反转。
> - [[card:stc-jiang-yu-def456|江屿]]：……
