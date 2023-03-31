import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/core/utils/utils.dart';
import 'package:flutter_chat_research/firebase_options.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth/presentation/register_page.dart';
import 'chat/chat_list/presentation/atu_chat_page.dart';
import 'chat/share/chat_provider.dart';
import 'core/utils/firebase_function.dart';
import 'core/utils/storage_function.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadEnv();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    getUserForAuth();
  }

  Future<void> getUserForAuth() async {
    var userId = await readInLocal();
    // await getUserInLocal(userId ?? '', ref);
    getUser(userId ?? '').then(
        (value) => ref.read(userProvider.notifier).update((state) => value));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ref.watch(userProvider) == null
          ? const RegisterPage()
          : const ATuChatPage(),
    );
  }
}
