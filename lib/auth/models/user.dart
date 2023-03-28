import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// {@template user}
/// User model
///
/// [User.empty] represents an unauthenticated user.
/// {@endtemplate}
@freezed
class User with _$User {
  const User._();
  const factory User({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String photo,
    required bool isOnline,
  }) = _User;

  /// Empty user which represents an unauthenticated user.
  // static const empty = User(id: '');

  /// Convenience getter to determine whether the current user is empty.
  // bool get isEmpty => this == User.empty;

  /// Convenience getter to determine whether the current user is not empty.
  // bool get isNotEmpty => this != User.empty;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
