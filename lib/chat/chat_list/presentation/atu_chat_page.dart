import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/auth/presentation/register_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/message_list_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/onesignal/onesignal.dart';

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

  Stream<List<Chat>> getPeerChats() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('chatUsers')
        .doc(ref.watch(userProvider)!.id)
        .collection('chats')
        .where('allUserIds', arrayContainsAny: [ref.watch(userProvider)!.id])
        .snapshots()
        .map((event) {
          List<Chat> messageList = [];
          for (var element in event.docs) {
            messageList.add(Chat.fromJson(element.data()));
          }
          return messageList;
        });
  }

  Stream<List<Chat>> getGroupChats() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('groupChats')
        .where('allUserIds', arrayContainsAny: [ref.watch(userProvider)!.id])
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
        title: Text(ref.watch(userProvider)!.name.toString()),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserListPage(),
              ),
            ),
            icon: const Icon(Icons.chat),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserListPage(
                  chat: Chat(
                    id: '',
                    name: '',
                    photo: '',
                    isGroup: true,
                    peerUserId: '',
                    peerUserName: '',
                    userIds: [],
                    adminIds: [],
                    allUserIds: [],
                    lastMessage: '',
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.group),
          ),
          IconButton(
            onPressed: () {
              deleteUserTag();
              ref.read(userProvider.notifier).update((state) => null);
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                  ),
                  (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<List<Chat>>(
              stream: getGroupChats(),
              builder: (context, snapshot) {
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const Loader();
                // }
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return const NoData();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var sortList = snapshot.data!;
                      sortList.sort(
                        (a, b) => a.name.compareTo(b.name),
                      );
                      var chat = sortList[index];
                      return InkWell(
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => MessageListPage(
                            chat: chat,
                          ),
                        )),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(index.toString())),
                          title: chat.isGroup
                              ? Text(chat.name)
                              : Text(chat.peerUserName),
                          subtitle: Text(chat.id),
                        ),
                      );
                    },
                  );
                } else {
                  return const Loader();
                }
              },
            ),
            StreamBuilder<List<Chat>>(
              stream: getPeerChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loader();
                }
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return const NoData();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var sortList = snapshot.data!;
                      sortList.sort(
                        (a, b) => a.name.compareTo(b.name),
                      );
                      var chat = sortList[index];
                      return InkWell(
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => MessageListPage(
                            chat: chat,
                          ),
                        )),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(index.toString())),
                          title: chat.isGroup
                              ? Text(chat.name)
                              : Text(chat.peerUserName),
                          subtitle: Text(chat.id),
                        ),
                      );
                    },
                  );
                } else {
                  return const Loader();
                }
              },
            ),
          ],
        ),
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
