import 'dart:convert';
import 'package:http/http.dart' as http;

/// AG 智能体客户端 — 接外部 API（ant-ling 在线 / 本地 llama.cpp）
/// Wave 集成：全局管控 + 游戏决策 + 对话
class AgentClient {
  // 外部 API 配置（用户在设置里填）
  static String baseUrl = 'https://api.ant-ling.com/v1';
  static String apiKey = '';
  static String model = 'Ling-3.1-flash';
  // 本地备选
  static const localUrl = 'http://127.0.0.1:8001/v1';

  static bool get isConfigured => baseUrl.isNotEmpty;

  /// 聊天补全
  static Future<String> chat(List<Map<String, String>> messages) async {
    final url = Uri.parse('$baseUrl/chat/completions');
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'stream': false,
    });
    try {
      final resp = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final content = data['choices'][0]['message']['content'];
        return content?.toString() ?? '';
      }
      return '错误 ${resp.statusCode}: ${resp.body}';
    } catch (e) {
      return '连接失败: $e';
    }
  }

  /// 流式聊天（逐字回调）
  static Future<void> chatStream(
    List<Map<String, String>> messages,
    void Function(String chunk) onChunk,
  ) async {
    final url = Uri.parse('$baseUrl/chat/completions');
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'stream': true,
    });
    final req = http.Request('POST', url)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Type'] = 'application/json'
      ..body = body;
    final stream = await req.send();
    await for (final chunk in stream.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ') && line != 'data: [DONE]') {
          try {
            final d = jsonDecode(line.substring(6));
            final delta = d['choices'][0]['delta']['content'];
            if (delta != null) onChunk(delta.toString());
          } catch (_) {}
        }
      }
    }
  }

  /// 测活
  static Future<bool> ping() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}