import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AG 智能体客户端 — 接外部 API（ant-ling 在线 / 本地 llama.cpp）
/// v2: 配置持久化 + 超时 + 本地自动回退
class AgentClient {
  static const _kUrl = 'ag_base_url';
  static const _kKey = 'ag_api_key';
  static const _kModel = 'ag_model';
  static const _kTimeout = Duration(seconds: 60);

  static String baseUrl = 'https://api.ant-ling.com/v1';
  static String apiKey = '';
  static String model = 'Ling-3.1-flash';
  static const localUrl = 'http://127.0.0.1:8001/v1';
  static const localModel = 'Ternary-Bonsai-4B-abliterated-Q4_K_M';

  static bool get isConfigured => baseUrl.isNotEmpty;

  /// 启动时恢复配置（在 AgentScreen initState 调一次）
  static Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      baseUrl = sp.getString(_kUrl) ?? baseUrl;
      apiKey = sp.getString(_kKey) ?? '';
      model = sp.getString(_kModel) ?? model;
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kUrl, baseUrl);
      await sp.setString(_kKey, apiKey);
      await sp.setString(_kModel, model);
    } catch (_) {}
  }

  static Map<String, String> _headers() => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  /// 聊天补全（非流式，带超时；主端点失败自动回退本地）
  static Future<String> chat(List<Map<String, String>> messages) async {
    final r = await _chatOnce('$baseUrl/chat/completions', model, messages)
        .timeout(_kTimeout, onTimeout: () => '⏱ 请求超时（60s）');
    if (!_isError(r)) return r;
    // 回退本地 llama.cpp
    final lr = await _chatOnce(
            '$localUrl/chat/completions', localModel, messages)
        .timeout(_kTimeout, onTimeout: () => '⏱ 本地服务也超时');
    return _isError(lr) ? '$r\n（本地回退也失败）' : '$lr\n\n—（来自本地模型）';
  }

  static bool _isError(String s) =>
      s.startsWith('错误') || s.startsWith('连接失败') || s.startsWith('⏱');

  static Future<String> _chatOnce(String url, String m,
      List<Map<String, String>> messages) async {
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: _headers(),
        body: jsonEncode({
          'model': m,
          'messages': messages,
          'temperature': 0.7,
          'stream': false,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['choices']?[0]?['message']?['content']?.toString() ?? '';
      }
      final b = resp.body;
      return '错误 ${resp.statusCode}: ${b.length > 200 ? b.substring(0, 200) : b}';
    } catch (e) {
      return '连接失败: $e';
    }
  }

  /// 流式聊天（逐字回调）；返回完整文本。失败自动回退非流式。
  static Future<String> chatStream(
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
    final buf = StringBuffer();
    try {
      final req = http.Request('POST', url)
        ..headers.addAll(_headers())
        ..body = body;
      final stream = await req.send().timeout(_kTimeout);
      await for (final chunk in stream.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          final l = line.trim();
          if (!l.startsWith('data: ') || l == 'data: [DONE]') continue;
          try {
            final d = jsonDecode(l.substring(6));
            final delta = d['choices']?[0]?['delta']?['content'];
            if (delta != null && delta.toString().isNotEmpty) {
              buf.write(delta);
              onChunk(delta.toString());
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      if (buf.isEmpty) {
        final fb = await chat(messages);
        final text = fb.isNotEmpty ? fb : '\n[连接失败: $e]';
        onChunk(text);
        buf.write(text);
      }
    }
    return buf.toString();
  }

  /// 测活
  static Future<bool> ping() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/models'), headers: _headers())
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}