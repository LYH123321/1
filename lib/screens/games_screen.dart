import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// 游戏厅 — 内置大富翁 / 斗地主（WebView 加载本地 HTML）
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _sel = 0;
  final _games = const [
    {'name': '大富翁', 'file': 'assets/games/monopoly/index.html'},
    {'name': '斗地主', 'file': 'assets/games/doudizhu/index.html'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('游戏厅')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _games.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: ChoiceChip(
                  label: Text(_games[i]['name']!),
                  selected: _sel == i,
                  onSelected: (_) => setState(() => _sel = i),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildWebView(_games[_sel]['file']!),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(String asset) {
    late final WebViewController controller;
    if (Platform.isAndroid) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0B0B0F))
        ..loadFlutterAsset(asset);
      (controller.platform as AndroidWebViewController)
        ..setMediaPlaybackRequiresUserGesture(false);
    } else {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFlutterAsset(asset);
    }
    return WebViewWidget(controller: controller);
  }
}