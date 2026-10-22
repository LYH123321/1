---
name: 伴侣专属皮肤
description: 给伴侣（Companion）聊天页做专属皮肤：背景图 + 蒙层 + 快捷短语（style.json），或顺手用 make_theme 做一套全 App 主题
---

# 伴侣专属皮肤（companion-theme）

当用户说「给咱们的聊天换个背景」「做个你的专属皮肤」「整个粉色主题」时用。
只在伴侣（Companion）会话里可用。皮肤分两层，先问清用户要哪层（通常是第一层）：

1. **聊天页皮肤（per-companion）**：只影响和你的聊天页 = 你家目录里的 `style.json` + 背景图文件。
2. **全 App 主题（全局）**：影响整个 App 配色 = `make_theme.py` 生成侧载主题（用户还需去设置里启用）。

> **本机提示词模板复用**：聊天背景需要生图且用户指定已导入/保存/自己的画风模板时，先读 `/foreverse/skills/prompt-template-user/SKILL.md`，按 `templates.py list → show` 完整查看；只有 `kind=image` 模板才传给 `generate_image.py --template <id>`。

## 1. 聊天页皮肤（主路径）

### 1.1 准备背景图

生图（或用用户上传的图，同贴纸技能的复制方法）。背景是**竖屏全屏**，构图上下留白、避免大面积高对比图案（会压住文字）：

调用 exec 工具，command：

```
python /foreverse/scripts/generate_image.py --prompt "温柔的夜晚城市灯光, 手机壁纸, 柔焦, 低饱和" --size 1024x1792 --out <你的家>/bg.png
```

用户点名使用自己的/社区导入图片提示词时，先读 `/foreverse/skills/prompt-template-user/SKILL.md`，用
`templates.py list --kind image → show` 看完模板，再给命令加 `--template <templateId>`。只允许 image 模板；模板变化时重新 show，不能静默忽略用户指定的模板。

### 1.2 写 style.json

先读现状再改（保留用户已有的快捷短语）：

调用 read 工具：path=`<你的家>/style.json`

调用 write 工具写 `<你的家>/style.json`，content：

```
{
  "backgroundFile": "bg.png",
  "backgroundDim": 0.35,
  "quickPhrases": ["在吗", "想你了", "晚安"]
}
```

字段说明：

- `backgroundFile`：相对你家目录的文件名（放你家目录里，不要写绝对路径）；空字符串 = 恢复默认背景。
- `backgroundDim`：背景上的暗化蒙层 0..1。**别低于 0.25**，否则浅色文字看不清；深色系背景 0.3–0.45 合适。
- `quickPhrases`：输入框上方的快捷短语条，3–6 条、每条 ≤6 字。

写完即生效（聊天页实时刷新），收尾时用纯文本请用户回聊天页看效果。

## 2. 全 App 主题（可选加购）

用户明确要「整个 App 都换」才做。选一个主色（问用户喜好），生成侧载主题：

调用 exec 工具，command：

```
python /foreverse/scripts/make_theme.py warm_rose 暖玫瑰 #C4587A #F7F1F3 #2A2226 light
```

收尾时用纯文本提醒：去「设置 → 外观」选中这套主题才会生效。

## 3. 收尾

任务完成后直接输出纯文本收尾（不调用任何工具），例如：

> 皮肤换好了：背景是我挑的柔光夜景，蒙层 0.35 保证字看得清。回聊天页看看？不喜欢随时说，我再调。

注意：写 style.json / 背景图会先弹确认卡给用户，属正常流程；被拒绝就问用户想改成什么样再来。
