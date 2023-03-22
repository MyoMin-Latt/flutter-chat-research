import 'package:freezed_annotation/freezed_annotation.dart';
part 'chat.freezed.dart';
part 'chat.g.dart';

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    required String name,
    required String photo,
    required bool isGroup,
    required String peerUserId,
    required String peerUserName,
    required List<String> userIds,
    required List<String> adminIds,
    required List<String> allUserIds,
    required String lastMessage,
  }) = _Chat;

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
}
