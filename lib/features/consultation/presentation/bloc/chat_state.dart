part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String roomId;
  final String currentUserId;
  final String currentUserName;

  const ChatLoaded({
    required this.messages,
    required this.roomId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  List<Object?> get props => [messages, roomId, currentUserId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
