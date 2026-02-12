import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/data/data_sources/chat_service.dart';
import 'package:mediconnect/features/consultation/data/models/chat_message_model.dart';
import 'package:mediconnect/features/consultation/domain/entities/chat_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;
  StreamSubscription? _messagesSubscription;

  String _roomId = '';
  String _currentUserId = '';
  String _currentUserName = '';

  ChatBloc(this._chatService) : super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageReceived>(_onChatMessageReceived);
    on<ChatSendMessage>(_onChatSendMessage);
    on<ChatMarkAsRead>(_onChatMarkAsRead);
  }

  void _onChatStarted(ChatStarted event, Emitter<ChatState> emit) {
    _roomId = event.roomId;
    _currentUserId = event.currentUserId;
    _currentUserName = event.currentUserName;

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .getMessages(_roomId)
        .listen(
          (messages) => add(ChatMessageReceived(messages)),
          onError: (error) => add(ChatMessageReceived(const [])),
        );
  }

  void _onChatMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    // Auto-mark unread messages from others as read
    for (final msg in event.messages) {
      if (msg.senderId != _currentUserId && !msg.isReadBy(_currentUserId)) {
        add(ChatMarkAsRead(msg.id));
      }
    }

    emit(
      ChatLoaded(
        messages: event.messages,
        roomId: _roomId,
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
      ),
    );
  }

  Future<void> _onChatSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = ChatMessageModel(
        id: '',
        roomId: _roomId,
        senderId: _currentUserId,
        senderName: _currentUserName,
        content: event.content,
        type: event.type,
        timestamp: DateTime.now(),
        readBy: [_currentUserId],
      );
      await _chatService.sendMessage(message);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onChatMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.markAsRead(_roomId, event.messageId, _currentUserId);
    } catch (_) {
      // Silent fail for read receipts
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
