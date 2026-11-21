import '../../../../core/errors/result.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  final _messages = <String, ChatMessage>{};
  int _sequence = 0;

  @override
  String nextMessageId() => 'mock-${_sequence++}';

  @override
  Future<Result<List<ChatMessage>>> load() async {
    final messages = _messages.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Result.success(
      messages.skip(messages.length > 50 ? messages.length - 50 : 0).toList(),
    );
  }

  @override
  Future<Result<void>> save(ChatMessage message) async {
    _messages[message.id] = message;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> clear() async {
    _messages.clear();
    return const Result.success(null);
  }
}
