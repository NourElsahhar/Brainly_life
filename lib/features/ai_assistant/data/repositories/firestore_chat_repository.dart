import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository(this.source);
  final ChatRemoteDataSource source;

  @override
  String nextMessageId() => source.nextMessageId();

  @override
  Future<Result<List<ChatMessage>>> load() => _guard(source.load);

  @override
  Future<Result<void>> save(ChatMessage message) =>
      _guard(() => source.save(message));

  @override
  Future<Result<void>> clear() => _guard(source.clear);

  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } catch (error) {
      return Result.failure(FirebaseErrorMapper.map(error));
    }
  }
}
