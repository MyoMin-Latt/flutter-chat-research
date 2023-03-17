import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/auth/models/models.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

class ATuChatPage extends ConsumerStatefulWidget {
  const ATuChatPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ATuChatPageState();
}

class _ATuChatPageState extends ConsumerState<ATuChatPage> {
  String generateRandomString(int lengthOfString) {
    final random = Random();
    const allChars = 'AaBbCcDdlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1EeFfGgHhIiJjKkL';

    final randomString = List.generate(lengthOfString,
        (index) => allChars[random.nextInt(allChars.length)]).join();
    return randomString;
  }

  Future<void> addUser(User user) async {
    await FirebaseFirestore.instance
        .collection('mml')
        .doc('mml_id')
        .collection('users')
        .doc(user.id)
        .set(user.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ATu_Chat"),
        actions: [
          IconButton(
              onPressed: () {
                var name = generateRandomString(5);
                var email = '$name@gmail.com';
                var user =
                    User(id: const Uuid().v4(), email: email, name: name);
                debugPrint(user.toString());
                ref.read(userProvider.notifier).update((state) => user);
                addUser(user);
              },
              icon: const Icon(Icons.person_add))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const UserListPage(),
          ),
        ),
        child: const Icon(Icons.chat),
      ),
    );
  }
}
