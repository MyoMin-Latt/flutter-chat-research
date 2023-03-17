import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/models/user.dart';
import '../../models/message.dart';
import '../../share/chat_provider.dart';

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
        .collection('mml')
        .doc('mml_id')
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
        .collection('mml')
        .doc('mml_id')
        .collection('messages')
        .doc(message.id)
        .set(message.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.id),
        actions: [
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
              );
              debugPrint(message.toJson().toString());
              sendMessage(message);
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: getMessage(),
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
                  (a, b) => a.sendOn.compareTo(b.sendOn),
                );
                var message = sortList[index];
                return ListTile(
                  title: Text('${message.text} by ${message.sender['name']}'),
                  subtitle: Text(message.chatId),
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
