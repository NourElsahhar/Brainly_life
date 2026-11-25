import '../../../core/errors/result.dart';
import '../data/models/chat_message.dart';

typedef CreateFromAi = Future<Result<String>> Function(String title);

class AiActionHandler {
  const AiActionHandler({required this.createTask, required this.createHabit});

  final CreateFromAi createTask;
  final CreateFromAi createHabit;

  Future<Result<AiActionType?>> execute(
    AiAction? action, {
    required bool confirmed,
  }) async {
    if (action == null || !confirmed) return const Result.success(null);

    switch (action.type) {
      case AiActionType.startFocus:
      case AiActionType.openPlan:
        return Result.success(action.type);
      case AiActionType.createTask:
      case AiActionType.createHabit:
        final create = action.type == AiActionType.createTask
            ? createTask
            : createHabit;
        final result = await create(action.title!);
        return result.fold(
          onSuccess: (_) => Result.success(action.type),
          onFailure: Result.failure,
        );
    }
  }
}
