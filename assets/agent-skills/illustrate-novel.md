---
name: 为小说章节配图/配视频
description: 给书架上某本小说的指定章节范围逐段配插画（或短视频），就地插入正文，用户阅读时实时可见；支持联网搜真实明星/参考图
---

# 为小说配图 / 配视频（illustrate-novel）

当用户说「给《某书》第 N 章配图」「为这本小说某段配张插画 / 配个短视频」「用某明星的网图给前 100 章配图」之类时，按下面步骤做。
全程只用 read / write / edit / exec 四个工具，路径一律用虚拟路径。**只新增媒体块，绝不改写用户正文文字。**

> 配图任务的「完成」定义 = 图片**已用 insert_media 插进正文**、用户在阅读器看得到。只生成/下载了图而没插正文 = **没完成**。
> 长篇正文常 10MB+，**别用 write 碰整个 main.md**；插图统一走 `insert_media.py`。
> 顺带要**改正文文字**（配图时修一句描写 / 填充占位章）时同理走章级工具：章内替换用
> `edit_chapter.py --world <id> --n <章号> --old "..." --new "..."`；整章重写先把纯正文 write 到
> /workspace 再 `replace_chapter.py --world <id> --n <章号> --file /workspace/xx.md`（锚点由系统分配，
> 禁止手写 `<!-- -->` 注释）。绝不要为了「能编辑」把正文覆盖成小文件——那会摧毁全书。

## 0. 模型、社区资料与本次任务边界

生成前读 `/foreverse/skills/media-operations/SKILL.md`，用 `models.py list/show` 实时查 Foreverse 官方与用户配置模型，核对费用、参考图和规格；不列未配置供应商、不自动改默认。用户要便宜，优先已知低价的一张图，不把未知说免费。

用户要直接读社区生图技能/提示词，不要求安装：`community.py browse --type skill|prompt_template` → `contents --pack <id>` → `read --pack <id> --version <version> --entry <entryId>`，有 nextCursor 就原样续读。完整图片模板且仍在本轮上下文时使用 `generate_image --template-ref <contentRef>`；与本机 `--template` 互斥。详见 `prompt-template-user/SKILL.md`。权限/版本变化时停止，不绕开模板生成。

本技能的“必须插入正文”只适用于用户要求给书配图。用户只要在普通会话生成图片时，原生媒体回执显示即是交付，不擅自写书或建书。生成成功但保存失败不能再次付费重跑。

## 1. 找到这本书

每本书 = `/foreverse/assets/worlds/<worldId>/` 一个目录。先把口语书名映射到 worldId：

调用 exec 工具，command：

```
python /foreverse/scripts/list_books.py
```

拿到 `id ⇆ 书名 ⇆ 类型 ⇆ 正文是否就绪`，挑出用户说的那本。若显示「待解析」，先 `python /foreverse/scripts/parse_book.py --world <id>` 把正文解析就绪（零 AI 费用）再继续；只有非小说世界才需要提示用户去阅读器。

## 2. 看章节目录，定位章节范围（别用字节窗脑补）

不要直接 read 整本 main.md 再用总字数猜「前 100 章在哪」。先列章节目录：

调用 exec 工具，command：

```
python /foreverse/scripts/list_chapters.py --world <worldId>
```

返回每章的 `序号 ⇆ 章号 ⇆ 标题 ⇆ 起始字节 offset`，一眼看清共多少章、「前 N 章」的边界。章数很多时加 `--limit` 先看前一截。

## 3. 按章读正文

按章号或范围读，避免盲翻字节窗：

调用 exec 工具，command：

```
python /foreverse/scripts/read_chapters.py --world <worldId> --from 1 --to 10
```

- 单章用 `read_chapter.py --world <worldId> --n <章号>`。
- 范围超长会自动截断并给覆盖区间提示，按提示分批续读（如 1–10、11–20…）。
- 记下每个要配图段落的 **章号** 或 **一段足够唯一的原文片段**（后面 insert_media 用 `--chapter` / `--after` 定位，不能配错段）。

## 4. 为每个场景拿到图片（联网搜真图 / 生成 / 直链下载）

为每个要配图的对象（人物 / 明星 / 场景）拿一张图。

> **真人/明星硬规则**：用户要「真实明星网络图」时，**必须用 A 联网搜到并下载的真照**插正文，**严禁**用 `generate_image` 生成一张「像某明星」的画顶替——AI 生成的不是本人、等于没满足需求。`generate_image`（B）只用于**虚构场景 / 物件 / 原创画风**，不允许给「有真实姓名的公众人物」生成头像。A 搜到的图只要下载成功（`web_fetch` 退出 0、文件是有效图片）就直接用，不要再 B 生成「备用图」。

按对象三选一：

**A. 联网搜真实图（找明星写真、剧照、参考图首选）**——先搜直链再下载。联网是**本技能自带的脚本**（`scripts/web_search.py`、`scripts/web_fetch.py`，真 CPython 跑，经唯一原生联网原语下载），不是内置 tool：

调用 exec 工具，command：

```
python /foreverse/skills/illustrate-novel/scripts/web_search.py --query "赵今麦 写真" --image --n 5
```

stdout 的结果**已按相关性排序**（标题/来源含明星名、可信图床优先），每条含 `image_url` 与来源页 `page_url`。**直接取 `rank=1` 的 `image_url` 下载，不要反复换关键词空搜**（下载失败或明显不对再换一次词）。用 `web_fetch.py` 下载落到**本书 assets 目录**（阅读器才能按相对路径渲染）；图床常对写真/剧照做防盗链，**把该图的 `page_url` 传给 `--referer`** 可绕过 403：

调用 exec 工具，command：

```
python /foreverse/skills/illustrate-novel/scripts/web_fetch.py --url <image_url> --referer <page_url> --out /foreverse/assets/worlds/<worldId>/assets/images/ch3-star.jpg
```

需要读某网页正文（如查明星资料）时，`web_fetch.py --url <页面> --extract` 会剥掉导航/广告只回可读正文。
用户给的是 `.charx`（角色卡 zip）/ EPUB 链接时：先 `web_fetch.py --url <链接> --out /workspace/pkg.charx` 下载，再 `python /foreverse/skills/illustrate-novel/scripts/archive.py --unzip /workspace/pkg.charx --out /workspace/pkg` 解压，然后 `cat` 出里面的 card.json / 章节再处理。

**B. 模型生成插画（仅虚构场景 / 物件 / 原创画风；真人明星不许走这条）**：

调用 exec 工具，command：

```
python /foreverse/scripts/generate_image.py --prompt "暴雨夜，少女撑伞站在霓虹街口回头，电影感" --world <worldId> --out /foreverse/assets/worlds/<worldId>/assets/images/ch3-rain.png
```

用户说「用我保存的/刚从社区导入的提示词」时，同时读 `/foreverse/skills/prompt-template-user/SKILL.md`：
先 `templates.py list --kind image` 找精确 id，再 `templates.py show --id <id>` 看完全文（分页直到
`use_ready=true`），最后给上面的命令加 `--template <id>`；参考图说明可加 `--reference-notes "..."`。
`kind=planner` 只用来指导你把正文整理成裸图片描述，不能直接传给 `--template`，也不要额外调用一个文本 planner 多花钱。用户指定的模板不可用时如实停下，不要静默去掉模板生一张别的图。

**C. 配短视频** 用 `generate_video.py`（可 `--first-frame <刚生成/下载的图片>` 做图生视频）：

调用 exec 工具，command：

```
python /foreverse/scripts/generate_video.py --prompt "少女撑伞回头，雨丝飘动" --duration 5 --world <worldId> --first-frame /foreverse/assets/worlds/<worldId>/assets/images/ch3-rain.png --out /foreverse/assets/worlds/<worldId>/assets/video/ch3-rain.mp4
```

stdout 的 `saved=` 是绝对虚拟路径（如 `/foreverse/assets/worlds/<id>/assets/images/ch3-star.jpg`）。

## 4.5（M42）角色图归属（可选，一行命令的事）

生成的是**特定角色**的立绘/画像，且该书有角色档案（`python char_meta.py --world <id> list`
能列出）时：插入正文后把图关联到角色，让它出现在阅读器的角色图库里——
`python char_meta.py --world <id> set --char <charId> --avatar assets/images/<文件名>`
（仅当用户想把它设为头像时；普通归属由 UI 侧生图链自动写 manifest，agent 生图暂不需要手动归属）。

## 5. 把媒体就地插入正文——必做，否则等于没配（用 insert_media，不要用 edit）

长篇 main.md 常 10MB+，超 `edit`/`write` 的 ~1MB 体积上限会直接失败（真机实测模型曾卡死在这一步）。插图统一用内置脚本 `insert_media.py`，它直写正文、绕开体积上限、可在版本历史回滚。`--image` 直接给第 4 步 `saved=` 的绝对虚拟路径即可（脚本会自动收敛成相对 `assets/...`）。

定位三选一：

- **按章号**（最稳，配「第 N 章」首图）：`--chapter <章号>`，插到该章标题后。
- **按原文片段**（精确配到某段后）：`--after "该段里一句足够唯一的原文"`。
- 也支持 `--anchor aNNN`（按锚点行）。

调用 exec 工具，command：

```
python /foreverse/scripts/insert_media.py --world <worldId> --image /foreverse/assets/worlds/<worldId>/assets/images/ch3-rain.png --alt "暴雨夜少女撑伞回头" --chapter 3
```

精确到某段后（片段需在该章里唯一）：

调用 exec 工具，command：

```
python /foreverse/scripts/insert_media.py --world <worldId> --image /foreverse/assets/worlds/<worldId>/assets/images/ch3-star.jpg --alt "赵今麦 剧照" --after "她在霓虹下回头。"
```

配视频把 `--image` 换成 `--video`。要求：

- **图片/视频必须已真实落在本书 assets 下才插得进**：`insert_media` 会校验文件存在（先 `generate_image --out` / `web_fetch --out` 落盘成功再插入，别凭记忆编路径——死链会被拒绝）。
- **真人/明星真照不要加 `--ai`**：`insert_media` 默认把图当真实图，阅读器不显示「· AI 生成」标签。只有 `generate_image` 产出的 AI 图才加 `--ai`，让阅读器打上透明度标签。给真人配真照却带 `--ai` 会把真照误标成「AI 生成」，违反「真实网络图」需求。
- 一段配一张/一个；多段就重复第 4–5 步，逐段做。同一张图重复插会自动跳过（幂等）。
- **插错了要撤**：`insert_media.py --world <worldId> --remove <该媒体路径>` 删除正文中的引用行（多处命中全删；只删正文引用不删图片文件；不适用于 --comic 容器——改页列表用 --comic 同 --id 重写）。不要试图用 write/python 改 main.md 来删图。
- **自动模式下不要把「是否插入正文」拆成一次提问**：直接做完该批所有章节的「找图 + 下载 + insert_media 插入」再用纯文本收尾。

## 6. 收尾

每插入一处，阅读器/书架会自动局部刷新——用户若正读到该段，会**实时看到**图片/视频出现；改动在用户视窗上方时视窗不跳动。
全部做完用纯文本向用户说明：配了哪几章、几张图/几个视频、明星图来自哪几位/搜索词，可在阅读器查看。

> **战报必须来自本轮真实工具返回**：只有本轮实际调用过 generate_image / web_fetch / insert_media 并看到成功输出，才能声称「已配图」；绝不复述会话早前轮的成功叙述当作本轮结果（长会话续 turn 容易零工具「幻觉完成」）。拿不准就先 read 正文核实该图的 embed 行真的在，再汇报。批量多本书的配图任务建议每本书用一个新会话做。

## 7. 配音 / 朗读

用户要朗读、旁白或角色配音时，先读
`/foreverse/skills/media-operations/SKILL.md`。`generate_tts.py` 的参数、按字符计费、
分段上限、输出路径和「已生成但保存失败绝不盲目重跑」纪律都只在该媒体域技能维护；
本小说配图技能不复制第二份协议。
