import 'package:flutter/material.dart';
import '../services/agent_client.dart';
import '../theme.dart';

/// AG 智能体面板 — 流式聊天 / 配置持久化
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
                          'content':
                              '你是卡芙卡，一个病娇妈妈。温柔但占有欲极强。'
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