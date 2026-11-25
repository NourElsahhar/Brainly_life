import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

enum AiActionType { createTask, createHabit, startFocus, openPlan }

class AiAction extends Equatable {
  const AiAction(this.type, {this.title});
  final AiActionType type;
  final String? title;

  static AiAction? tryParse(Object? json) {
    if (json is! Map) return null;
    final type = switch (json['type']) {
      'create_task' => AiActionType.createTask,
      'create_habit' => AiActionType.createHabit,
      'start_focus' => AiActionType.startFocus,
      'open_plan' => AiActionType.openPlan,
      _ => null,
    };
    if (type == null) return null;
    if (type == AiActionType.createHabit || type == AiActionType.createTask) {
      final title = json['title'];
      final maxLength = type == AiActionType.createHabit ? 50 : 100;
      if (title is! String ||
          title.trim().isEmpty ||
          title.trim().length > maxLength) {
        return null;
      }
      return AiAction(type, title: title.trim());
    }
    return AiAction(type);
  }

  Map<String, Object?> toJson() => {
    'type': switch (type) {
      AiActionType.createTask => 'create_task',
      AiActionType.createHabit => 'create_habit',
      AiActionType.startFocus => 'start_focus',
      AiActionType.openPlan => 'open_plan',
    },
    if (title != null) 'title': title,
  };

  @override
  List<Object?> get props => [type, title];
}

class ChatMessage extends Equatable {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    Iterable<AiAction> actions = const [],
  }) : actions = List.unmodifiable(actions);

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final List<AiAction> actions;

  Map<String, Object?> toContextJson() => {'role': role.name, 'text': text};

  static List<AiAction> parseActions(Object? values) => values is List
      ? values.take(4).map(AiAction.tryParse).whereType<AiAction>().toList()
      : [];

  @override
  List<Object?> get props => [id, role, text, createdAt, actions];
}
