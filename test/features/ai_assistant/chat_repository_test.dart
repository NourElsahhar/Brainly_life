import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/ai_assistant/data/datasources/chat_remote_data_source.dart';
import 'package:brainly_life/features/ai_assistant/data/repositories/firestore_chat_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _DataSource extends Mock implements ChatRemoteDataSource {}

void main() {
  test(
    'Returns safe failures for unavailable Firestore and rejects no reads',
    () async {
      final source = _DataSource();
      when(source.load).thenAnswer((_) async => []);
      when(source.clear).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      final repository = FirestoreChatRepository(source);
      expect((await repository.load()).dataOrNull, isEmpty);
      expect((await repository.clear()).failureOrNull, isA<NetworkFailure>());
    },
  );
}
