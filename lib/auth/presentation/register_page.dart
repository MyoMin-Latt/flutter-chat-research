import 'package:flutter/material.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/atu_chat_page.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:flutter_chat_research/core/utils/firebase_function.dart';
import 'package:flutter_chat_research/core/utils/storage_function.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/common_function.dart';
import '../models/user.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  String id = 'id';
  String name = 'name';
  String email = 'email';
  @override
  void initState() {
    super.initState();
    setData();
  }

  void setData() {
    var genString = generateRandomString(2);
    id = const Uuid().v4();
    name = genString;
    email = '$genString@gmail.com';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(id),
            const SizedBox(height: 8),
            Text(name),
            const SizedBox(height: 8),
            Text(email),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: () {
                  User user = User(id: id, name: name, email: email, photo: '');
                  debugPrint(user.toJson().toString());
                  ref.read(userProvider.notifier).update((state) => user);
                  saveInLocal(user);
                  addUser(user).then(
                    (value) => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const ATuChatPage(),
                        ),
                        (route) => false),
                  );
                },
                child: const Text('Register'))
          ],
        ),
      ),
    );
  }
}
