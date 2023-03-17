import 'package:flutter_chat_research/auth/models/models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userProvider = StateProvider<User>((ref) => const User(id: ''));
