import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/data/models/chat_message_model.dart';
import 'package:mediconnect/features/consultation/domain/entities/chat_message.dart';

abstract class ChatService {
  Stream<List<ChatMessage>> getMessages(String roomId);
  Future<void> sendMessage(ChatMessageModel message);
  Future<void> markAsRead(String roomId, String messageId, String userId);
  Future<int> getUnreadCount(String roomId, String userId);
}

@LazySingleton(as: ChatService)
class ChatServiceImpl implements ChatService {
  final FirebaseFirestore _db;

  ChatServiceImpl(this._db);

  CollectionReference _messagesRef(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('messages');
  }

  @override
  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _messagesRef(roomId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> sendMessage(ChatMessageModel message) async {
    await _messagesRef(message.roomId).add(message.toFirestore());
  }

  @override
  Future<void> markAsRead(
    String roomId,
    String messageId,
    String userId,
  ) async {
    await _messagesRef(roomId).doc(messageId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<int> getUnreadCount(String roomId, String userId) async {
    final snapshot = await _messagesRef(roomId).get();
    return snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .where((msg) => !msg.readBy.contains(userId) && msg.senderId != userId)
        .length;
  }
}
