---
name: 角色卡美化
description: 给角色卡套「主题皮肤包」——把固定 marker 输出协议渲染成整套文化母题美化（民国纸档/赛博终端/千禧Y2K/琉璃星轨/蝶梦捕梦网/深海水母/晨间手记/古风此间录/每日公报/Steam玩家主页），含状态栏/思维链/场景卡/旁白/可点选项五件；也支持简易内联卡面，以及把聊天背景升级为会动的动态视频背景（图生视频循环微动）
---

# 角色卡美化（card-beautify v2 · 主题皮肤包）

当用户说「给这张卡做美化 / 状态栏 / 像小红书那种美化 / 换个皮肤」时用。
原理：让模型输出**纯文本 marker**，由全局正则在显示时替换成主题 HTML（WebView 富渲染）。
一套皮肤 = 5 条正则（状态栏/思维链/场景卡/旁白/可点选项）同一文化母题。

## 1. 选皮肤

| 皮肤 | 母题 | 适合题材 | 模板文件 |
|---|---|---|---|
| jinmen 津门旧事 | 民国纸档·场记表·火漆印 | 民国/悬疑/年代 | `skins-jinmen.md` |
| terminal 终端回响 | 赛博终端·扫描线·故障色 | 赛博/科幻/怪谈 | `skins-terminal.md` |
| y2k 千禧电子宠物 | Win98窗口·糖果粉紫 | 网恋/电竞/整活 | `skins-y2k.md` |
| liuli 琉璃星轨 | 星云玻璃拟态·花体题字·TIME SYNC | 都市言情/星际/重逢 | `skins-liuli.md` |
| dreamnet 蝶梦捕梦网 | 深夜蓝黑玻璃·凤蝶·白羽垂饰 | 悬疑/治愈/哥特/梦境 | `skins-dreamnet.md` |
| abyss 深海水母 | 深蓝全屏融合·发光水母·竖排诗 | 沉浸/深海/寂寥/探秘 | `skins-abyss.md` |
| morning 晨间手记 | 奶油绿杂志·拱门风景画·五线谱 | 清新/日常/治愈/田园 | `skins-morning.md` |
| gufeng 古风此间录 | 宣纸竹影·时辰大字·朱批眉批·甲乙丙笺条 | 古风/权谋/宫廷/仙侠 | `skins-gufeng.md` |
| gazette 每日公报 | 复古报纸·Oxford双线报头·首字下沉·分类启事 | 民国/都市/悬疑/经营 | `skins-gazette.md` |
| gamehub 玩家主页 | Steam深蓝面板·游戏中徽·观察记录·任务列表 | 电竞/网恋/游戏/现代 | `skins-gamehub.md` |

按卡的题材选一套（一卡一母题）；用户点名要别的风格时，参考模板自创同结构的 5 条（守住第 4 节红线）。

**皮肤 = 四件套**：① 5 条正则（上表）② 背景 ③ 聊天 Chrome 主题 ④ 手绘装饰素材（可选但强烈推荐）。
- **背景**：world 目录下放 `backgrounds/main.png`（或 .jpg，1080x2400 主题底图）即触发全屏沉浸背景。
  玻璃拟态皮肤（liuli 浅色 / dreamnet 深色）**必须**配背景；实色母题（terminal/y2k/jinmen）可选。
  图片来源：用户相册、或用生图能力产一张（浅色系提示词「淡紫星云渐变 竖屏手机壁纸 星点光晕 无文字」；
  深色系「深邃普鲁士蓝夜色花园 暗蓝玫瑰藤蔓剪影 星光萤火 油画质感 深色调 无文字 竖幅」）。
  进阶：背景可以**动**（`backgrounds/main.mp4` 视频背景，优先于静态图），动效 prompt 范式与做法见 §1.5。
- **装饰素材**：world 目录下 `beautify-assets/*.webp|png`，模板 HTML 用
  `<img src="https://fv.local/beautify-assets/<文件名>" onerror="this.style.display='none'">`
  引用（宿主只映射这一个目录，file:// 不通）。素材要「手绘感」：水彩/钢笔淡彩质感、无文字、
  主体留白；用生图能力产（纯白底再抠透明），或引导用户挑图。`onerror` 必写——素材缺失时布局
  自动降级不裂图。
- **聊天 Chrome 主题**：world 目录下写 `chat-theme.json`，输入栏配色跟皮肤走 + 可关背景遮罩 +
  可切悬浮形态。字段全可选（缺省回退默认），颜色 #RRGGBB/#AARRGGBB，scrim 0~1（浅色皮肤设 0），
  `floatingInput: true` = 输入卡变悬浮玻璃胶囊（收窄+底部留空+投影；配 25%~40% 半透 inputBg
  才有玻璃感，实色母题如 y2k 窗口风保持缺省贴边）：

```
{"inputBg":"#59FFFFFF","inputText":"#332B4E","inputPlaceholder":"#77709A",
 "inputBorder":"#B3FFFFFF","inputAccent":"#8F7FC8","buttonBg":"#4DFFFFFF",
 "buttonIcon":"#5F5784","bottomScrim":0.0,"topScrim":0.0,"floatingInput":true}
```

  各皮肤模板文件末尾附推荐配色；写完 world 里重开聊天生效。

## 1.5 动态背景（把背景升级成会动的，可选）

用户说「背景能不能动 / 像猫箱那样会动 / 让 TA 活过来」时做。原理：world 目录放
`backgrounds/main.mp4`（或 .webm）即优先于静态图——聊天页全屏**静音无限循环**播放
（我们是持续呼吸感微动，比猫箱的「进场动画播一次就定格」规格更高）。

**动效 prompt 范式（写好背景动画的关键）**——图生视频，五要素缺一不可
（在 vidu 五卡 + seedance 2.0 mini 两卡上实测通过，帧差 4.1~15.7 全部落在「微动」区间）：

1. **人物原位微动**：呼吸起伏 / 眨眼 / 发丝被风拂动 / 衣摆轻晃 / 指尖轻敲——只挑 1~2 个；
   必写「人物保持原位，位置、姿态、构图不变」。
2. **神态锁定**：底图神态特殊（垂目/闭眼/侧脸/望向别处）时，必写「始终保持〈垂目〉神态，
   视线方向不变，不抬头不看镜头」——实测（seedance mini）「呼吸/眨眼」类指令会诱发模型
   让人物抬眼直视镜头，冷感/沉静人设一秒穿帮；这是最高频的漂移面。
3. **环境微动**：按画面内容挑 1~2 个——杯口热气·蒸汽 / 光斑飘移 / 云海流动 / 烛光闪烁 /
   雨丝 / 飘落的叶·雪 / 尘埃浮动 / 窗外霓虹·车流光影。
4. **镜头完全固定**：必写「镜头固定不动，无推拉摇移」——背景是底图不是短片，任何运镜都
   穿帮；此约束只能靠 prompt（实测部分模型如 seedance mini 的图生视频不收锁机位参数）。
5. **可循环**：必写「动作幅度小，首尾衔接自然，适合无缝循环播放」。

范例（写实办公室卡）：「人物保持原位轻微自然呼吸，发丝微动，手中保温杯冒出热气；窗外
车流光影缓慢移动；镜头完全固定；动作幅度小，首尾衔接自然，适合无缝循环播放」。
母题动效词参考：国风=广袖衣摆风动/云海/剑穗轻晃；哥特=烛光闪烁/琴面反光；赛璐璐=眨眼/
暖光光斑；深夜写实=屏幕蓝光呼吸/雨痕/蒸汽。

**忌**（命中一条就是废片，重写 prompt）：转头、走动、换姿势等大动作；抬眼看镜头（神态
漂移）；镜头推拉/环绕；表情剧烈变化；新元素入画；画面里生成文字。

**做法**（生成视频是付费动作，动手前先向用户确认；一条 5 秒即可）：

1. 底图 = 该卡现有立绘/背景（`backgrounds/main.png` 或 `avatar.png`，竖屏构图最佳）；
   没有就先按第 1 节生一张静态背景。
2. 图生视频（竖屏 9:16，先落草稿区）。调用 exec 工具，command：

```
python /foreverse/scripts/generate_video.py --prompt "<按上面范式写>" --duration 5 --aspect 9:16 --first-frame /foreverse/assets/worlds/<worldId>/backgrounds/main.png --world <worldId> --out /workspace/dyn-bg.mp4
```

3. 挪进 backgrounds/（generate_video 的 --out 白名单不含 backgrounds/，用 python 收尾）：

```
python -c "import os; os.makedirs('/foreverse/assets/worlds/<worldId>/backgrounds', exist_ok=True); os.replace('/workspace/dyn-bg.mp4', '/foreverse/assets/worlds/<worldId>/backgrounds/main.mp4')"
```

4. **保留静态 main.png 不删**：视频观感不对时删掉 main.mp4 即回退静态；进场首帧可能有
   一瞬黑屏属已知瞬态，不用修。重开聊天生效。

生成失败排查：报「疑似真人/敏感内容」= 该上游对写实人像有输入审核硬闸（豆包 seedance
直连实测如此），换绘画感底图或换别的视频模型再试，不要反复重交同一张图白花钱。

## 2. marker 契约（固定，不要改）

```
:::think 内心推演，≤3句 :::
[状态|F1|F2|F3|F4]           ← 4 字段，字段名按卡主题化（如 场号/所在/时刻/心绪）
:::scene 标题 # 正文 :::
:::note 一句旁白 :::
:::opt 行动A ¦ 行动B ¦ 行动C :::   ← ¦ 是 U+00A6，点击可回填输入框
```

## 3. 工作流

1. 读目标卡：read `/foreverse/assets/st-library/characters/cards/<libraryId>/card.md`；
   没有卡就先用 `card-from-novel` 或 `card-author` 写一张（**内容层规程在那边**，本 skill 只管表现层）。
2. read 选中的 `skins-<id>.md`，把模板里 `__HEAD__` 换成 2 字印章/标题字、`__F1__..__F4__` 换成状态栏字段名。
3. 写全局正则包 `/workspace/beautify-pack.json`（数组，5 个对象）：
   `{"id":"fvb-<卡slug>-think","name":"[FVB] <卡名> 思维链","find":"<模板文件给的find>","replace":"<替换后的HTML>","placement":["AI_OUTPUT"],"markdownOnly":true}`
   ——five 条的 find 原样抄模板文件，replace 用第 2 步产物。
4. 逐条校验后入库（工具同「编写正则」skill）：
   `python /foreverse/scripts/validate_regex.py /workspace/beautify-pack.json`
   `python /foreverse/scripts/import_regex.py /workspace/beautify-pack.json`
5. 给卡接上输出协议：edit 卡的 `## System Prompt` 段，追加（{{char}}/{{user}} 只能出现在这里，不能进开场白）：

```
严格遵守输出格式（只输出纯文本 marker，不输出 HTML）：
1) 可选 :::think 观察推理≤3句 :::
2) 必须 [状态|F1|F2|F3|F4]（字段随剧情更新）
3) :::scene 标题 # 正文 :::
4) 可选 :::note 旁白 :::
5) 结尾必须 :::opt 行动A ¦ 行动B ¦ 行动C :::
```

6. 开场白改造：把 first_mes 重写为演示全套 marker 的版本（think/状态/scene/opt 至少各一），
   让用户第一眼就看到皮肤效果。开场白里**禁止** `{{char}}/{{user}}`（显示期不展开会漏出）。

## 4. 红线（违反=不渲染或坏版面）

- marker 是纯文本，HTML 只出现在正则 replace；模板禁外链图片/字体/音频（本地素材走
  `https://fv.local/beautify-assets/` 通道）；单条 replace ≤30KB。
- 选项必须 `class="choice-item" data-choice="$n"`（宿主自动接管点击回填输入框），禁自写 onclick。
- 状态栏固定 4 字段（引擎不支持变长回引）。
- 正则顺序：think → status → scene → opt → note。
- `<details>` summary 自带折叠提示要挂 `class="fvb-fold-hint"`，否则宿主再补三角变双箭头。

## 4.5 去 AI 味守则（自创皮肤/改模板时必守——违反就会被用户看出「模板感」）

- **图标禁 emoji**：用内联 SVG 细线图形（stroke-width 1~1.2）或素材图；✧✦ 只做点缀。
- **布局破方正**：选项卡不等圆角（`6px 20px 20px 20px` 尖角轮换）+ 左右错落缩进；
  便签卡微斜置（rotate ±0.4~0.8deg）；字段行缩进分级，不许全顶格。
- **大小对比拉满**：一处超大（46px+ 超细体时钟/花体渐变标题）压一片 9px 拉宽字距英文小标签。
- **素材出血**：装饰图至少一处溢出卡缘（负 margin/绝对定位 + 微旋转）。
- **色彩单族**：紫/蓝系皮肤在模板头注入 `<style>q{color:#xxx !important;}</style>`
  统一台词色（宿主默认橙金，撞色穿帮）。
- **深色玻璃母题（dreamnet 类）**：阴影全换发光（外发光 + `inset 0 1px rgba(255,255,255,.14)`
  顶边高光）；文字禁纯白（.9 透明度上限）、关键数字加冷光 text-shadow；浅色主体素材
  （白羽毛类）生图时用**纯黑底**出图再抠透明（白底会把主体一起抠没）。
- **全屏融合母题（abyss 类）**：去容器——卡底色压到 `rgba(…,.2~.44)` + blur，边框只留虚线，
  可读性靠深色 text-shadow；背景图就是皮肤本体，必须先推 `backgrounds/main.jpg` 再装正则。
- **带构图的画不抠图**：拱门风景画/相框照片类保留完整矩形，CSS 圆角
  （`border-radius:150px 150px 10px 10px`）+ `overflow:hidden` 裁形、文字直接叠印画上；
  抠透明只给贴纸类主体。
- **中式古典母题（gufeng 类）**：破规=书画装裱语言——水墨素材出血 opacity ≤.6 压进纸面、
  印章钤卡角与正文微交叠、角框只做对角两角、选项**去边框**改左竖线三色+纸色微差+微斜
  （有边框圆角=功能按钮，纸条才像古籍页）；衬线字族 + 正文行距 2.0+；时间用母题概念
  （时辰/年号）替代西式时钟。
- **实体纸母题（gazette 类）**：与玻璃拟态正相反——卡底**不透明纸色**（#f6efdb + 纸斑
  radial-gradient），全程无 backdrop-filter；投影用重落影 `0 14px 34px rgba(16,10,3,.5)`
  （纸片拼贴在深色桌面上）而非柔影；破规=报纸排版语法（Oxford 双线一粗一细/点线 leader
  发行栏/首字下沉/全大写拉宽英文小标）+ 做旧痕迹（咖啡渍 multiply 钤角、邮票出血、
  剪角优惠券启事）；边框压 `rgba(74,62,46,.7)` 别用纯黑；油墨感靠 `.2px` 极轻 text-shadow。
- **系统 UI 拟态母题（gamehub 类）**：直角扁平面板 + 蓝灰层级本身就是「真」，去 AI 味**不靠
  歪斜做旧**（斜置反而穿帮），靠：①边界感压到最低——border `rgba(120,160,190,.08~.12)`、
  无大圆角、阴影只做贴地暗影不做发光；②内容颗粒（等级数字/DONE 时间戳/已完成删除线行/
  「仅自己可见」锁标）替代装饰；③红绿点缀只准撒在语义位（等级章红/在线绿/收藏红心），
  面积 <5%；④像素素材加 `image-rendering:pixelated` 保持锯齿味。

## 5. 收尾（纯文本，不调用工具）

> 已装好「<皮肤名>」皮肤包（全局正则 5 条）并给《<卡名>》接上输出协议。重开聊天即可看到：
> 场记表状态栏 / 折叠思维链 / 场景卡 / 可点选项（点选项会自动填进输入框）。
> 若看到的是 `:::think` 原文，请到聊天设置确认「美化渲染（HTML/CSS）」已开启。
