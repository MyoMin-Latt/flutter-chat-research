import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/message_list_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ATuChatPage extends ConsumerStatefulWidget {
  const ATuChatPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ATuChatPageState();
}

class _ATuChatPageState extends ConsumerState<ATuChatPage> {
  @override
  void initState() {
    super.initState();
  }

  Stream<List<Chat>> getChats() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserListPage(),
              ),
            ),
            icon: const Icon(Icons.chat),
          ),
        ],
      ),
      body: StreamBuilder<List<Chat>>(
        stream: getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const NoData();
            }
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var sortList = snapshot.data!;
                sortList.sort(
                  (a, b) => a.name.compareTo(b.name),
                );
                var chat = sortList[index];
                debugPrint(chat.toString());
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MessageListPage(chat: chat),
                  )),
                  child: ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                    title: Text(chat.name),
                    subtitle: Text(chat.id),
                    // subtitle: Text(chat.messages.last['text']),
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

class NoData extends StatelessWidget {
  const NoData({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No Data'),
    );
  }
}
