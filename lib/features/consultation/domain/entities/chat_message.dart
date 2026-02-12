import 'package:equatable/equatable.dart';

enum MessageType { text, prescription, system }

class ChatMessage extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final List<String> readBy;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.readBy,
  });

  bool isReadBy(String userId) => readBy.contains(userId);

  @override
  List<Object?> get props => [
    id,
    roomId,
    senderId,
    content,
    type,
    timestamp,
    readBy,
  ];
}
