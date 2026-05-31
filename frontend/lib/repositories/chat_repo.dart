// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import '../core/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatRepository {
  final ApiClient api;
  ChatRepository(this.api);

  Future<List<Conversation>> conversations() async {
    final res = await api.dio.get('/conversations');
    return (res.data as List)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> messages(int conversationId, {int limit = 50}) async {
    final res = await api.dio.get(
      '/conversations/$conversationId/messages',
      queryParameters: {'limit': limit},
    );
    return (res.data as List)
        .map((e) => Message.fromJson(e as Map<String, dynamic>, fallbackConvId: conversationId))
        .toList();
  }

  Future<Message> sendMessage(
    int conversationId,
    String content, {
    Map<String, dynamic>? attachment,
  }) async {
    final res = await api.dio.post(
      '/conversations/$conversationId/messages',
      data: {
        'content': content,
        'attachment': ?attachment,
      },
    );
    return Message.fromJson(res.data as Map<String, dynamic>, fallbackConvId: conversationId);
  }

  /// Creates a poll in a team conversation. The poll message is delivered back
  /// over the socket (message:new).
  Future<void> createPoll(int conversationId, String question, List<String> options) async {
    await api.dio.post(
      '/conversations/$conversationId/polls',
      data: {'question': question, 'options': options},
    );
  }

  /// Casts (or changes) a vote; returns the updated poll {options, counts, ...}.
  Future<Map<String, dynamic>> votePoll(int pollId, int option) async {
    final res = await api.dio.post(
      '/conversations/polls/$pollId/vote',
      data: {'option': option},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Conversation> getOrCreateDirect(int otherUserId) async {
    final res = await api.dio.post('/conversations/direct/$otherUserId');
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }
}
