// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import '../core/storage.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../repositories/chat_repo.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../core/config.dart' show Config;

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repo;
  final TokenStorage _storage;

  ChatProvider(this._repo, this._storage);

  List<Conversation> conversations = [];
  bool loadingConvs = false;
  String? convError;

  sio.Socket? _socket;
  int? _activeConvId;
  List<Message> messages = [];
  bool loadingMessages = false;

  Future<void> loadConversations() async {
    loadingConvs = true;
    convError = null;
    notifyListeners();
    try {
      conversations = await _repo.conversations();
    } catch (e) {
      convError = e.toString();
    } finally {
      loadingConvs = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(int convId) async {
    if (_activeConvId == convId) return;
    _leaveSocket();
    _activeConvId = convId;
    messages = [];
    loadingMessages = true;
    notifyListeners();
    try {
      messages = await _repo.messages(convId);
    } catch (_) {}
    loadingMessages = false;
    notifyListeners();
    _joinSocket(convId);
  }

  Future<void> sendMessage(String content, {Map<String, dynamic>? attachment}) async {
    if (_activeConvId == null) return;
    try {
      final msg = await _repo.sendMessage(_activeConvId!, content, attachment: attachment);
      if (!messages.any((m) => m.id == msg.id)) {
        messages = [...messages, msg];
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Creates a poll (team conversation). The poll message arrives via socket.
  Future<void> createPoll(String question, List<String> options) async {
    if (_activeConvId == null) return;
    try {
      await _repo.createPoll(_activeConvId!, question, options);
    } catch (_) {}
  }

  Future<void> votePoll(int pollId, int option) async {
    try {
      _applyPollUpdate(await _repo.votePoll(pollId, option));
    } catch (_) {}
  }

  void _applyPollUpdate(Map<String, dynamic> poll) {
    final pid = poll['id'];
    final i = messages.indexWhere((m) => m.hasPoll && m.poll!['id'] == pid);
    if (i >= 0) {
      messages = [...messages]..[i] = messages[i].copyWith(poll: poll);
      notifyListeners();
    }
  }

  void _joinSocket(int convId) async {
    final token = await _storage.read();
    if (token == null) return;
    _socket = sio.io(
      Config.socketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.emit('conversation:join', convId);
    _socket!.on('message:new', (data) {
      if (data is Map) {
        final msg = Message.fromJson(Map<String, dynamic>.from(data));
        if (msg.conversationId == convId && !messages.any((m) => m.id == msg.id)) {
          messages = [...messages, msg];
          notifyListeners();
        }
      }
    });
    _socket!.on('poll:update', (data) {
      if (data is Map) _applyPollUpdate(Map<String, dynamic>.from(data));
    });
  }

  void _leaveSocket() {
    if (_socket != null && _activeConvId != null) {
      _socket!.emit('conversation:leave', _activeConvId);
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  /// Leaves the active conversation's socket room (call when the thread closes).
  void closeConversation() {
    _leaveSocket();
    _activeConvId = null;
  }

  @override
  void dispose() {
    _leaveSocket();
    super.dispose();
  }
}
