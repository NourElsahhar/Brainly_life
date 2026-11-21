import '../../../core/errors/failure.dart';
import '../data/models/chat_message.dart';

sealed class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatEmpty extends ChatState {
  const ChatEmpty();
}

class ChatLoaded extends ChatState {
  ChatLoaded(
    Iterable<ChatMessage> messages, {
    this.isSending = false,
    this.isClearing = false,
  }) : messages = List.unmodifiable(messages);

  final List<ChatMessage> messages;
  final bool isSending;
  final bool isClearing;
}

class ChatError extends ChatState {
  ChatError(
    this.failure,
    Iterable<ChatMessage> messages, {
    required this.canRetry,
  }) : messages = List.unmodifiable(messages);

  final Failure failure;
  final List<ChatMessage> messages;
  final bool canRetry;
}
