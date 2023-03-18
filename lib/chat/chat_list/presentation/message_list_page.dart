import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/models/user.dart';
import '../../../core/share/core_provider.dart';
import '../../models/message.dart';
import '../../share/chat_provider.dart';
import 'atu_chat_page.dart';

class MessageListPage extends ConsumerStatefulWidget {
  final Chat chat;
  const MessageListPage({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageListPage> {
  Stream<List<Message>> getMessage() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .where('chatId', isEqualTo: widget.chat.id)
        .snapshots()
        .map((event) {
      List<Message> messageList = [];
      for (var element in event.docs) {
        messageList.add(Message.fromJson(element.data()));
      }
      return messageList;
    });
  }

  String generateRandomString(int lengthOfString) {
    final random = Random();
    const allChars = 'ABCDEFGabcdefghijklmnopqrstuvwxyz';

    final randomString = List.generate(lengthOfString,
        (index) => allChars[random.nextInt(allChars.length)]).join();
    return randomString;
  }

  Future<void> sendMessage(Message message) async {
    await FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .doc(message.id)
        .set(message.toJson());
  }

  Future<void> setMessageStatus(String messageId, String status) async {
    await FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .doc(messageId)
        .update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    var networkStatus = ref.watch(networkStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => UserListPage(chat: widget.chat),
            )),
            icon: const Icon(Icons.person_add),
          ),
          IconButton(
            onPressed: () {
              var text = generateRandomString(7);
              User user = ref.watch(userProvider);
              Message message = Message(
                chatId: widget.chat.id,
                id: const Uuid().v4(),
                sender: user.toJson(),
                text: text,
                sendOn: DateTime.now(),
                status: 'offline',
              );
              debugPrint(
                  'SendMessage : status-offline : ${message.toJson().toString()}');
              sendMessage(message);
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: getMessage(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Loader();
          // }
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const NoData();
            }
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var sortList = snapshot.data!;
                sortList.sort(
                  (a, b) => a.sendOn.compareTo(b.sendOn),
                );
                var message = sortList[index];

                if (message.status.toLowerCase() == 'offline') {
                  // add internet connection state
                  networkStatus == NetworkStatus.connected
                      ? setMessageStatus(message.id, 'online')
                      : null;
                }

                return Align(
                  alignment: message.sender['id'] == ref.watch(userProvider).id
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 45,
                      minWidth: 70,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${message.text} sent by ${message.sender['name']}  ${message.status}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
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
