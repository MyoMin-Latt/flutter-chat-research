import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:flutter_chat_research/core/utils/firebase_function.dart';

import '../../../auth/models/user.dart';

class UserListPage extends ConsumerStatefulWidget {
  final Chat? chat;
  const UserListPage({this.chat, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  List<User> userList = [];

  mutiSelectUsers(User user) {
    if (userList.contains(user)) {
      userList.remove(user);
    } else {
      userList.add(user);
    }
    setState(() {});
  }

  selectAll(List<User> userList) {
    if (userList.isEmpty) {
      userList.addAll(userList);
    } else {
      userList.clear();
    }
  }

  Future<void> addChat(Chat chat) async {
    await FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('chats')
        .doc(chat.id)
        .set(chat.toJson());

    // ignore: use_build_context_synchronously
    // Navigator.of(context).pop();
  }

  Stream<List<User>> getUsers() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('users')
        .where('id', isNotEqualTo: ref.watch(userProvider).id)
        .snapshots()
        .map((event) {
      List<User> userList = [];
      for (var element in event.docs) {
        userList.add(User.fromJson(element.data()));
      }
      return userList;
    });
  }

  Future<Chat?> getChat(User user) {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('chats')
        .where('isGroup', isEqualTo: '')
        .where('userIds', arrayContains: user.id)
        .get()
        .then((value) {
      List<QueryDocumentSnapshot<Map<String, dynamic>>> data = value.docs;
      if (data.isNotEmpty) {
        List<Chat?> chatList = [];
        for (var element in data) {
          chatList.add(Chat.fromJson(element.data()));
        }
        return chatList[0];
      }
      return null;
    });
  }

  void checkUserAddChat(User user, Chat chat) async {
    await getUser(user.id).then((value) {
      if (value != null) {
        addChat(chat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isGroup = widget.chat != null && widget.chat!.isGroup == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose User'),
        actions: [
          isGroup
              ? TextButton(
                  onPressed: () {
                    List<String> userIds = [];
                    List<String?> gpName = [];
                    for (var element in userList) {
                      gpName.add(element.name);
                      if (ref.watch(userProvider).id != element.id) {
                        userIds.add(element.id);
                      }
                    }
                    Chat groupChat = Chat(
                      id: const Uuid().v4(),
                      name: gpName.join(', '),
                      photo: '',
                      isGroup: true,
                      peerUserId: '',
                      peerUserName: '',
                      userIds: [...userIds],
                      adminIds: [ref.watch(userProvider).id],
                      allUserIds: [ref.watch(userProvider).id, ...userIds],
                      lastMessage: '',
                    );
                    addChat(groupChat);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : const SizedBox()
        ],
      ),
      body: StreamBuilder<List<User>>(
        stream: getUsers(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Loader();
          // }
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var sortList = snapshot.data!;
                sortList.sort(
                  (a, b) => a.name!.compareTo(b.name!),
                );
                var user = sortList[index];
                return InkWell(
                  onTap: () {
                    Chat peerChat = Chat(
                      id: const Uuid().v4(),
                      name: '${ref.watch(userProvider).name} ${user.name}',
                      photo: '',
                      isGroup: false,
                      peerUserId: user.id,
                      peerUserName: user.name ?? '',
                      userIds: [],
                      adminIds: [ref.watch(userProvider).id, user.id],
                      allUserIds: [ref.watch(userProvider).id, user.id],
                      lastMessage: '',
                    );
                    addChat(peerChat);
                    Navigator.of(context).pop();

                    // isGroup
                    //     ? mutiSelectUsers(user)
                    //     : addChat(peerChat);
                  },
                  child: ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                    title: Text(user.name!),
                    subtitle: Text(user.email!),
                    trailing:
                        userList.contains(user) ? const Icon(Icons.done) : null,
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

class Loader extends StatelessWidget {
  const Loader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
