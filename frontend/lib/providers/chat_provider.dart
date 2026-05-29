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

  Future<void> sendMessage(String content) async {
    if (_activeConvId == null) return;
    try {
      final msg = await _repo.sendMessage(_activeConvId!, content);
      if (!messages.any((m) => m.id == msg.id)) {
        messages = [...messages, msg];
        notifyListeners();
      }
    } catch (_) {}
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
  }

  void _leaveSocket() {
    if (_socket != null && _activeConvId != null) {
      _socket!.emit('conversation:leave', _activeConvId);
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  @override
  void dispose() {
    _leaveSocket();
    super.dispose();
  }
}
