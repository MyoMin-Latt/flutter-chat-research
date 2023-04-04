import 'package:flutter/material.dart';
import 'package:flutter_chat_research/auth/presentation/register_page.dart';
import 'package:flutter_chat_research/chat/message/presentation/message_list_page.dart';
import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/firebase_function.dart';
import '../../../core/utils/onesignal/onesignal.dart';

class ATuChatPage extends ConsumerStatefulWidget {
  const ATuChatPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ATuChatPageState();
}

class _ATuChatPageState extends ConsumerState<ATuChatPage> {
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
              stream: getGroupChats(ref.watch(userProvider)!),
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
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MessageListPage(
                              chat: chat,
                            ),
                          ),
                        ),
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
              stream: getPeerChats(ref.watch(userProvider)!),
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
