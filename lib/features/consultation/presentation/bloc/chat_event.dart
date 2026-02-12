part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  final String roomId;
  final String currentUserId;
  final String currentUserName;

  const ChatStarted({
    required this.roomId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  List<Object?> get props => [roomId, currentUserId, currentUserName];
}

class ChatMessageReceived extends ChatEvent {
  final List<ChatMessage> messages;

  const ChatMessageReceived(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatSendMessage extends ChatEvent {
  final String content;
  final MessageType type;

  const ChatSendMessage({required this.content, this.type = MessageType.text});

  @override
  List<Object?> get props => [content, type];
}

class ChatMarkAsRead extends ChatEvent {
  final String messageId;

  const ChatMarkAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}
