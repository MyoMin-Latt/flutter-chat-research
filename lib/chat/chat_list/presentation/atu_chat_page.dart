import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/auth/presentation/register_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/message_list_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:flutter_chat_research/core/utils/firebase_function.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/models/user.dart';
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

  Stream<List<Chat>> getChats() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('chatUsers')
        .doc(ref.watch(userProvider).id)
        .collection('chats')
        .where('allUserIds', arrayContainsAny: [ref.watch(userProvider).id])
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
        title: Text(ref.watch(userProvider).name.toString()),
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
              ref
                  .read(userProvider.notifier)
                  .update((state) => const User(id: ''));
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
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MessageListPage(
                      chat: chat,
                    ),
                  )),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(index.toString())),
                    title: Text(chat.name),
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
    );
  }
}

class PeerChatName extends StatefulWidget {
  const PeerChatName({
    super.key,
    required this.index,
    required this.chat,
    required this.currentUser,
  });

  final Chat chat;
  final User currentUser;
  final int index;

  @override
  State<PeerChatName> createState() => _PeerChatNameState();
}

class _PeerChatNameState extends State<PeerChatName> {
  @override
  void initState() {
    super.initState();
    getPartnerName();
  }

  String chatName = '';
  String firstChar = '';

  getPartnerName() async {
    if (widget.chat.allUserIds[0] == widget.chat.allUserIds[1]) {
      chatName = 'My Note';
    } else {
      for (var element in widget.chat.allUserIds) {
        if (widget.currentUser.id != element) {
          await getUser(element).then((value) {
            if (value != null) {
              chatName = value.name ?? '';
            }
          });
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => MessageListPage(chat: widget.chat),
      )),
      child: ListTile(
        leading: CircleAvatar(child: Text(widget.index.toString())),
        title: widget.chat.isGroup ? Text(widget.chat.name) : Text(chatName),
        subtitle: Text(widget.chat.id),
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
