import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/features/consultation/data/data_sources/chat_service.dart';
import 'package:mediconnect/features/consultation/data/models/chat_message_model.dart';
import 'package:mediconnect/features/consultation/domain/entities/chat_message.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/chat_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockChatService extends Mock implements ChatService {}

class FakeChatMessageModel extends Fake implements ChatMessageModel {}

void main() {
  late MockChatService mockChatService;
  late StreamController<List<ChatMessage>> messagesController;

  setUpAll(() {
    registerFallbackValue(FakeChatMessageModel());
  });

  setUp(() {
    mockChatService = MockChatService();
    messagesController = StreamController<List<ChatMessage>>.broadcast();
  });

  tearDown(() {
    messagesController.close();
  });

  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      final bloc = ChatBloc(mockChatService);
      expect(bloc.state, isA<ChatInitial>());
      bloc.close();
    });

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoaded] when messages are received after ChatStarted',
      setUp: () {
        when(
          () => mockChatService.getMessages('room_1'),
        ).thenAnswer((_) => messagesController.stream);
        when(
          () => mockChatService.markAsRead(any(), any(), any()),
        ).thenAnswer((_) async {});
      },
      build: () => ChatBloc(mockChatService),
      act: (bloc) async {
        bloc.add(
          const ChatStarted(
            roomId: 'room_1',
            currentUserId: 'user_1',
            currentUserName: 'Test User',
          ),
        );
        // Give time for the subscription to be set up
        await Future.delayed(const Duration(milliseconds: 50));
        // Simulate incoming messages
        messagesController.add([
          ChatMessage(
            id: 'msg_1',
            roomId: 'room_1',
            senderId: 'user_1',
            senderName: 'Test User',
            content: 'Hello',
            type: MessageType.text,
            timestamp: DateTime(2026, 2, 12),
            readBy: const ['user_1'],
          ),
        ]);
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<ChatLoaded>()],
      verify: (_) {
        verify(() => mockChatService.getMessages('room_1')).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'auto-marks unread messages from others as read',
      setUp: () {
        when(
          () => mockChatService.getMessages('room_1'),
        ).thenAnswer((_) => messagesController.stream);
        when(
          () => mockChatService.markAsRead('room_1', 'msg_2', 'user_1'),
        ).thenAnswer((_) async {});
      },
      build: () => ChatBloc(mockChatService),
      act: (bloc) async {
        bloc.add(
          const ChatStarted(
            roomId: 'room_1',
            currentUserId: 'user_1',
            currentUserName: 'Test User',
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        // Message from another user that hasn't been read
        messagesController.add([
          ChatMessage(
            id: 'msg_2',
            roomId: 'room_1',
            senderId: 'user_2',
            senderName: 'Doctor',
            content: 'How are you?',
            type: MessageType.text,
            timestamp: DateTime(2026, 2, 12),
            readBy: const ['user_2'], // Not read by user_1
          ),
        ]);
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<ChatLoaded>()],
      verify: (_) {
        verify(
          () => mockChatService.markAsRead('room_1', 'msg_2', 'user_1'),
        ).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'does NOT auto-mark own messages as read',
      setUp: () {
        when(
          () => mockChatService.getMessages('room_1'),
        ).thenAnswer((_) => messagesController.stream);
      },
      build: () => ChatBloc(mockChatService),
      act: (bloc) async {
        bloc.add(
          const ChatStarted(
            roomId: 'room_1',
            currentUserId: 'user_1',
            currentUserName: 'Test User',
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        // Own message
        messagesController.add([
          ChatMessage(
            id: 'msg_3',
            roomId: 'room_1',
            senderId: 'user_1',
            senderName: 'Test User',
            content: 'My message',
            type: MessageType.text,
            timestamp: DateTime(2026, 2, 12),
            readBy: const ['user_1'],
          ),
        ]);
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<ChatLoaded>()],
      verify: (_) {
        verifyNever(() => mockChatService.markAsRead(any(), any(), any()));
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits ChatError when sendMessage fails',
      setUp: () {
        when(
          () => mockChatService.getMessages('room_1'),
        ).thenAnswer((_) => messagesController.stream);
        when(
          () => mockChatService.sendMessage(any()),
        ).thenThrow(Exception('Network error'));
      },
      build: () => ChatBloc(mockChatService),
      act: (bloc) async {
        // Start the chat to set internal room/user state
        bloc.add(
          const ChatStarted(
            roomId: 'room_1',
            currentUserId: 'user_1',
            currentUserName: 'Test User',
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        // Try to send a message
        bloc.add(const ChatSendMessage(content: 'Hello!'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<ChatError>()],
    );
  });

  group('ChatMessage entity', () {
    test('isReadBy returns true when user is in readBy list', () {
      final msg = ChatMessage(
        id: '1',
        roomId: 'room',
        senderId: 'sender',
        senderName: 'Sender',
        content: 'Hello',
        type: MessageType.text,
        timestamp: DateTime.now(),
        readBy: const ['sender', 'reader'],
      );
      expect(msg.isReadBy('reader'), true);
      expect(msg.isReadBy('other'), false);
    });

    test('MessageType enum contains expected values', () {
      expect(
        MessageType.values,
        containsAll([
          MessageType.text,
          MessageType.prescription,
          MessageType.system,
        ]),
      );
    });
  });
}
