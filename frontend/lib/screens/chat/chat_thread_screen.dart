// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../profile/user_profile_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatThreadScreen({super.key, required this.conversation});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  late final ChatProvider _chat;

  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  int _recordSecs = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chat.openConversation(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    _chat.closeConversation();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _ctrl.clear();
    _scrollToBottom();
  }

  /// Picks an image from the gallery, compresses it and sends it as an
  /// attachment (base64 data URL).
  Future<void> _attachImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final dataUrl = 'data:${x.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
    if (!mounted) return;
    await context.read<ChatProvider>().sendMessage('', attachment: {
      'type': 'image',
      'name': x.name,
      'data': dataUrl,
    });
    _scrollToBottom();
  }

  /// Picks an arbitrary file (<= 5 MB) and sends it as a base64 attachment.
  Future<void> _attachFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    final f = (result?.files.isNotEmpty ?? false) ? result!.files.first : null;
    final bytes = f?.bytes;
    if (f == null || bytes == null) return;
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('chat.fileTooLarge'))));
      }
      return;
    }
    final dataUrl = 'data:application/octet-stream;base64,${base64Encode(bytes)}';
    if (!mounted) return;
    await context.read<ChatProvider>().sendMessage('', attachment: {
      'type': 'file',
      'name': f.name,
      'data': dataUrl,
    });
    _scrollToBottom();
  }

  /// Bottom sheet: send a photo or a file.
  void _pickAttachment() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(ctx.tr('chat.photo')),
              onTap: () { Navigator.pop(ctx); _attachImage(); },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(ctx.tr('chat.file')),
              onTap: () { Navigator.pop(ctx); _attachFile(); },
            ),
            if (widget.conversation.type == 'project')
              ListTile(
                leading: const Icon(Icons.poll_outlined),
                title: Text(ctx.tr('chat.poll')),
                onTap: () { Navigator.pop(ctx); _createPoll(); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPoll() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _PollComposer(),
    );
    if (result == null || !mounted) return;
    await context.read<ChatProvider>().createPoll(
          result['question'] as String,
          (result['options'] as List).cast<String>(),
        );
    _scrollToBottom();
  }

  Future<void> _startRecord() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('chat.micDenied'))));
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() { _recording = true; _recordSecs = 0; });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSecs++);
    });
  }

  Future<void> _stopRecord({required bool send}) async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    if (mounted) setState(() => _recording = false);
    if (!send || path == null) return;
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) return;
    final dataUrl = 'data:audio/mp4;base64,${base64Encode(bytes)}';
    if (!mounted) return;
    await context.read<ChatProvider>().sendMessage('', attachment: {
      'type': 'audio',
      'name': 'voice.m4a',
      'data': dataUrl,
    });
    _scrollToBottom();
  }

  static String fmtSecs(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final myId = context.read<AuthProvider>().user?.id ?? -1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              titleWidget: _DmHeaderTitle(conversation: widget.conversation),
            ),
            Expanded(
              child: provider.loadingMessages && provider.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.messages.isEmpty
                      ? Center(child: Text(context.tr('chat.noMessages'), style: TextStyle(color: context.palette.textMuted)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: provider.messages.length,
                          itemBuilder: (_, i) => _Bubble(message: provider.messages[i], mine: provider.messages[i].senderId == myId),
                        ),
            ),
            _recording
                ? _RecordingBar(
                    seconds: _recordSecs,
                    onCancel: () => _stopRecord(send: false),
                    onSend: () => _stopRecord(send: true),
                  )
                : _InputBar(
                    controller: _ctrl,
                    onSend: _send,
                    onAttach: _pickAttachment,
                    onMic: _startRecord,
                  ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool mine;
  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: mine ? Theme.of(context).colorScheme.primary : context.palette.slate100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message.senderName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.palette.primaryHover)),
                    RoleBadge(role: message.senderRole, size: 12),
                  ],
                ),
              ),
            if (message.hasImage) _imageAttachment(context),
            if (message.hasAudio) _AudioBubble(dataUrl: message.attachmentData!, mine: mine),
            if (message.hasFile) _fileAttachment(context),
            if (message.hasPoll) _PollBubble(poll: message.poll!, mine: mine),
            if (message.content.isNotEmpty && !message.hasPoll)
              Padding(
                padding: EdgeInsets.only(top: (message.hasImage || message.hasFile) ? 6 : 0),
                child: Text(message.content,
                    style: TextStyle(color: mine ? Colors.white : context.palette.textPrimary, height: 1.3)),
              ),
            const SizedBox(height: 3),
            Text(
              _hm(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : context.palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageAttachment(BuildContext context) {
    final bytes = base64Decode(message.attachmentData!.split(',').last);
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.memory(bytes, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 220,
          fit: BoxFit.fitWidth,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 40),
        ),
      ),
    );
  }

  Widget _fileAttachment(BuildContext context) {
    final fg = mine ? Colors.white : context.palette.textPrimary;
    return GestureDetector(
      onTap: () => _openFileAttachment(message),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: mine ? Colors.white24 : context.palette.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.insert_drive_file_outlined, size: 20, color: fg),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.attachmentName ?? 'fichier',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: fg),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.download_rounded, size: 18, color: fg),
        ]),
      ),
    );
  }

  static String _hm(DateTime t) {
    final tl = t.toLocal();
    return '${tl.hour.toString().padLeft(2, '0')}:${tl.minute.toString().padLeft(2, '0')}';
  }
}

/// Writes a received base64 file to a temp path and opens the system share
/// sheet so the user can save or open it.
Future<void> _openFileAttachment(Message m) async {
  final data = m.attachmentData;
  if (data == null || data.isEmpty) return;
  try {
    final bytes = base64Decode(data.split(',').last);
    final dir = await getTemporaryDirectory();
    final safe = (m.attachmentName ?? 'file').replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '${dir.path}/$safe';
    await File(path).writeAsBytes(bytes);
    await Share.shareXFiles([XFile(path)]);
  } catch (_) {
    // best-effort open; ignore failures
  }
}

class _PollBubble extends StatelessWidget {
  final Map<String, dynamic> poll;
  final bool mine;
  const _PollBubble({required this.poll, required this.mine});

  @override
  Widget build(BuildContext context) {
    final id = (poll['id'] as num).toInt();
    final question = poll['question'] as String? ?? '';
    final options = ((poll['options'] as List?) ?? const []).map((e) => '$e').toList();
    final counts = ((poll['counts'] as List?) ?? const []).map((e) => (e as num).toInt()).toList();
    final total = (poll['total'] as num?)?.toInt() ?? 0;
    final myVote = (poll['my_vote'] as num?)?.toInt();
    final fg = mine ? Colors.white : context.palette.textPrimary;
    final track = mine ? Colors.white24 : context.palette.slate200;
    final fill = mine
        ? Colors.white.withValues(alpha: 0.4)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);

    final footer = mine ? Colors.white70 : context.palette.textMuted;
    return SizedBox(
      width: 256,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.bar_chart_rounded, size: 18, color: fg),
            const SizedBox(width: 6),
            Expanded(
              child: Text(question,
                  style: TextStyle(fontWeight: FontWeight.w700, color: fg, height: 1.2)),
            ),
          ]),
          const SizedBox(height: 10),
          for (int i = 0; i < options.length; i++)
            () {
              final count = i < counts.length ? counts[i] : 0;
              final pct = total > 0 ? count / total : 0.0;
              final selected = myVote == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => context.read<ChatProvider>().votePoll(id, i),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? fg.withValues(alpha: 0.9) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(children: [
                        Container(height: 40, width: double.infinity, color: track),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(height: 40, color: fill),
                        ),
                        Container(
                          height: 40,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(children: [
                            if (selected) ...[
                              Icon(Icons.check_circle, size: 16, color: fg),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(options[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: fg,
                                      fontWeight:
                                          selected ? FontWeight.w700 : FontWeight.w500)),
                            ),
                            const SizedBox(width: 8),
                            Text('${(pct * 100).round()}%',
                                style: TextStyle(
                                    color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              );
            }(),
          const SizedBox(height: 2),
          Text(context.tr('chat.votes', {'n': '$total'}),
              style: TextStyle(fontSize: 11, color: footer)),
        ],
      ),
    );
  }
}

class _PollComposer extends StatefulWidget {
  const _PollComposer();
  @override
  State<_PollComposer> createState() => _PollComposerState();
}

class _PollComposerState extends State<_PollComposer> {
  final _question = TextEditingController();
  final List<TextEditingController> _options = [TextEditingController(), TextEditingController()];

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final q = _question.text.trim();
    final opts = _options.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (q.isEmpty || opts.length < 2) return;
    Navigator.pop(context, {'question': q, 'options': opts});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('chat.newPoll')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _question, decoration: InputDecoration(labelText: context.tr('chat.question'))),
          for (int i = 0; i < _options.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _options[i],
                decoration: InputDecoration(labelText: '${context.tr('chat.option')} ${i + 1}'),
              ),
            ),
          if (_options.length < 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _options.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('chat.addOption')),
              ),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
        FilledButton(onPressed: _submit, child: Text(context.tr('chat.create'))),
      ],
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  const _RecordingBar({required this.seconds, required this.onCancel, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(top: BorderSide(color: context.palette.slate100)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
          onPressed: onCancel,
        ),
        const Icon(Icons.fiber_manual_record, color: Color(0xFFEF4444), size: 14),
        const SizedBox(width: 8),
        Text(_ChatThreadScreenState.fmtSecs(seconds),
            style: TextStyle(color: context.palette.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        Text(context.tr('chat.recording'),
            style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
        const Spacer(),
        InkWell(
          onTap: onSend,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _AudioBubble extends StatefulWidget {
  final String dataUrl;
  final bool mine;
  const _AudioBubble({required this.dataUrl, required this.mine});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _bytes;
  bool _playing = false;
  Duration _dur = Duration.zero;
  Duration _pos = Duration.zero;

  @override
  void initState() {
    super.initState();
    _bytes = base64Decode(widget.dataUrl.split(',').last);
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _dur = d); });
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _pos = p); });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playing = false; _pos = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(BytesSource(_bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.mine ? Colors.white : context.palette.textPrimary;
    final totalMs = _dur.inMilliseconds == 0 ? 1 : _dur.inMilliseconds;
    final shown = (_playing || _pos > Duration.zero) ? _pos : _dur;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: _toggle,
        child: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 32, color: fg),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 110,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (_pos.inMilliseconds / totalMs).clamp(0.0, 1.0),
            minHeight: 4,
            color: fg,
            backgroundColor: fg.withValues(alpha: 0.3),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(_ChatThreadScreenState.fmtSecs(shown.inSeconds),
          style: TextStyle(fontSize: 11, color: fg)),
    ]);
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onMic;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(top: BorderSide(color: context.palette.slate100)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: context.palette.textMuted),
            onPressed: onAttach,
            tooltip: context.tr('chat.attach'),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: context.tr('chat.inputHint'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.mic_none_rounded, color: context.palette.textMuted),
            onPressed: onMic,
            tooltip: context.tr('chat.recordVoice'),
          ),
          InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Direct-message header: the other person's avatar (with presence dot) + name.
/// Tapping it opens their public profile.
class _DmHeaderTitle extends StatelessWidget {
  final Conversation conversation;
  const _DmHeaderTitle({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final otherId = conversation.otherUserId;
    return GestureDetector(
      onTap: otherId == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UserProfileScreen(
                  userId: otherId,
                  initialName: conversation.otherUserName,
                  initialAvatar: conversation.otherUserAvatar,
                ),
              )),
      child: Row(
        children: [
          GradientAvatar(
            name: conversation.displayName,
            size: 36,
            imageUrl: conversation.avatarImageUrl,
            presenceStatus: conversation.avatarStatus,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              conversation.displayName,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
