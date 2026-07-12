import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/community_service.dart';
import '../theme/app_theme.dart';

/// Realtime group chat. Loads history, then streams new messages live.
class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _community = CommunityService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _blocked = {};
  RealtimeChannel? _channel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final blocked = await _community.blockedUserIds();
      final history = await _community.messageHistory(widget.groupId);
      if (!mounted) return;
      setState(() {
        _blocked
          ..clear()
          ..addAll(blocked);
        _messages
          ..clear()
          ..addAll(history.where((m) => !_blocked.contains(m['sender_id'])));
        _loading = false;
      });
      _channel = _community.groupMessages(widget.groupId, (msg) {
        if (!mounted) return;
        // Hide blocked members and avoid duplicating a message we already have.
        if (_blocked.contains(msg['sender_id'])) return;
        if (_messages.any((m) => m['id'] == msg['id'])) return;
        setState(() => _messages.add(msg));
        _jumpToEnd();
      });
      _jumpToEnd();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    _input.clear();
    HapticFeedback.selectionClick();
    await _community.sendMessage(widget.groupId, body);
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = _community.currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            tooltip: 'Safety & guidelines',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Keeping it safe'),
                content: const Text(
                  'Be respectful — no harassment, hate, or unsafe advice.\n\n'
                  'Long-press any message to report it or block the sender. '
                  'We review reports within 24 hours and remove content or '
                  'members that break the rules.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _empty(context)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(Ah.gutter),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m['sender_id'] == me;
                          final bubble = _Bubble(
                            body: (m['body'] as String?) ?? '',
                            mine: mine,
                          );
                          // Others' messages can be reported or blocked
                          // (Apple Guideline 1.2). Your own can't.
                          if (mine) return bubble;
                          return GestureDetector(
                            onLongPress: () => _showModerationSheet(m),
                            child: bubble,
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Ah.s12, Ah.s8, Ah.s12, Ah.s8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message your group…',
                      ),
                    ),
                  ),
                  const SizedBox(width: Ah.s8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Ah.accent,
                      foregroundColor: Ah.onAccent,
                    ),
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Long-press a member's message → report it or block them.
  void _showModerationSheet(Map<String, dynamic> msg) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Ah.surface1,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Ah.warning),
              title: const Text('Report message'),
              subtitle: const Text('Flag this to our team for review'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _report(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Ah.danger),
              title: const Text('Block this member'),
              subtitle: const Text("You won't see their messages anymore"),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _block(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Ah.textSecondary),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(sheetCtx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _report(Map<String, dynamic> msg) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = msg['id'] as String?;
    if (id == null) return;
    try {
      await _community.reportContent(targetType: 'message', targetId: id);
      messenger.showSnackBar(const SnackBar(
        content: Text('Thanks — reported. We review reports within 24 hours.'),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't send the report. Please try again."),
      ));
    }
  }

  Future<void> _block(Map<String, dynamic> msg) async {
    final messenger = ScaffoldMessenger.of(context);
    final userId = msg['sender_id'] as String?;
    if (userId == null) return;
    try {
      await _community.blockUser(userId);
      if (!mounted) return;
      setState(() {
        _blocked.add(userId);
        _messages.removeWhere((m) => m['sender_id'] == userId);
      });
      messenger.showSnackBar(const SnackBar(
        content: Text("Blocked. You won't see this member's messages."),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't block right now. Please try again."),
      ));
    }
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Ah.s32),
          child: Text(
            'No messages yet — say hello to your group.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Ah.textSecondary),
          ),
        ),
      );
}

class _Bubble extends StatelessWidget {
  final String body;
  final bool mine;
  const _Bubble({required this.body, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Ah.s8),
        padding:
            const EdgeInsets.symmetric(horizontal: Ah.s12, vertical: Ah.s8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? Ah.accent : Ah.surface2,
          borderRadius: BorderRadius.circular(Ah.rMd),
          border: mine ? null : Border.all(color: Ah.hairline),
        ),
        child: Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mine ? Ah.onAccent : Ah.textPrimary,
                height: 1.35,
              ),
        ),
      ),
    );
  }
}
