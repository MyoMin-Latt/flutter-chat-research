import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/auth/models/models.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/message_list_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/models/message.dart';
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
    const allChars = 'ABCDEFGabcdefghijklmnopqrstuvwxyz';

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

  // Future<void> sendMessage(Message message) async {
  //   await FirebaseFirestore.instance
  //       .collection('mml')
  //       .doc('mml_id')
  //       .collection('messages')
  //       .doc(message.id)
  //       .set(message.toJson());
  // }

  Stream<List<Chat>> getChats() {
    return FirebaseFirestore.instance
        .collection('mml')
        .doc('mml_id')
        .collection('chats')
        .where('users', arrayContainsAny: [ref.watch(userProvider).toJson()])
        .snapshots()
        .map((event) {
          List<Chat> messageList = [];
          for (var element in event.docs) {
            messageList.add(Chat.fromJson(element.data()));
          }
          return messageList;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ATu_Chat"),
        actions: [
          IconButton(
            onPressed: () {
              var name = generateRandomString(2);
              var email = '$name@gmail.com';
              var user = User(id: const Uuid().v4(), email: email, name: name);
              debugPrint(user.toString());
              ref.read(userProvider.notifier).update((state) => user);
              addUser(user);
            },
            icon: const Icon(Icons.person_add),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserListPage(),
              ),
            ),
            icon: const Icon(Icons.chat),
          ),
          // IconButton(
          //   onPressed: () {
          //     var text = generateRandomString(7);
          //     User user = ref.watch(userProvider);
          //     Message message = Message(
          //       chatId: const Uuid().v4(),
          //       id: const Uuid().v4(),
          //       sender: user.toJson(),
          //       text: text,
          //       sendOn: DateTime.now(),
          //     );
          //     debugPrint(message.toJson().toString());
          //     sendMessage(message);
          //   },
          //   icon: const Icon(Icons.send),
          // ),
        ],
      ),
      body: StreamBuilder<List<Chat>>(
        stream: getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var sortList = snapshot.data!;
                sortList.sort(
                  (a, b) => a.name.compareTo(b.name),
                );
                var chat = sortList[index];
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MessageListPage(chat: chat),
                  )),
                  child: ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                    title: Text(chat.name),
                    subtitle: Text(chat.id),
                    // subtitle: Text(message.messages.last['text']),
                  ),
                );
                // }
              },
            );
          } else {
            return const Loader();
          }
        },
      ),
    );
  }
}
