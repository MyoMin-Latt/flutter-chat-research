import 'package:flutter/material.dart';
import 'package:flutter_chat_research/auth/models/user.dart';
import 'package:flutter_chat_research/auth/presentation/register_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/atu_chat_page.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:flutter_chat_research/core/utils/firebase_function.dart';
import 'package:flutter_chat_research/core/utils/storage_function.dart';
import 'package:flutter_chat_research/core/utils/utils.dart';
import 'package:flutter_chat_research/core/widgets/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ChatListScreenState createState() => ChatListScreenState();
}

class ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _chatId = '';
  String _openChatId = '';

  Future<void> setupOneSignal(String userId) async {
    await initOneSignal();

    registerOneSignalEventListener(
      onOpened: onOpened,
      onReceivedInForeground: onReceivedInForeground,
    );

    promptPolicyPrivacy(userId);
  }

  void onOpened(OSNotificationOpenedResult result) {
    vLog('NOTIFICATION OPENED HANDLER CALLED WITH: $result');
    vLog(
      "Opened notification: \n${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}",
    );

    try {
      final data = result.notification.additionalData;

      if (data != null) {
        final chatId = data['chatId'];

        setState(() {
          _openChatId = chatId;
        });
      }
    } catch (err) {
      eLog(err);
    }
  }

  void onReceivedInForeground(OSNotificationReceivedEvent event) {
    vLog(
      "Notification received in foreground notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}",
    );

    try {
      final data = event.notification.additionalData;

      if (data != null) {
        wLog(data);
        // e57867e0-b9a1-11ed-b472-cda189771762
        final chatId = data['chatId'];

        setState(() {
          _chatId = chatId;
        });
      }
    } catch (err) {
      eLog(err);
    }
  }

  Future<void> promptPolicyPrivacy(String userId) async {
    final shared = OneSignal.shared;

    bool userProvidedPrivacyConsent = await shared.userProvidedPrivacyConsent();
    vLog('userProvidedPrivacyConsent => $userProvidedPrivacyConsent');

    if (userProvidedPrivacyConsent) {
      sendUserTag(userId);
    } else {
      bool requiresConsent = await shared.requiresUserPrivacyConsent();

      if (requiresConsent) {
        final accepted = await shared.promptUserForPushNotificationPermission();
        if (accepted) {
          await shared.consentGranted(true);
          sendUserTag(userId);
        }
      } else {
        sendUserTag(userId);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    var userId = await readInLocal();
    getUserInLocal(userId ?? '', ref);
  }

  @override
  Widget build(BuildContext context) {
    final userId = const Uuid().v1();

    return StartupContainer(
      onInit: () async {
        setupOneSignal(userId);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chat List"),
              Text(
                "User Id: $userId",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                // deleteUserTag();
                // ref
                //     .read(userProvider.notifier)
                //     .update((state) => const User(id: ''));
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Chat Id: $_chatId',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 20),
              if (_openChatId.isNotEmpty)
                Text(
                  'Chat Id: $_openChatId',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ref.watch(userProvider).id.isEmpty
                ? const RegisterPage()
                : const ATuChatPage(),
          )),
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}
