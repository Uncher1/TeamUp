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
import '../../design_system/gif_picker_sheet.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/projects_provider.dart';
import '../../repositories/project_repo.dart';
import '../../repositories/user_repo.dart';
import '../profile/crop_avatar_screen.dart';
import '../profile/user_profile_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatThreadScreen({super.key, required this.conversation});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _ctrl = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  late final ChatProvider _chat;

  /// Non-null while editing an existing message (inline, in the input bar).
  Message? _editing;

  /// Attachments staged for sending WITH an optional caption (up to 10). They
  /// are not sent until the user presses send.
  final List<_Staged> _pending = [];
  static const _maxAttachments = 10;

  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  int _recordSecs = 0;
  Timer? _recordTimer;
  // Live mic amplitudes (normalized 0..1) feeding the recording waveform.
  final List<double> _amps = [];
  StreamSubscription<Amplitude>? _ampSub;
  // True while a finished voice note is being encoded/uploaded, so the thread
  // shows an optimistic "loading voice" bubble until the real message lands.
  bool _sendingVoice = false;

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
    _inputFocus.dispose();
    _scroll.dispose();
    _recordTimer?.cancel();
    _ampSub?.cancel();
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
    final editing = _editing;
    if (editing != null) {
      // Inline edit mode: update the existing message instead of sending.
      if (text.isEmpty) return;
      context.read<ChatProvider>().editMessage(editing.id, text);
      setState(() => _editing = null);
      _ctrl.clear();
      return;
    }
    if (_pending.isNotEmpty) {
      // Send the staged images/files WITH the typed caption (text may be empty).
      final attachments = _pending
          .map((s) => {'type': s.type, 'name': s.name, 'data': s.dataUrl})
          .toList();
      context.read<ChatProvider>().sendMessage(text, attachments: attachments);
      setState(_pending.clear);
      _ctrl.clear();
      _scrollToBottom();
      return;
    }
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _ctrl.clear();
    _scrollToBottom();
  }

  void _removeStaged(int index) {
    if (index >= 0 && index < _pending.length) setState(() => _pending.removeAt(index));
  }

  /// Enters inline-edit mode: load the message text into the input bar and
  /// focus it. A banner (with an ✕) appears above the field to cancel.
  void _beginEdit(Message m) {
    setState(() => _editing = m);
    _ctrl.text = m.content;
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _inputFocus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _ctrl.clear();
  }

  /// Picks one or more images and STAGES them (previews above the input) so the
  /// user can add a caption before sending. Capped at [_maxAttachments] total.
  Future<void> _attachImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final maxMsg = context.tr('chat.maxAttachments', {'n': '$_maxAttachments'});
    final xs = await ImagePicker().pickMultiImage(
      maxWidth: 1280, maxHeight: 1280, imageQuality: 70);
    if (xs.isEmpty || !mounted) return;
    var hitMax = false;
    for (final x in xs) {
      if (_pending.length >= _maxAttachments) { hitMax = true; break; }
      final bytes = await x.readAsBytes();
      final dataUrl = 'data:${x.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
      _pending.add(_Staged(type: 'image', name: x.name, dataUrl: dataUrl, bytes: bytes));
    }
    if (!mounted) return;
    if (hitMax) messenger.showSnackBar(SnackBar(content: Text(maxMsg)));
    setState(() {});
    _inputFocus.requestFocus();
  }

  /// Picks one or more files (<= 5 MB each) and STAGES them. Capped at
  /// [_maxAttachments] total (shared with images).
  Future<void> _attachFile() async {
    final messenger = ScaffoldMessenger.of(context);
    final tooLargeMsg = context.tr('chat.fileTooLarge');
    final maxMsg = context.tr('chat.maxAttachments', {'n': '$_maxAttachments'});
    final result = await FilePicker.pickFiles(withData: true, allowMultiple: true);
    final files = result?.files ?? const [];
    if (files.isEmpty || !mounted) return;
    var hitMax = false, hadTooLarge = false;
    for (final f in files) {
      final bytes = f.bytes;
      if (bytes == null) continue;
      if (_pending.length >= _maxAttachments) { hitMax = true; break; }
      if (bytes.length > 5 * 1024 * 1024) { hadTooLarge = true; continue; }
      final dataUrl = 'data:application/octet-stream;base64,${base64Encode(bytes)}';
      _pending.add(_Staged(type: 'file', name: f.name, dataUrl: dataUrl, bytes: null));
    }
    if (!mounted) return;
    if (hadTooLarge) messenger.showSnackBar(SnackBar(content: Text(tooLargeMsg)));
    if (hitMax) messenger.showSnackBar(SnackBar(content: Text(maxMsg)));
    setState(() {});
    _inputFocus.requestFocus();
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
          multi: result['multi'] as bool? ?? false,
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
    setState(() { _recording = true; _recordSecs = 0; _amps.clear(); });
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (!mounted) return;
      // amp.current is dBFS (~ -45 silence .. 0 loudest); map to 0..1.
      final norm = ((amp.current + 45) / 45).clamp(0.0, 1.0);
      setState(() {
        _amps.add(norm);
        if (_amps.length > 48) _amps.removeAt(0);
      });
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordSecs++);
      // Hard cap: a voice message can't exceed 10 minutes - auto-send at 10:00.
      if (_recordSecs >= 600) _stopRecord(send: true);
    });
  }

  Future<void> _stopRecord({required bool send}) async {
    _recordTimer?.cancel();
    _ampSub?.cancel();
    final path = await _recorder.stop();
    if (mounted) setState(() => _recording = false);
    if (!send || path == null) return;
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) return;
    // Show the optimistic "loading voice" bubble immediately, then encode+send.
    if (!mounted) return;
    setState(() => _sendingVoice = true);
    _scrollToBottom();
    try {
      final dataUrl = 'data:audio/mp4;base64,${base64Encode(bytes)}';
      await context.read<ChatProvider>().sendMessage('', attachment: {
        'type': 'audio',
        'name': 'voice.m4a',
        'data': dataUrl,
      });
    } finally {
      if (mounted) setState(() => _sendingVoice = false);
    }
    _scrollToBottom();
  }

  Future<void> _pickGif() async {
    final url = await GifPickerSheet.show(context);
    if (url == null || !mounted) return;
    await context.read<ChatProvider>().sendMessage('', attachment: {
      'type': 'gif',
      'name': 'gif',
      'data': url,
    });
    _scrollToBottom();
  }

  static String fmtSecs(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  /// Ring the other person (1:1 DM call). Calls start as audio; the camera and
  /// screen share are turned on from inside the call.
  void _startCall() {
    final c = widget.conversation;
    final otherId = c.otherUserId;
    if (otherId == null) return;
    final call = context.read<CallProvider>();
    if (call.isBusy) return;
    call.startCall(
      userId: otherId,
      name: c.otherUserName ?? '',
      avatar: c.otherUserAvatar,
      conversationId: c.id,
    );
  }

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
              actions: (widget.conversation.type == 'project' &&
                      widget.conversation.projectId != null)
                  ? [
                      _TeamMenuButton(
                        projectId: widget.conversation.projectId!,
                        onLeft: () => Navigator.of(context).maybePop(),
                      ),
                    ]
                  : widget.conversation.otherUserId != null
                      ? [
                          IconButton(
                            icon: const Icon(Icons.call),
                            tooltip: context.tr('call.audio'),
                            onPressed: _startCall,
                          ),
                        ]
                      : const [],
            ),
            Expanded(
              child: provider.loadingMessages && provider.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : (provider.messages.isEmpty && !_sendingVoice)
                      ? Center(child: Text(context.tr('chat.noMessages'), style: TextStyle(color: context.palette.textMuted)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: provider.messages.length + (_sendingVoice ? 1 : 0),
                          itemBuilder: (_, i) {
                            // Trailing optimistic bubble while a voice note uploads.
                            if (i >= provider.messages.length) {
                              return const _VoiceLoadingBubble();
                            }
                            return _Bubble(
                              message: provider.messages[i],
                              mine: provider.messages[i].senderId == myId,
                              // Team owner can moderate (delete) any message.
                              canModerate: widget.conversation.type == 'project' &&
                                  widget.conversation.projectOwnerId == myId,
                              onEdit: _beginEdit,
                            );
                          },
                        ),
            ),
            _recording
                ? _RecordingBar(
                    seconds: _recordSecs,
                    amps: _amps,
                    onCancel: () => _stopRecord(send: false),
                    onSend: () => _stopRecord(send: true),
                  )
                : _InputBar(
                    controller: _ctrl,
                    focusNode: _inputFocus,
                    onSend: _send,
                    onAttach: _pickAttachment,
                    onMic: _startRecord,
                    onGif: _pickGif,
                    editing: _editing != null,
                    onCancelEdit: _cancelEdit,
                    staged: _pending,
                    onRemoveStaged: _removeStaged,
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
  final bool canModerate;
  final void Function(Message)? onEdit;
  const _Bubble({
    required this.message,
    required this.mine,
    this.canModerate = false,
    this.onEdit,
  });

  bool get _canEdit =>
      mine && message.attachmentType == null && message.content.trim().isNotEmpty;
  bool get _canDelete => mine || canModerate;

  Future<void> _showMenu(BuildContext context) async {
    if (!_canEdit && !_canDelete) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(ctx.tr('chat.edit')),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            if (_canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                title: Text(ctx.tr('common.delete'),
                    style: const TextStyle(color: Color(0xFFDC2626))),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (action == 'edit') {
      // Inline edit: hand the message back to the thread screen, which loads
      // it into the input bar (no popup).
      onEdit?.call(message);
    } else if (action == 'delete' && context.mounted) {
      await _delete(context);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final chat = context.read<ChatProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(ctx.tr('chat.deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('common.delete')),
          ),
        ],
      ),
    );
    if (ok == true) await chat.deleteMessage(message.id);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMenu(context),
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
            if (message.hasGif) _gifAttachment(context),
            if (message.hasAudio) _AudioBubble(dataUrl: message.attachmentData!, mine: mine),
            if (message.hasFile) _fileAttachment(context),
            if (message.hasAttachments) _multiAttachments(context),
            if (message.hasPoll) _PollBubble(poll: message.poll!, mine: mine),
            if (message.content.isNotEmpty && !message.hasPoll)
              Padding(
                padding: EdgeInsets.only(top: (message.hasImage || message.hasFile) ? 6 : 0),
                child: Text(message.content,
                    style: TextStyle(color: mine ? Colors.white : context.palette.textPrimary, height: 1.3)),
              ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.edited) ...[
                  Text(
                    context.tr('chat.edited'),
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: mine ? Colors.white70 : context.palette.textMuted,
                    ),
                  ),
                  Text(
                    ' . ',
                    style: TextStyle(
                      fontSize: 10,
                      color: mine ? Colors.white70 : context.palette.textMuted,
                    ),
                  ),
                ],
                Text(
                  _hm(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine ? Colors.white70 : context.palette.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Renders up to 10 attachments (images as a thumbnail grid, files as chips).
  Widget _multiAttachments(BuildContext context) {
    final fg = mine ? Colors.white : context.palette.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final a in message.attachments)
            if (a['type'] == 'image' && (a['data'] as String?)?.isNotEmpty == true)
              GestureDetector(
                onTap: () => showZoomableImage(context, imageUrl: a['data'] as String?),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode((a['data'] as String).split(',').last),
                    width: 108, height: 108, fit: BoxFit.cover, gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox(width: 108, height: 108),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _openAttachmentData(a['data'] as String?, a['name'] as String?),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mine ? Colors.white24 : context.palette.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.insert_drive_file_outlined, size: 18, color: fg),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(a['name'] as String? ?? 'fichier',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: fg)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.download_rounded, size: 16, color: fg),
                  ]),
                ),
              ),
        ],
      ),
    );
  }

  Widget _imageAttachment(BuildContext context) {
    final bytes = base64Decode(message.attachmentData!.split(',').last);
    return GestureDetector(
      // Same full-screen viewer as profiles/posts → pinch AND double-tap zoom.
      onTap: () => showZoomableImage(context, imageUrl: message.attachmentData),
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

  Widget _gifAttachment(BuildContext context) {
    final url = message.attachmentData!;
    return GestureDetector(
      onTap: () => showZoomableImage(context, imageUrl: url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 220,
          fit: BoxFit.fitWidth,
          gaplessPlayback: true,
          loadingBuilder: (c, child, p) => p == null
              ? child
              : Container(
                  width: 220, height: 160,
                  color: context.palette.slate100,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
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
Future<void> _openFileAttachment(Message m) =>
    _openAttachmentData(m.attachmentData, m.attachmentName);

/// Writes a base64 data URL to a temp file and opens the system share sheet.
Future<void> _openAttachmentData(String? data, String? name) async {
  if (data == null || data.isEmpty) return;
  try {
    final bytes = base64Decode(data.split(',').last);
    final dir = await getTemporaryDirectory();
    final safe = (name ?? 'file').replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '${dir.path}/$safe';
    await File(path).writeAsBytes(bytes);
    await Share.shareXFiles([XFile(path)]);
  } catch (_) {
    // best-effort open; ignore failures
  }
}

/// A picked attachment staged in the composer before sending.
class _Staged {
  final String type; // 'image' | 'file'
  final String name;
  final String dataUrl; // base64 data URL sent to the backend
  final Uint8List? bytes; // image preview (null for files)
  const _Staged({required this.type, required this.name, required this.dataUrl, this.bytes});
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
    final multi = poll['multi'] == true;
    final myVotes = ((poll['my_votes'] as List?) ??
            (poll['my_vote'] != null ? [poll['my_vote']] : const []))
        .map((e) => (e as num).toInt())
        .toSet();
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(multi ? Icons.checklist_rounded : Icons.bar_chart_rounded, size: 18, color: fg),
            const SizedBox(width: 6),
            Expanded(
              child: Text(question,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: fg, height: 1.3)),
            ),
          ]),
          // Make multi-choice obvious right under the question.
          if (multi)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 24),
              child: Text(context.tr('chat.pollMultiHint'),
                  style: TextStyle(fontSize: 11, color: footer, fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 12),
          for (int i = 0; i < options.length; i++)
            () {
              final count = i < counts.length ? counts[i] : 0;
              final pct = total > 0 ? count / total : 0.0;
              final selected = myVotes.contains(i);
              // Single = radio, multi = checkbox; filled when selected.
              final IconData mark = multi
                  ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                  : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
                        Container(height: 32, width: double.infinity, color: track),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(height: 32, color: fill),
                        ),
                        Container(
                          height: 32,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(children: [
                            Icon(mark, size: 16, color: fg),
                            const SizedBox(width: 6),
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
  bool _multi = false;

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
    Navigator.pop(context, {'question': q, 'options': opts, 'multi': _multi});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('chat.newPoll')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _question,
            maxLength: 150,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(labelText: context.tr('chat.question')),
          ),
          for (int i = 0; i < _options.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _options[i],
                maxLength: 40,
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('chat.pollMulti'), style: const TextStyle(fontSize: 14)),
            subtitle: Text(context.tr('chat.pollMultiHint'),
                style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
            value: _multi,
            onChanged: (v) => setState(() => _multi = v),
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
  final List<double> amps;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  const _RecordingBar({required this.seconds, required this.amps, required this.onCancel, required this.onSend});

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
        // Live voice waveform (replaces the old "Recording..." text).
        Expanded(child: _Waveform(amps: amps, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 10),
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

/// Animated bars showing live mic amplitude while recording a voice note.
/// Newest bars on the right; older ones scroll off the left.
class _Waveform extends StatelessWidget {
  final List<double> amps;
  final Color color;
  const _Waveform({required this.amps, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: SingleChildScrollView(
        reverse: true, // keep the latest bars visible at the right edge
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final a in amps)
              Container(
                width: 3,
                height: (4 + a * 24).clamp(4.0, 28.0),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Optimistic placeholder shown in the thread while a just-recorded voice note
/// is being encoded and uploaded, so it appears instantly instead of after a lag.
class _VoiceLoadingBubble extends StatelessWidget {
  const _VoiceLoadingBubble();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Icon(Icons.mic, size: 18, color: Colors.white.withValues(alpha: 0.9)),
          ],
        ),
      ),
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
    // Preload the clip (without playing) so the TOTAL duration is known and
    // shown right away - instead of 0:00 until the user hits play.
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setSource(BytesSource(_bytes));
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
      // Replay from the start once finished.
      if (_dur > Duration.zero && _pos >= _dur) await _player.seek(Duration.zero);
      await _player.resume();
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
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onMic;
  final VoidCallback onGif;
  final bool editing;
  final VoidCallback onCancelEdit;
  final List<_Staged> staged;
  final void Function(int) onRemoveStaged;
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.onMic,
    required this.onGif,
    this.editing = false,
    required this.onCancelEdit,
    this.staged = const [],
    required this.onRemoveStaged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(top: BorderSide(color: context.palette.slate100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Inline edit banner (✕ on the left to cancel) ──────────────────
          if (editing)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
              child: Row(
                children: [
                  InkWell(
                    onTap: onCancelEdit,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 20, color: context.palette.textMuted),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(context.tr('chat.editing'),
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: primary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          // ── Staged attachments preview (horizontal; tap an image to zoom) ──
          if (staged.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: staged.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = staged[i];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: s.type == 'image'
                            ? () => showZoomableImage(context, imageUrl: s.dataUrl)
                            : null,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.palette.slate100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: s.type == 'image' && s.bytes != null
                              ? Image.memory(s.bytes!, fit: BoxFit.cover)
                              : Icon(Icons.insert_drive_file_outlined,
                                  color: context.palette.textMuted),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onRemoveStaged(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Row(
        children: [
          if (!editing)
            IconButton(
              icon: Icon(Icons.attach_file, color: context.palette.textMuted),
              onPressed: onAttach,
              tooltip: context.tr('chat.attach'),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: context.tr('chat.inputHint'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          // Attaching/recording/GIFs don't apply while editing an existing message.
          if (!editing)
            IconButton(
              icon: Icon(Icons.gif_box_outlined, color: context.palette.textMuted),
              onPressed: onGif,
              tooltip: context.tr('gif.button'),
            ),
          if (!editing)
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
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(14)),
              child: Icon(editing ? Icons.check_rounded : Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
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
          GestureDetector(
            // Team photo zoom (2-finger). For DMs the whole row already opens
            // the profile, where the photo is zoomable too.
            onTap: conversation.isTeam
                ? () => showZoomableImage(context, imageUrl: conversation.avatarImageUrl)
                : null,
            child: GradientAvatar(
              name: conversation.displayName,
              size: 36,
              imageUrl: conversation.avatarImageUrl,
              presenceStatus: conversation.avatarStatus,
              isTeam: conversation.isTeam,
            ),
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

/// 3-dot menu in a team chat header: invite a friend, owner settings, leave.
class _TeamMenuButton extends StatefulWidget {
  final int projectId;
  final VoidCallback onLeft;
  const _TeamMenuButton({required this.projectId, required this.onLeft});

  @override
  State<_TeamMenuButton> createState() => _TeamMenuButtonState();
}

class _TeamMenuButtonState extends State<_TeamMenuButton> {
  Map<String, dynamic>? _m;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await context.read<ProjectRepository>().teamMembership(widget.projectId);
      if (mounted) setState(() => _m = m);
    } catch (_) {}
  }

  Future<void> _invite() async {
    final users = context.read<UserRepository>();
    final projects = context.read<ProjectRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final invitedMsg = context.tr('team.invited');
    final errMsg = context.tr('common.error');
    final noneMsg = context.tr('team.noFriends');
    List<Map<String, dynamic>> friends;
    try {
      friends = await users.friends();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
      return;
    }
    if (!mounted) return;
    if (friends.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(noneMsg)));
      return;
    }
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final f in friends)
              ListTile(
                leading: GradientAvatar(
                    name: f['full_name'] as String? ?? '?',
                    size: 40,
                    imageUrl: f['avatar_url'] as String?),
                title: Text(f['full_name'] as String? ?? ''),
                onTap: () => Navigator.pop(ctx, f['id'] as int),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await projects.inviteToTeam(widget.projectId, chosen);
      messenger.showSnackBar(SnackBar(content: Text(invitedMsg)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  Future<void> _settings() async {
    final m = _m;
    if (m == null) return;
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _TeamSettingsDialog(
        projectId: widget.projectId,
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String?,
        allowMemberInvite: m['allow_member_invite'] == true,
      ),
    );
    if (updated != null && mounted) setState(() => _m = {...?_m, ...updated});
  }

  /// Owner-only: delete the whole team (the chief can't "leave", they delete).
  Future<void> _deleteTeam() async {
    final projects = context.read<ProjectsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final doneMsg = context.tr('team.deleted');
    final errMsg = context.tr('common.error');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('team.delete')),
        content: Text(ctx.tr('team.deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('team.delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await projects.deleteProject(widget.projectId);
      messenger.showSnackBar(SnackBar(content: Text(doneMsg)));
      widget.onLeft();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  Future<void> _leave() async {
    final projects = context.read<ProjectRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final leftMsg = context.tr('team.left');
    final errMsg = context.tr('common.error');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(ctx.tr('team.leaveConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('team.leave')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await projects.leaveTeam(widget.projectId);
      messenger.showSnackBar(SnackBar(content: Text(leftMsg)));
      widget.onLeft();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        if (v == 'invite') _invite();
        if (v == 'settings') _settings();
        if (v == 'leave') _leave();
        if (v == 'delete') _deleteTeam();
      },
      itemBuilder: (ctx) => [
        if (m != null && m['can_invite'] == true)
          PopupMenuItem(
            value: 'invite',
            child: Row(children: [
              const Icon(Icons.person_add_alt_1, size: 18),
              const SizedBox(width: 10),
              Text(ctx.tr('team.invite')),
            ]),
          ),
        if (m != null && m['is_owner'] == true)
          PopupMenuItem(
            value: 'settings',
            child: Row(children: [
              const Icon(Icons.settings_outlined, size: 18),
              const SizedBox(width: 10),
              Text(ctx.tr('team.settings')),
            ]),
          ),
        if (m != null && m['is_member'] == true && m['is_owner'] != true)
          PopupMenuItem(
            value: 'leave',
            child: Row(children: [
              const Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Text(ctx.tr('team.leave'), style: const TextStyle(color: Color(0xFFDC2626))),
            ]),
          ),
        // The owner can't leave - they delete the whole team instead.
        if (m != null && m['is_owner'] == true)
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Text(ctx.tr('team.delete'), style: const TextStyle(color: Color(0xFFDC2626))),
            ]),
          ),
      ],
    );
  }
}

/// Owner-only team settings: rename, edit description, change photo and toggle
/// member-invite. Returns the updated fields ({title, description, avatar_url,
/// allow_member_invite}) when saved, or null on cancel.
class _TeamSettingsDialog extends StatefulWidget {
  final int projectId;
  final String title;
  final String description;
  final String? avatarUrl;
  final bool allowMemberInvite;
  const _TeamSettingsDialog({
    required this.projectId,
    required this.title,
    required this.description,
    required this.avatarUrl,
    required this.allowMemberInvite,
  });

  @override
  State<_TeamSettingsDialog> createState() => _TeamSettingsDialogState();
}

class _TeamSettingsDialogState extends State<_TeamSettingsDialog> {
  late final TextEditingController _title = TextEditingController(text: widget.title);
  late final TextEditingController _desc = TextEditingController(text: widget.description);
  late String? _avatar = widget.avatarUrl;
  late bool _allow = widget.allowMemberInvite;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (x == null) return;
    final raw = await x.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropAvatarScreen(imageBytes: raw)));
    if (cropped == null) return;
    setState(() => _avatar = 'data:image/png;base64,${base64Encode(cropped)}');
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errMsg = context.tr('common.error');
    final projectRepo = context.read<ProjectRepository>();
    final projectsProvider = context.read<ProjectsProvider>();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await projectRepo.updateTeam(
            widget.projectId,
            title: title,
            description: _desc.text.trim(),
            avatarUrl: _avatar ?? '',
            allowMemberInvite: _allow,
          );
      // Refresh My Teams so the new name/photo show up there too.
      await projectsProvider.loadMine();
      navigator.pop({
        'title': title,
        'description': _desc.text.trim(),
        'avatar_url': _avatar,
        'allow_member_invite': _allow,
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(errMsg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('team.settings')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickPhoto,
                child: Column(
                  children: [
                    GradientAvatar(
                        name: _title.text.trim().isEmpty ? '?' : _title.text.trim(),
                        size: 72,
                        imageUrl: _avatar,
                        isTeam: true),
                    const SizedBox(height: 6),
                    Text(context.tr('team.changePhoto'),
                        style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              maxLength: 20,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: context.tr('team.name')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLength: 600,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr('team.descriptionLabel'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('team.memberInvite'), style: const TextStyle(fontSize: 14)),
              value: _allow,
              onChanged: _saving ? null : (v) => setState(() => _allow = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(context.tr('common.cancel'))),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr('common.save')),
        ),
      ],
    );
  }
}
