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

  Future<Message> sendMessage(int conversationId, String content) async {
    final res = await api.dio.post(
      '/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return Message.fromJson(res.data as Map<String, dynamic>, fallbackConvId: conversationId);
  }

  Future<Conversation> getOrCreateDirect(int otherUserId) async {
    final res = await api.dio.post('/conversations/direct/$otherUserId');
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }
}
