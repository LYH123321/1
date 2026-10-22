---
name: task-operations
description: 查看、取消或发布后台任务，并发起整库备份；用户问进度、要离场继续或要导出备份时按需读取
---

# 后台任务与整库备份

## 1. 查任务

```text
python /foreverse/scripts/tasks.py list
python /foreverse/scripts/tasks.py status --id <taskType>:<taskKey>
```

- list/status 只读免确认。进行中状态取 FvTaskEngine 进程内快照；最近记录取恢复登记表。
- 登记表只是索引，不是业务真断点。若显示「登记为 RUNNING 但当前不在运行」，说明可能被进程重启或系统
  中断；不要声称仍在跑，按回执指向任务面板/恢复卡。
- id 按第一个冒号分开，taskKey 自己可以继续含冒号；始终照 list 返回的完整 id 使用。

## 2. 取消任务

```text
python /foreverse/scripts/tasks.py cancel --id <taskType>:<taskKey>
```

- cancel 是 STRONG 确认，即使自动模式也必须让用户看卡。
- 它只发协作式取消请求：任务在最近安全点停；已经开始的付费段仍会跑完并计费，费用不退。
- 已有内容不会因取消自动删除；是否存在完整/部分产物要看该任务终态与业务真断点。
- 取消后再用 status 查终态。任务已经结束时会拒绝 cancel，不要反复提交。

## 3. 发布一个离场后继续的任务

```text
python /foreverse/scripts/tasks.py publish --title "任务名称" --prompt "要完成的事情" [--budget 3000]
```

- publish 是付费后台任务，必须先让用户看到确认卡；不要因为用户只说了“帮我做”就偷偷发布。
- 适合已经明确目标的长任务。需求还在讨论时先留在本机 Agent 对话里澄清，不要过早下单。
- 接单后本地 Agent 立即返回 task id，不占着回合等结果；用户可以离开 App，之后在「后台任务」或
  `tasks.py status` 查看。
- 服务端接单结果不明时严禁自动重发，避免同一任务重复扣费；按回执稍后去「后台任务」找回。
- `--budget` 是该任务预算上限，不是承诺一定花完；最终按实际用量结算。

## 4. 发起整库备份导出

```text
python /foreverse/scripts/backup.py export
```

- 这是 Pro 的整库备份能力；恢复自己的备份包仍永久免费，但恢复只在「设置 → 备份」人工确认，不提供
  `backup.py restore`。
- export 只负责启动 FvTaskEngine 长任务并立即返回 task id，不在 Agent 回合里私建后台协程。
- 任务零 AI 费用；完成后 zip 保存到系统 `Download/Foreverse`，包含书籍、角色、世界书、预设、正则等，
  BYOK 密钥、登录 token、私密 prefs 与受保护社区内容不进包。
- 用返回的 id 接 `tasks.py status` 查进度。重复发起同一进行中任务不会并跑第二份。
- 打包失败没有模型费用；按 status 的失败原因处理后可重试。不要把「备份失败」说成数据丢失——原资料库
  不会被修改。

