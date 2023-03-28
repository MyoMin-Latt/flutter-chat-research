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
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    setData();
  }

  void setData() {
    var genString = generateRandomString(3);
    id = const Uuid().v4();
    nameController.text = genString;
    passwordController.text = '123';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter your name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                decoration:
                    const InputDecoration(hintText: 'Enter your password'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: () async {
                    User user = User(
                      id: id,
                      name: nameController.text,
                      email: '${nameController.text}@gmail.com',
                      photo: '',
                      isOnline: false,
                      phone: '',
                    );
                    debugPrint(user.toJson().toString());

                    getUserWithName(nameController.text).then((value) async {
                      if (value != null) {
                        ref
                            .read(userProvider.notifier)
                            .update((state) => value);
                        await saveInLocal(value);

                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const ATuChatPage(),
                            ),
                            (route) => false);
                      } else {
                        ref.read(userProvider.notifier).update((state) => user);
                        await saveInLocal(user);
                        addUser(user).then(
                          (val) => Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const ATuChatPage(),
                              ),
                              (route) => false),
                        );
                      }
                    });
                  },
                  child: const Text('Register'))
            ],
          ),
        ),
      ),
    );
  }
}
