---
name: 同人演绎
description: 基于用户给的原著（书架小说 / 联网搜索 / 角色卡）创建一本可在阅读器持续 AI 续写的同人小说：先访谈定位用户的同人需求（身份/立场/CP/金手指/走向），再立项写开头，并把世界观、世界书词条、文风、剧情走向总纲写进续写时真正会注入的字段
---

# 同人演绎（fanfic-derive）

当用户说「帮我写一本《某某》的同人」「我想穿越进某小说当主角的队友」「用这张角色卡开一本同人文」「找个出名小说给我开个同人本」之类时，按本技能做。
全程只用 read / write / edit / exec 四个工具，路径一律用虚拟路径。

**本技能的交付物不是「一次性生成的剧情」，而是一本用户之后会在阅读器里反复点「AI 续写 / 剧情候选 / 扩写」的书。**
所以除了开头正文，最重要的工作是把设定写进续写时**真正会被注入 prompt 的字段**（见 §4 §5 注入机制），
让用户后续每一次续写都自动带着原著世界观、人设与用户钦定的剧情走向跑，而不是只有你在场时才对味。

> **Reader 模板桥**：用户要求查看、切换或绑定已导入/保存的续写、扩写、改写、候选或图片模板时，先读 `/foreverse/skills/prompt-template-user/SKILL.md`。用 `templates.py current/list/show/bind` 走 typed Store；不要直接找偏好文件。封面或章头图只有 `kind=image` 模板可传给 `generate_image.py --template <id>`。

## 0. 先访谈：搞清楚用户到底想要什么样的同人（必做，不许跳过）

同人的成败在需求定位，不在文笔。动笔前**必须**用纯文本向用户提问（输出问题后自然停轮等回复，不要调用工具）。
一次最多问 5 个问题，用户已经在任务里说清楚的不要重复问；用户说「都听你的 / 随便」时按推荐档补齐并在收尾时说明。

必须澄清的维度（按重要性）：

1. **素材来源**：原著是书架上已有的书？还是要联网查资料的知名小说？还是用户会给角色卡 / 文件？（对应 §1 三条路线）
2. **「我」是谁——身份与立场**（同人最核心的一刀）：
   - 原著主角视角续写 / 番外（不加新人）；
   - 自设新主角进入原著世界：穿越者 / 穿书者（读过原著=剧情先知）/ 重生原著配角 / 土著原创角色；
   - 与原著主角的关系立场：**队友互助**（正向流：抱大腿、辅佐、并肩）/ **平行线**（各自精彩，偶有交集）/
     **取而代之**（截胡主角机缘、夺其气运，常配后宫 / 争霸）/ **对手或反派阵营**（站原著反派边，或自己当反派）。
     这直接决定世界书里「主角相关词条」怎么写——是维护原著主线，还是明说「原著主线剧情可以被抢走 / 改写」。
3. **金手指与知悉度**：有没有系统 / 特殊能力？知不知道后续剧情（先知流要在设定里写明知悉范围，续写时模型才敢让主角「未卜先知」）？
4. **感情线**：无 CP / 跟原著 CP 走 / 自设 CP（和谁）/ 后宫（列出目标角色）。涉及拆原著官配要单独确认（很多读者的雷点）。
5. **走向与基调**：爽文碾压 / 正向热血 / 日常温馨 / 黑深残 / 悬疑烧脑；以及**从原著哪个时间点切入**（开局第一幕在哪，如「主角刚进宗门时」「大战前三年」）。
6. **雷点与禁忌**：不许写死谁、不碰什么题材、尺度边界。

推荐档（用户全权委托时）：自设穿越者主角 + 队友互助立场 + 轻度剧情先知 + 无 CP 或单 CP + 正向爽文 + 从原著开篇附近切入。

## 1. 拿到原著素材（三条路线，可组合）

### 路线 A · 书架已有的书（本地导入小说）

调用 exec 工具，command：

```
python /foreverse/scripts/list_books.py
```

找到原著的 worldId 后，先看章节目录再按章读，提炼设定（不要盲翻整本）：

调用 exec 工具，command：

```
python /foreverse/scripts/list_chapters.py --world <原著worldId>
```

调用 exec 工具，command：

```
python /foreverse/scripts/read_chapters.py --world <原著worldId> --from 1 --to 8
```

- 读开头若干章定：世界观规则、主角人设与说话方式、主要配角、势力结构、切入点附近的剧情状态。
- 用户指定「从第 N 章切入」就精读第 N 章前后（`read_chapter.py --world <id> --n <N>`）。
- 顺手记 3~5 段最能代表原著文风的原文短句（每段 ≤80 字），§5 的文风块要用。
- 原著「正文未就绪」（无 `chats/main.md`）时用纯文本请用户先在阅读器打开一次这本书。

### 路线 B · 知名小说，联网查资料

联网脚本在 illustrate-novel 技能目录下（真 CPython，经原生联网原语）：

调用 exec 工具，command：

```
python /foreverse/skills/illustrate-novel/scripts/web_search.py --query "斗破苍穹 萧炎 设定 斗气等级" --n 5
```

调用 exec 工具，command：

```
python /foreverse/skills/illustrate-novel/scripts/web_fetch.py --url <某条结果的 url> --extract
```

- 用 2~4 次搜索覆盖：世界观体系（力量等级 / 规则）、主角与核心配角人设、主线大事年表、用户切入点附近的剧情。
- `--extract` 只回可读正文；查百科 / 萌娘百科 / 维基类页面效率最高。
- **只提炼设定事实，不整段复制原著文字进正文**——同人是原创演绎，不是搬运。
- 搜不到可靠资料的小众作品，退回向用户要材料（路线 A / C），不要凭模糊印象编造原著设定。

### 路线 C · 用户给的角色卡 / 文件

- 用户 @ 引用或让你看角色库：`read /foreverse/assets/st-library/characters/cards` 列出，再 read 对应 `card.md`
  （Description / Personality / Scenario / Lorebook 都是现成设定源，世界书词条可直接改写复用）。
- 用户上传的文件在 `/foreverse/uploads`（只读）。zip/charx 先用 illustrate-novel 的 `archive.py --unzip` 解到 /workspace 再读。

## 2. 立项：创建同人书

访谈定稿 + 素材读完后创建新书（书名体现同人身份，如《斗破：药老的第二个弟子》）：

调用 exec 工具，command：

```
python /foreverse/scripts/create_novel.py --title "<同人书名>" --chapters 5 --outline "切入|||初遇|||立足|||分歧点|||新篇" --intro "<一句话简介：谁、以什么身份、进入哪个原著、要做什么>"
```

- stdout 的 `world_id=` 是新书 worldId（`created-novel-` 前缀），后面所有写入都用它。
- `--outline` 写你规划的前几章章题；后续章节用户靠阅读器续写长出来，不必贪多。
- 章节占位是「（本章待创作…）」，§3 用 edit 逐章替换。

## 3. 写开头正文（1~3 章，落实访谈结论）

每章正文写在该章 `<!-- @anchor: aNNN kind=manual -->` 锚点注释行**下方**，用 edit 把占位段替换成正文；
**锚点行本身一个字符都不要动、不要自造新锚点行**（阅读位置锚在它上面）。

调用 edit 工具改 `/foreverse/assets/worlds/<新书worldId>/chats/main.md`（old=「（本章待创作：用 edit 或 insert_media 填充正文与配图。）」所在段、new=整章正文，多个自然段用空行分隔）。

开头的硬要求：

- 第 1 章必须兑现访谈里的**切入点**：时间、地点、原著剧情进行到哪一步、主角以什么方式入场。
- 主角身份 / 金手指 / 知悉度在前两章内自然展示（穿书者的「我读过这本书」要落到具体剧情记忆，不要只喊口号）。
- 原著角色出场要贴原著人设与语气（从 §1 素材里来），不要 OOC；与原著的**第一个分歧点**要清晰可感。
- 每章 1200~3000 字；章尾留钩子——这本书的下文是用户在阅读器里续出来的，结尾要「可续」。
- 大纲式罗列、「未完待续」等元信息不要出现在正文里。

## 4. 写 `_world.md` 世界观（续写时的「常开总纲」）

`/foreverse/assets/worlds/<新书worldId>/_world.md` 的 frontmatter 语义键 + 正文，
会在**每一次** Reader 文本 AI（续写 / 扩写 / 新建分支 / 选区重写 / 剧情候选）里作为「世界设定」全量注入
（系统噪声键 author/source/tags/word_count 等会被自动剔除，其余全部进 prompt）。这里放「每次续写都必须在场」的信息：

调用 write 工具写 `/foreverse/assets/worlds/<新书worldId>/_world.md`，content 骨架：

```
---
name: <同人书名>
genre: 同人 · <原著名> · <赛道>
---

## 原著世界观速览
（力量体系 / 核心规则 / 主要势力，5~10 行，只写续写时必须遵守的硬设定）

## 本书主角
（姓名、身份（穿越者/穿书者/重生者/土著）、金手指、知悉度范围、性格与说话方式）

## 与原著的关系
（切入时间点；与原著主角的立场：队友/平行/取而代之/对手；哪些原著主线保持不变、哪些已被本书改写；
 感情线约定：CP 是谁 / 后宫名单 / 不拆哪对官配）

## 剧情走向总纲
（用户钦定的走向与基调；未来 3~5 个大节点的一句话路标；绝对不许发生的事（雷点））

## 写作规约
（人称视角、文风基调、每次续写优先推进什么（主线/日常/感情线的配比）、禁止 OOC 的点名角色）
```

写法纪律：全文控制在 1500 字内（每次都注入，吃 token 预算）；写「规则和事实」，不写抒情；
「剧情走向总纲」是用户日后**控制剧情方向的头号旋钮**——告诉用户改这里 = 改所有后续续写的航向
（阅读页 → 书籍信息 → 编辑世界观，保存即生效）。

## 5. 写 AI 资料栈：世界书词条 / 角色 / 文风（第二注入面）

注册进 `reader_context/prompt_stack.json` 的块，同样在每一次 Reader 文本 AI 里注入（位于世界设定之后）。

**Reader 与酒馆聊天的关键差异，别拿 ST 经验想当然**：Reader 的世界书词条**不做关键词触发扫描**，
所有 `enabled` 的词条每次**全部注入**。所以词条不追求酒馆式几十条大书，而是「少而硬」：
6~15 条、单条 ≤300 字、总量 ≤3000 字；keys 字段只当分类标签写（不影响注入），靠 `enabled` 与块开关控制预算。

### 5.1 块文件

按需写这几类（都放 `reader_context/` 下）：

**世界书词条**（原著专名档案：人物 / 势力 / 地点 / 物品 / 大事件，凡正文会反复提到的专名都值得一条）——
写 `/foreverse/assets/worlds/<id>/reader_context/lore/fanfic-lore.json`：

```
{"entries": [
  {"id": "e1", "comment": "萧炎", "keys": ["萧炎"], "content": "原著主角。当前时点：…。与本书主角的关系：…。人设锚：…（≤300字）", "enabled": true},
  {"id": "e2", "comment": "斗气等级", "keys": ["斗气"], "content": "斗者→斗师→…→斗帝。本书主角当前：…", "enabled": true}
]}
```

写完校验：

调用 exec 工具，command：

```
python /foreverse/scripts/validate_lore.py /foreverse/assets/worlds/<id>/reader_context/lore/fanfic-lore.json
```

**主角人物卡**（比 _world.md 更细的行为层：口癖、行事习惯、底线）→
`reader_context/world_fragments/protagonist.md`（markdown，可带 frontmatter，注入时自动去 frontmatter）。

**文风样例**（§1 记下的原著原文短句 3~5 段 + 一行「模仿以上句法节奏，不得照抄原句」）→
`reader_context/world_fragments/style.md`。

### 5.2 注册进资料栈

调用 write 工具写 `/foreverse/assets/worlds/<id>/reader_context/prompt_stack.json`：

```
{
  "version": 1,
  "targetType": "reader_world",
  "readerTextEnabled": true,
  "blocks": [
    {"blockId": "fanfic-lore", "kind": "lore", "label": "原著世界书", "enabled": true, "order": 100,
     "risk": "normal", "sourceImportId": "agent-fanfic", "path": "reader_context/lore/fanfic-lore.json", "sha256": "", "injectsText": true},
    {"blockId": "fanfic-protagonist", "kind": "character", "label": "本书主角", "enabled": true, "order": 200,
     "risk": "normal", "sourceImportId": "agent-fanfic", "path": "reader_context/world_fragments/protagonist.md", "sha256": "", "injectsText": true},
    {"blockId": "fanfic-style", "kind": "style", "label": "原著文风样例", "enabled": true, "order": 300,
     "risk": "normal", "sourceImportId": "agent-fanfic", "path": "reader_context/world_fragments/style.md", "sha256": "", "injectsText": true}
  ]
}
```

- `path` 一律写**相对新书 world 根**的路径（越界会被拒读）；`kind` 只能是
  character/world/lore/preset/output_format/style/regex/other。
- 该文件已存在（用户先导入过资料）时**只 edit 追加 blocks，别整文件覆盖**别人的块。
- 这些块在 App 的「本书 AI 资料」页可见可开关（阅读页 → 书籍信息 → AI 资料），用户可逐块启停 / 排序——
  收尾时要告诉用户这一点。

## 6. 剧情走向控制位（收尾必须向用户讲清）

用户日后想「控制这本同人的剧情往哪走」，共有四个旋钮，从粗到细：

| 旋钮 | 位置 | 生效范围 |
| --- | --- | --- |
| 剧情走向总纲 / 世界观 | 阅读页 → 书籍信息 → 编辑世界观（`_world.md`） | 之后每一次续写 |
| 世界书词条 / 主角卡 / 文风块 | 阅读页 → 书籍信息 → AI 资料（逐块开关） | 之后每一次续写 |
| 用户偏好 / 提升词 | 续写设置里的「用户偏好」与各任务「提升词」（本书档） | 之后该书每次 / 每类任务 |
| 本次意图 | 续写时的自由输入框 / 剧情候选选项 | 仅本次生成 |

对应关系举例：用户想「以后感情线多一点」→ 改总纲或用户偏好；「这一段让他先输一次」→ 续写输入框写一句即可；
「后宫加一个角色」→ 总纲的感情线约定 + 给该角色补一条世界书词条。

## 7. 校验与收尾

1. `python /foreverse/scripts/list_chapters.py --world <新书id>` 确认章节结构正常、占位章已替换。
2. read 一遍 `_world.md` 与 prompt_stack.json 引用的每个块文件，确认路径都真实存在、JSON 可解析（lore 用 validate_lore.py）。
3. （可选）用户要封面 / 章头图时按 illustrate-novel 技能走 `generate_image.py` + `insert_media.py`。若用户指定自己的/社区导入提示词，同时读 `prompt-template-user` 技能，先 `templates.py list → show` 看完 `kind=image` 模板，再把 `--template <templateId>` 传给生图。
4. 纯文本收尾，必须包含：新书用 `[[book:<world_id>|书名]]` 指代（world_id 取 create_novel stdout；渲染成可点开读的
   链接，**别把裸 world_id 写给用户**）+ 书架状态（已上架）；访谈结论一句话回放（身份 / 立场 / CP / 走向）；
   写了几章、开头讲到哪；**哪些设定已进自动注入**（世界观总纲 + N 条世界书词条 + 主角卡 + 文风样例，每次续写自动生效）；
   §6 的四个控制旋钮各一句话；下一步建议（「打开这本书读到末尾，点续写或剧情候选试试」）。

忠于访谈：正文与设定都必须与 §0 确认的结论一致；用户中途改需求时先改 `_world.md` / 词条再改正文，保持三者不打架。
