import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:flutter_chat_research/core/utils/firebase_function.dart';

import '../../../auth/models/user.dart';
import '../../message/presentation/message_list_page.dart';

class UserListPage extends ConsumerStatefulWidget {
  final Chat? chat;
  final String? addUser;
  const UserListPage({this.chat, this.addUser, super.key});

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
                    List<String> userIds = [...widget.chat!.allUserIds];
                    List<String?> gpName = [];
                    for (var element in userList) {
                      gpName.add(element.name);
                      if (ref.watch(userProvider)!.id != element.id) {
                        userIds.add(element.id);
                      }
                    }
                    Chat groupChat = Chat(
                      id: const Uuid().v4(),
                      name: gpName.join(', '),
                      photo: '',
                      isGroup: true,
                      userIds: [...userIds],
                      adminIds: [ref.watch(userProvider)!.id],
                      allUserIds: [ref.watch(userProvider)!.id, ...userIds],
                      lastMessage: '',
                      peerUserId: '',
                      peerUserName: '',
                    );

                    widget.addUser.toString() == 'adduser'
                        ? addUserInGroupChat(
                                userIds.toSet().toList(), widget.chat!)
                            .then((value) => Navigator.of(context).pop())
                        : userList.length == 1
                            ? {
                                getPeerChat(
                                  ref.watch(userProvider)!.id,
                                  userList[0].id,
                                ).then((value) {
                                  if (value == null) {
                                    Navigator.of(context)
                                        .pushReplacement(MaterialPageRoute(
                                      builder: (context) => MessageListPage(
                                          chat: Chat(
                                        id: const Uuid().v4(),
                                        name: userList[0].name,
                                        photo: '',
                                        isGroup: false,
                                        peerUserId: userList[0].id,
                                        peerUserName: userList[0].name,
                                        userIds: [],
                                        adminIds: [],
                                        allUserIds: [],
                                        lastMessage: '',
                                      )),
                                    ));
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => MessageListPage(
                                          chat: value,
                                        ),
                                      ),
                                    );
                                  }
                                })
                              }
                            : Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => MessageListPage(
                                    chat: groupChat,
                                  ),
                                ),
                              );
                  },
                  child:
                      const Text('Done', style: TextStyle(color: Colors.white)),
                )
              : const SizedBox()
        ],
      ),
      body: StreamBuilder<List<User>>(
        stream: getUsers(
            widget.chat?.allUserIds ?? [], ref.watch(userProvider)!.id),
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
                  (a, b) => a.name.compareTo(b.name),
                );
                var user = sortList[index];
                return InkWell(
                  onTap: () {
                    isGroup
                        ? mutiSelectUsers(user)
                        : {
                            getPeerChat(
                              ref.watch(userProvider)!.id,
                              user.id,
                            ).then((value) {
                              if (value == null) {
                                Navigator.of(context)
                                    .pushReplacement(MaterialPageRoute(
                                  builder: (context) => MessageListPage(
                                      chat: Chat(
                                    id: const Uuid().v4(),
                                    name: user.name,
                                    photo: '',
                                    isGroup: isGroup,
                                    peerUserId: user.id,
                                    peerUserName: user.name,
                                    userIds: [],
                                    adminIds: [],
                                    allUserIds: [],
                                    lastMessage: '',
                                  )),
                                ));
                              } else {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => MessageListPage(
                                      chat: value,
                                    ),
                                  ),
                                );
                              }
                            })
                          };
                  },
                  child: ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                    title: Text(user.name),
                    subtitle: Text(user.email),
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
