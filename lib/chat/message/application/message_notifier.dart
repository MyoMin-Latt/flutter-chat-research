import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_research/chat/message/repository/message_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'message_notifier.freezed.dart';

@freezed
class MessageState with _$MessageState {
  const factory MessageState.initial(List<DocumentSnapshot> docsList) =
      _Initial;
  const factory MessageState.loading(List<DocumentSnapshot> docsList) =
      _Loading;
  const factory MessageState.empty(List<DocumentSnapshot> docsList) = _Empty;
  const factory MessageState.success(List<DocumentSnapshot> docsList) =
      _Success;
  const factory MessageState.addMessage(List<DocumentSnapshot> docsList) =
      _AddMessage;
  const factory MessageState.updateMessage(List<DocumentSnapshot> docsList) =
      _UpdteMessage;
}

final messageNotifierProvider =
    StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  return MessageNotifier(ref.watch(messageRepositoryProvider));
});

class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepository repository;
  MessageNotifier(this.repository) : super(const MessageState.initial([]));

  Future<void> requestFirstPage(String chatId) async {
    state = MessageState.loading(state.docsList);
    final docsList = await repository.requestFirstPage(chatId);
    state = docsList.isEmpty
        ? const MessageState.empty([])
        : MessageState.success(docsList);
  }

  Future<void> requestNextPage(
      String chatId, DocumentSnapshot docSnapshot) async {
    final docsList = await repository.requestNextPage(chatId, docSnapshot);
    state = MessageState.success([...docsList, ...state.docsList]);
  }
}
