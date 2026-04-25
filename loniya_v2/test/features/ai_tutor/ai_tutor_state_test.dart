import 'package:flutter_test/flutter_test.dart';
import 'package:loniya_v2/features/ai_tutor/domain/entities/ai_message_entity.dart';
import 'package:loniya_v2/features/ai_tutor/presentation/providers/ai_tutor_provider.dart';

AiMessageEntity _msg({
  String id      = 'm1',
  MessageRole role = MessageRole.user,
  String content = 'hello',
}) =>
    AiMessageEntity(
      id:        id,
      role:      role,
      content:   content,
      createdAt: DateTime(2024),
    );

void main() {
  group('AiTutorState', () {
    test('default state is empty and not typing', () {
      const s = AiTutorState();
      expect(s.messages,     isEmpty);
      expect(s.isTyping,     isFalse);
      expect(s.errorMessage, isNull);
      expect(s.readyTutorId, isNull);
    });

    test('copyWith updates only specified fields', () {
      final msg   = _msg();
      const base  = AiTutorState(isTyping: false);
      final updated = base.copyWith(
        messages:  [msg],
        isTyping:  true,
      );
      expect(updated.messages,     [msg]);
      expect(updated.isTyping,     isTrue);
      expect(updated.errorMessage, isNull);   // preserved
      expect(updated.readyTutorId, isNull);   // preserved
    });

    test('copyWith without args preserves all fields', () {
      final msg   = _msg(id: 'x', role: MessageRole.tutor, content: 'ok');
      final state = AiTutorState(
        messages:     [msg],
        isTyping:     true,
        errorMessage: 'oops',
        readyTutorId: 'r1',
      );
      final copy = state.copyWith();
      expect(copy.messages,     state.messages);
      expect(copy.isTyping,     state.isTyping);
      expect(copy.errorMessage, state.errorMessage);
      expect(copy.readyTutorId, state.readyTutorId);
    });

    test('clearError flag resets errorMessage to null', () {
      final state = AiTutorState(errorMessage: 'some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('errorMessage is NOT reset unless clearError is true', () {
      final state   = AiTutorState(errorMessage: 'some error');
      final updated = state.copyWith(isTyping: true);
      expect(updated.errorMessage, 'some error');
    });

    test('readyTutorId tracks the last fully-ready tutor message', () {
      final s1 = const AiTutorState().copyWith(readyTutorId: 'msg-42');
      expect(s1.readyTutorId, 'msg-42');

      final s2 = s1.copyWith(readyTutorId: 'msg-99');
      expect(s2.readyTutorId, 'msg-99');
    });

    test('clearReadyTutor flag sets readyTutorId to null', () {
      final state   = AiTutorState(readyTutorId: 'msg-1');
      final cleared = state.copyWith(clearReadyTutor: true);
      expect(cleared.readyTutorId, isNull);
    });

    test('readyTutorId NOT cleared by unrelated copyWith', () {
      final state   = AiTutorState(readyTutorId: 'msg-1');
      final updated = state.copyWith(isTyping: false);
      expect(updated.readyTutorId, 'msg-1');
    });
  });

  group('AiMessageEntity helpers', () {
    test('isUser and isTutor are mutually exclusive', () {
      final user  = _msg(role: MessageRole.user);
      final tutor = _msg(role: MessageRole.tutor);
      expect(user.isUser,   isTrue);
      expect(user.isTutor,  isFalse);
      expect(tutor.isUser,  isFalse);
      expect(tutor.isTutor, isTrue);
    });

    test('equality respects all props', () {
      final a = _msg(id: 'same');
      final b = _msg(id: 'same');
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      final a = _msg(id: 'a');
      final b = _msg(id: 'b');
      expect(a, isNot(equals(b)));
    });
  });
}
