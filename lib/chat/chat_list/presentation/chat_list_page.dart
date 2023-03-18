import 'package:flutter/material.dart';
import 'package:flutter_chat_research/auth/presentation/register_page.dart';
import 'package:flutter_chat_research/core/utils/utils.dart';
import 'package:flutter_chat_research/core/widgets/widgets.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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
                deleteUserTag();
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
            builder: (context) => const RegisterPage(),
          )),
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}
