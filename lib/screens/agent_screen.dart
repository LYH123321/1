import 'package:flutter/material.dart';
import '../services/agent_client.dart';

/// AG 智能体面板 — 聊天 / 配置 / 游戏决策
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
  String _apiUrl = AgentClient.baseUrl;
  String _apiKey = AgentClient.apiKey;
  String _model = AgentClient.model;
  bool _thinking = false;

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _thinking = true;
    });
    _ctrl.clear();
    AgentClient.chat(_messages).then((reply) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _thinking = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AG 智能体'),
        actions: [
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
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length - 1 + (_thinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length - 1 && _thinking) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('思考中…'),
                    ]),
                  );
                }
                final m = _messages[i + 1]; // 跳过 system
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: '和 AG 聊天…'))),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfig() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AG 配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'API 地址'),
              controller: TextEditingController(text: _apiUrl),
              onChanged: (v) => _apiUrl = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'API Key'),
              controller: TextEditingController(text: _apiKey),
              onChanged: (v) => _apiKey = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: '模型'),
              controller: TextEditingController(text: _model),
              onChanged: (v) => _model = v,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                AgentClient.baseUrl = _apiUrl;
                AgentClient.apiKey = _apiKey;
                AgentClient.model = _model;
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}