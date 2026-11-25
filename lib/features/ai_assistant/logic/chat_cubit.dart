import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/ai.dart';
import '../../../core/errors/failure.dart';
import '../data/models/chat_message.dart';
import '../data/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required this._repository,
    required this._client,
    required this._now,
  }) : super(const ChatInitial());

  static const maxMessageLength = 1000;
  final ChatRepository _repository;
  final AiClient _client;
  final DateTime Function() _now;

  final _messages = <ChatMessage>[];
  ChatMessage? _pendingUser;
  ChatMessage? _pendingReply;
  late Future<void> Function() _retry = load;
  bool _busy = false;

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    emit(const ChatLoading());
    final result = await _repository.load();
    _busy = false;
    if (isClosed) return;
    result.fold(
      onSuccess: (messages) {
        _messages
          ..clear()
          ..addAll(messages);
        _showMessages();
      },
      onFailure: (failure) => _showError(failure, load),
    );
  }

  Future<void> send(String rawText) async {
    if (_busy) return;
    final text = rawText.trim();
    if (text.isEmpty || text.runes.length > maxMessageLength) {
      _showError(
        const ValidationFailure(
          userMessage: 'Enter a message between 1 and 1,000 characters.',
        ),
        null,
      );
      return;
    }
    _pendingReply = null;
    _pendingUser = ChatMessage(
      id: _repository.nextMessageId(),
      role: ChatRole.user,
      text: text,
      createdAt: _now().toUtc(),
    );
    _add(_pendingUser!);
    await _sendPending();
  }

  Future<void> _sendPending() async {
    if (_busy || _pendingUser == null) return;
    _busy = true;
    emit(ChatLoaded(_messages, isSending: true));
    final user = _pendingUser!;
    final write = await _repository.save(user);
    if (isClosed) return;
    if (write.failureOrNull case final failure?) {
      _showError(failure, _sendPending);
      return;
    }
    if (_pendingReply == null) {
      final result = await _client.generate(
        AiRequest(feature: AiFeature.chat, payload: _payload(user)),
      );
      if (isClosed) return;
      if (result.failureOrNull case final failure?) {
        _showError(
          failure,
          failure is AiGatewayFailure && !failure.canRetry
              ? null
              : _sendPending,
        );
        return;
      }
      final data = result.dataOrNull!.data;
      final reply = data['reply'];
      if (reply is! String ||
          reply.trim().isEmpty ||
          reply.length > 4000 ||
          data['actions'] is! List) {
        _showError(AiGatewayFailure(AiErrorCode.invalidResponse), _sendPending);
        return;
      }
      _pendingReply = ChatMessage(
        id: _repository.nextMessageId(),
        role: ChatRole.assistant,
        text: reply.trim(),
        createdAt: _now().toUtc(),
        actions: ChatMessage.parseActions(data['actions']),
      );
    }
    final reply = _pendingReply!;
    final saved = await _repository.save(reply);
    if (isClosed) return;
    if (saved.failureOrNull case final failure?) {
      _showError(failure, _sendPending);
      return;
    }
    _pendingReply = null;
    _pendingUser = null;
    _add(reply);
    _showMessages();
  }

  Map<String, Object?> _payload(ChatMessage user) {
    final history = _messages
        .where((message) => message.id != user.id)
        .toList();
    final lastTen = history.skip(history.length > 10 ? history.length - 10 : 0);
    final payload = <String, Object?>{'text': user.text, 'history': []};
    final entries = lastTen.map((message) => message.toContextJson()).toList();
    payload['history'] = entries;
    while (entries.isNotEmpty &&
        utf8.encode(jsonEncode(payload)).length > 20 * 1024) {
      entries.removeAt(0);
    }
    return payload;
  }

  Future<void> retry() async {
    final current = state;
    if (current is ChatError && current.canRetry && !_busy) await _retry();
  }

  Future<void> clear() async {
    if (_busy) return;
    _busy = true;
    emit(ChatLoaded(_messages, isClearing: true));
    final result = await _repository.clear();
    if (isClosed) return;
    result.fold(
      onSuccess: (_) {
        _messages.clear();
        _pendingUser = null;
        _pendingReply = null;
        _showMessages();
      },
      onFailure: (failure) => _showError(failure, clear),
    );
  }

  void _add(ChatMessage message) {
    _messages.add(message);
    if (_messages.length > 50) _messages.removeAt(0);
  }

  void _showMessages() {
    _busy = false;
    emit(_messages.isEmpty ? const ChatEmpty() : ChatLoaded(_messages));
  }

  void _showError(Failure failure, Future<void> Function()? retry) {
    _busy = false;
    if (retry != null) _retry = retry;
    emit(ChatError(failure, _messages, canRetry: retry != null));
  }
}
