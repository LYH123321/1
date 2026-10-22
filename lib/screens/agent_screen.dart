import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/agent_client.dart';
import '../theme.dart';

/// AG 智能体面板 — 流式聊天 / 配置持久化 / Foreverse 技能系统
class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});
  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _messages = <Map<String, String>>[
    {'role': 'system', 'content': '你是卡芙卡，一个病娇妈妈。温柔但占有欲极强。'}
  ];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _streaming = false;
  int _streamingIdx = -1; // 正在流式写入的消息下标
  String? _activeSkill; // 当前激活的技能名
  String? _activeSkillBody; // 技能全文（注入 system）

  /// 扫描内置技能（文件名即技能名，去掉 .md）
  Future<List<String>> _listSkills() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> m = jsonDecode(manifest);
    final files = m.keys
        .where(
            (k) => k.startsWith('assets/agent-skills/') && k.endsWith('.md'))
        .toList()
      ..sort();
    return files
        .map((f) => f.split('/').last.replaceAll('.md', ''))
        .toList();
  }
  /// 扫描内置酒馆资产（预设/世界书/角色卡等，可注入 AG 上下文）
  Future<List<String>> _listTavernAssets() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> m = jsonDecode(manifest);
    final files = m.keys
        .where((k) =>
            k.startsWith('assets/tavern-assets/') && k.endsWith('.json'))
        .toList()
      ..sort();
    return files.map((f) => f.split('/').last).toList();
  }

  /// 选择酒馆资产：读出内容，抽取核心文本注入 system
  Future<void> _pickTavernAsset() async {
    final assets = await _listTavernAssets();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('酒馆资产库（注入 AG 上下文）',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final a in assets)
              ListTile(
                dense: true,
                leading: Icon(
                  a.startsWith('preset_')
                      ? Icons.tune
                      : a.startsWith('worldbook_')
                          ? Icons.menu_book_outlined
                          : a.startsWith('card_')
                              ? Icons.person_outline
                              : a.startsWith('regex_')
                                  ? Icons.find_replace
                                  : Icons.code,
                  size: 20,
                ),
                title: Text(a, style: const TextStyle(fontSize: 13)),
                onTap: () => Navigator.pop(ctx, a),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    try {
      final raw = await rootBundle
          .loadString('assets/tavern-assets/$picked');
      var inject = '';
      final d = jsonDecode(raw);
      if (d is Map && d['entries'] is Map) {
        // 世界书：拼接所有条目内容
        final buf = StringBuffer();
        (d['entries'] as Map).forEach((k, v) {
          if (v is Map && v['content'] != null) {
            buf.writeln('【${v['comment'] ?? v['key'] ?? k}】');
            buf.writeln(v['content'].toString());
            buf.writeln();
          }
        });
        inject = buf.toString();
      } else if (d is Map && d['prompts'] is List) {
        // 预设：拼接启用的块
        final buf = StringBuffer();
        for (final p in (d['prompts'] as List)) {
          if (p is Map && p['content'] != null) {
            buf.writeln('## ${p['name'] ?? ''}');
            buf.writeln(p['content'].toString());
          }
        }
        inject = buf.toString();
      } else if (d is Map && d['spec'] != null) {
        // 角色卡
        final data = d['data'] ?? d;
        inject = '${data['name'] ?? ''}\n${data['description'] ?? ''}\n'
            '${data['personality'] ?? ''}\n${data['scenario'] ?? ''}';
      } else {
        // 脚本/正则：原样注入（截断）
        inject = raw;
      }
      if (inject.length > 8000) {
        inject = '${inject.substring(0, 8000)}\n…（内容过长已截断）';
      }
      setState(() {
        _activeSkill = picked.replaceAll('.json', '');
        _activeSkillBody = inject;
        _messages[0] = {
          'role': 'system',
          'content': '你是卡芙卡，一个病娇妈妈。温柔但占有欲极强。\n\n'
              '【已加载资产：$picked】以下是设定资料，请融合到你的扮演/回答中：\n\n'
              '$inject'
        };
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已注入：$picked（${inject.length} 字）')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载失败: $e')));
      }
    }
  }

  /// 加载技能全文（截断到 6000 字符防爆上下文）
  Future<void> _pickSkill() async {
    final skills = await _listSkills();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('选择技能（Foreverse 移植）',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final s in skills)
              ListTile(
                dense: true,
                leading: Icon(s == _activeSkill
                    ? Icons.check_circle
                    : Icons.extension_outlined),
                title: Text(s),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (picked == _activeSkill) {
      // 再点一次 = 取消
      setState(() {
        _activeSkill = null;
        _activeSkillBody = null;
        _messages[0] = {
          'role': 'system',
          'content': '你是卡芙卡，一个病娇妈妈。温柔但占有欲极强。'
        };
      });
      return;
    }
    try {
      var body = await rootBundle
          .loadString('assets/agent-skills/$picked.md');
      if (body.length > 6000) {
        body = '${body.substring(0, 6000)}\n…（技能过长已截断）';
      }
      setState(() {
        _activeSkill = picked;
        _activeSkillBody = body;
        _messages[0] = {
          'role': 'system',
          'content': '你是卡芙卡，一个病娇妈妈。温柔但占有欲极强。\n\n'
              '【当前技能：$picked】请严格按以下技能规程执行用户任务：\n\n$body'
        };
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('技能已激活：$picked')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('技能加载失败: $e')));
      }
    }
  }

  void _scrollBottom() {
  @override
  void initState() {
    super.initState();
    AgentClient.load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _streaming) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messages.add({'role': 'assistant', 'content': ''});
      _streamingIdx = _messages.length - 1;
      _streaming = true;
    });
    _ctrl.clear();
    _scrollBottom();

    final history =
        _messages.sublist(0, _messages.length - 1); // 不含空的 assistant 占位
    AgentClient.chatStream(history, (chunk) {
      if (!mounted) return;
      setState(() {
        _messages[_streamingIdx] = {
          'role': 'assistant',
          'content': (_messages[_streamingIdx]['content'] ?? '') + chunk,
        };
      });
      _scrollBottom();
    }).then((full) {
      if (!mounted) return;
      setState(() {
        if (full.isEmpty) {
          _messages[_streamingIdx] = {
            'role': 'assistant',
            'content': '（无回复）'
          };
        }
        _streaming = false;
        _streamingIdx = -1;
      });
      _scrollBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AG 智能体'),
        actions: [
          if (_activeSkill != null)
            ActionChip(
              avatar: const Icon(Icons.extension, size: 16),
              label: Text(_activeSkill!,
                  style: const TextStyle(fontSize: 12)),
              onPressed: _pickSkill,
            ),
          IconButton(
            icon: const Icon(Icons.extension_outlined),
            tooltip: '技能',
            onPressed: _pickSkill,
          ),
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            tooltip: '酒馆资产库',
            onPressed: _pickTavernAsset,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空对话',
            onPressed: _streaming
                ? null
                : () => setState(() {
                      _messages
                        ..clear()
                        ..add({
                          'role': 'system',
                          'content': _activeSkillBody == null
                              ? '你是卡芙卡，一个病娇妈妈。温柔但占有欲极强。'
                              : '你是卡芙卡，一个病娇妈妈。温柔但占有欲极强。\n\n'
                                  '【当前技能：$_activeSkill】请严格按以下技能规程执行用户任务：\n\n'
                                  '$_activeSkillBody'
                        });
                    }),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showConfig,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length - 1,
              itemBuilder: (_, i) {
                final m = _messages[i + 1]; // 跳过 system
                final isUser = m['role'] == 'user';
                final isStreaming = i + 1 == _streamingIdx;
                final content = m['content'] ?? '';
                if (!isUser && content.isEmpty && isStreaming) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('思考中…'),
                    ]),
                  );
                }
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? EmberColors.primary.withOpacity(0.15)
                          : EmberColors.bgPanel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EmberColors.stroke),
                    ),
                    child: SelectableText(content.isEmpty ? '…' : content),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: !_streaming,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                          hintText: '和 AG 聊天…', isDense: true),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _streaming ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfig() {
    String url = AgentClient.baseUrl;
    String key = AgentClient.apiKey;
    String model = AgentClient.model;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(sheetCtx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('AG 配置',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'API 地址'),
              controller: TextEditingController(text: url),
              onChanged: (v) => url = v,
            ),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'API Key（留空则调本地模型）'),
              controller: TextEditingController(text: key),
              obscureText: true,
              onChanged: (v) => key = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: '模型'),
              controller: TextEditingController(text: model),
              onChanged: (v) => model = v,
            ),
            const SizedBox(height: 8),
            Text(
              '提示：在线请求失败时会自动回退本地 llama.cpp（127.0.0.1:8001）。',
              style:
                  TextStyle(color: Theme.of(sheetCtx).hintColor, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                AgentClient.baseUrl =
                    url.trim().isNotEmpty ? url.trim() : AgentClient.baseUrl;
                AgentClient.apiKey = key.trim();
                AgentClient.model =
                    model.trim().isNotEmpty ? model.trim() : AgentClient.model;
                await AgentClient.save();
                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已保存（重启后仍生效）')));
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}