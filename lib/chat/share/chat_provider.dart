import 'package:flutter_chat_research/auth/models/models.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userProvider = StateProvider<User?>((ref) => null);

final chatProvider = StateProvider<Chat?>((ref) => null);
