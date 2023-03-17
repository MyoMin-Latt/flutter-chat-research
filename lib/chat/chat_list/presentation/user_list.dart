import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/models/user.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  Stream<List<User>> getUser() {
    return FirebaseFirestore.instance
        .collection('mml')
        .doc('mml_id')
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
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
                  onTap: () {},
                  // onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  //   builder: (context) => MobileChatScreen(
                  //       name: user.name, uid: 'uid', isGroupChat: false),
                  // )),
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
