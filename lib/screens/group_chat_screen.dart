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
  RealtimeChannel? _channel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await _community.messageHistory(widget.groupId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loading = false;
      });
      _channel = _community.groupMessages(widget.groupId, (msg) {
        if (!mounted) return;
        // Avoid duplicating a message we already have.
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
      appBar: AppBar(title: Text(widget.groupName)),
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
                          return _Bubble(
                            body: (m['body'] as String?) ?? '',
                            mine: mine,
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
