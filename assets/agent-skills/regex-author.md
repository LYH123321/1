---
name: 编写正则
description: 按需求写一条酒馆式正则规则（清理标签/替换显示/隐藏思考块等）并入库生效
---

# 编写正则（regex-author）

当用户说「帮我写条正则把 X 去掉 / 换成 Y」「隐藏状态块 / 清理模型多余标签」时用。
正则 = 对消息文本的查找替换规则，可作用于 AI 输出、用户输入或世界书。

## 1. 明确作用对象与目标

确认：改谁（AI 输出 / 用户输入 / 世界书）、查什么、换成什么、是只影响显示还是也影响上行 prompt。

## 2. 写正则 JSON 到 /workspace

字段：
- `id`：稳定短 id（如 `hide-status`）。
- `name`：人类可读名。
- `find`：正则 pattern（不含 `/ /` 分隔符；JSON 里反斜杠要写成 `\\`）。
- `replace`：替换串，支持 `$1`、`{{match}}`（整段）、空串=删除。
- `placement`：作用域数组，取值 `AI_OUTPUT` / `USER_INPUT` / `WORLD_INFO`（还有 `SLASH_COMMAND` / `REASONING`）。
- 可选：`markdownOnly`(仅渲染时)、`promptOnly`(仅上行时)、`minDepth`/`maxDepth`、`trimOut:[..]`。

示例（隐藏 AI 输出里的 `<status>…</status>` 块，只影响显示）：

调用 write 工具写 `/workspace/regex.json`，content：

```
{"id":"hide-status","name":"隐藏状态块","find":"<status>[\\s\\S]*?</status>","replace":"","placement":["AI_OUTPUT"],"markdownOnly":true}
```

## 3. 校验

调用 exec 工具，command：

```
python /foreverse/scripts/validate_regex.py /workspace/regex.json
```

校验会检查 JSON 合法 + find 能否编译。报错就 edit 修，重校验到 OK。

## 4. 入库并生效

调用 exec 工具，command：

```
python /foreverse/scripts/import_regex.py /workspace/regex.json
```

这一步会**入库并追加为全局生效正则**，需要用户确认一次。stdout 给出 `name=` 与 `placement=`。

## 5. 收尾

任务完成后直接输出纯文本收尾（不调用任何工具），例如：

> 已写好正则「隐藏状态块」并设为全局生效，作用于 AI 输出的显示。要不要我再加一条作用于上行 prompt 的？

注意：`find` 写复杂模式时务必先 validate（无法编译的 pattern 装进去运行期会报错）；拿不准就用更窄的匹配，避免误删正文。
