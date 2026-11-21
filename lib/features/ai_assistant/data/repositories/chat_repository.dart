import '../../../../core/errors/result.dart';
import '../models/chat_message.dart';

abstract interface class ChatRepository {
  String nextMessageId();
  Future<Result<List<ChatMessage>>> load();
  Future<Result<void>> save(ChatMessage message);
  Future<Result<void>> clear();
}
