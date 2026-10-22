// Wave CY.18.202 — "Behaviors" sub-screen.
//
// Holds the generation / interaction BEHAVIOUR options lifted out of
// the old flat Chat Settings screen:
//   • Delete behavior        (what deleting a message does)
//   • Ask persona on new chat
//
// Delete behavior + Ask persona bind to `ChatSettings` (persist via
// updateChatSettings). Audit B4(b) (owner-decided): the "Streaming" toggle
// that used to live here (bound to the global `ModelSettings.stream`) was
// removed — no send path ever consulted that field, so flipping it did
// nothing observable. `ModelSettings.stream` itself stays parsed (backup/
// sync compat); it's just no longer surfaced in the UI.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/how_it_works_card.dart';

class ChatBehaviorsScreen extends StatefulWidget {
  const ChatBehaviorsScreen({super.key});

  @override
  State<ChatBehaviorsScreen> createState() => _ChatBehaviorsScreenState();
}

class _ChatBehaviorsScreenState extends State<ChatBehaviorsScreen> {
  late ChatSettings _draft;

  @override
  void initState() {
    super.initState();
    // Audit presets-regex-appearance-01: carry ALL 15 ChatSettings fields into
    // the draft via copyWith(). This screen only edits deleteBehavior +
    // askPersonaOnNewChat, but `updateChatSettings` does a FULL replace — so a
    // partial draft (the old code copied only 7 fields) silently reset every
    // bubble/background customization to its constructor default on commit.
    // Cloning the live settings preserves the 8 appearance fields this screen
    // doesn't manage.
    _draft = context.read<AppStore>().chatSettings.copyWith();
  }

  void _commit() => context.read<AppStore>().updateChatSettings(_draft);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行为设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // ── How it works ──────────────────────────────────────────────
          const HowItWorksCard(
            title: '行为设置说明',
            subtitle: '每个开关控制什么。',
            sections: [
              HowItWorksSection('这是什么', [
                HowItWorksBlock.paragraph(
                    '这些设置控制聊天过程中的**行为** —— 删除消息时做什么、'
                    '新建聊天是否先选人设、回复生成时如何显示。'),
                HowItWorksBlock.paragraph(
                    '它们是**全局设置** —— 对所有聊天生效，'
                    '不只是当前这个。'),
              ]),
              HowItWorksSection('各开关说明', [
                HowItWorksBlock.bullet(
                    '**删除行为** —— 选择删除一条消息时，是只删这一条，'
                    '还是连它之后的所有消息一起删除。'),
                HowItWorksBlock.bullet(
                    '**新聊天询问人设** —— 开启后，新建聊天会先弹出人设'
                    '选择器；关闭后自动使用默认人设。'),
                // Audit B4(b): the Streaming bullet left with its toggle —
                // replies always stream; describing a removed switch here
                // would be stale help text.
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('删除行为',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '在聊天中删除一条消息时的处理方式。',
                    style:
                        TextStyle(color: EmberColors.textMid, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<DeleteBehavior>(
                    segments: const [
                      ButtonSegment(
                        value: DeleteBehavior.onlyThis,
                        label: Text('仅此消息'),
                      ),
                      ButtonSegment(
                        value: DeleteBehavior.thisAndAfter,
                        label: Text('此消息及之后'),
                      ),
                    ],
                    selected: {_draft.deleteBehavior},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) {
                      setState(() => _draft.deleteBehavior = s.first);
                      _commit();
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected)
                            ? EmberColors.primary
                            : EmberColors.bgElevated;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected)
                            ? Colors.white
                            : EmberColors.textMid;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Wave CY.15: persona-on-new-chat behaviour
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: SwitchListTile(
              title: const Text('新聊天询问人设',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '开启后，新建角色聊天会先弹出人设选择器；关闭后自动使用默认人设。',
                style:
                    TextStyle(color: EmberColors.textMid, fontSize: 12),
              ),
              value: _draft.askPersonaOnNewChat,
              activeThumbColor: EmberColors.primary,
              onChanged: (v) {
                setState(() => _draft.askPersonaOnNewChat = v);
                _commit();
              },
            ),
          ),
          // Audit B4(b): the "Streaming" toggle (bound to the global
          // `ModelSettings.stream`) was removed 1.2.1 — no send path ever
          // consulted that field, so flipping it did nothing observable.
          // `ModelSettings.stream` itself stays (backup/sync compat).
        ],
      ),
    );
  }
}
