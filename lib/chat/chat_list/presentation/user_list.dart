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
  Future<void> addChat(Chat chat) async {
    await FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('chats')
        .doc(chat.id)
        .set(chat.toJson());
  }

  Stream<List<User>> getUser() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('users')
        .snapshots()
        .map((event) {
      List<User> userList = [];
      for (var element in event.docs) {
        userList.add(User.fromJson(element.data()));
      }
      return userList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose User'),
      ),
      body: StreamBuilder<List<User>>(
        stream: getUser(),
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
                    Chat chat = Chat(
                      id: const Uuid().v4(),
                      name: '${ref.watch(userProvider).name} & ${user.name}',
                      isGroup: '',
                      users: [ref.watch(userProvider).toJson(), user.toJson()],
                      messages: [],
                    );
                    widget.chat != null
                        ? addUserInChat(user, widget.chat!)
                        : addChat(chat);
                    Navigator.of(context).pop();
                  },
                  child: ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                    title: Text(user.name!),
                    subtitle: Text(user.email!),
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
