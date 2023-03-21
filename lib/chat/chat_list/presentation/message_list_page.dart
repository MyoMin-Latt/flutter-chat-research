import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
import 'package:intl/intl.dart';
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
  final controller = ScrollController();
  bool jump = true;
  Stream<List<Message>> getMessage() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .where('chatId', isEqualTo: widget.chat.id)
        .snapshots()
        .map((event) {
      // QuerySnapshot<Map<String, dynamic>>
      List<Message> messageList = [];
      for (var element in event.docs) {
        // List<QueryDocumentSnapshot<Map<String, dynamic>>>
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
    debugPrint('sendMessage : $message');
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

  final _streamController = StreamController<List<Message>>();
  List<Message> products = [];
  DocumentSnapshot<Object?>? _docSnapshot;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .where('chatId', isEqualTo: widget.chat.id)
        .snapshots()
        .listen((data) {
      debugPrint('Firebase listen : start');
      if (products.isEmpty) {
        requestPage();
      } else {
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          controller.jumpTo(controller.position.maxScrollExtent);
        });
        onChangeData(data.docChanges);
      }
    });

    controller.addListener(() {
      if (controller.position.minScrollExtent == controller.offset) {
        setState(() => jump = false);
        requestPage();
      }
    });
  }

  void requestPage() async {
    if (products.isEmpty) {
      await FirebaseFirestore.instance
          .collection('org')
          .doc('org_id')
          .collection('messages')
          .where('chatId', isEqualTo: widget.chat.id)
          .orderBy('sendOn', descending: true)
          .limit(20)
          .get()
          .then((value) {
        for (var element in value.docs) {
          /// List<QueryDocumentSnapshot<Map<String, dynamic>>>
          products.add(Message.fromJson(element.data()));
          _docSnapshot = element;
        }
        _streamController.add(products);
      });
    } else {
      await FirebaseFirestore.instance
          .collection('org')
          .doc('org_id')
          .collection('messages')
          .where('chatId', isEqualTo: widget.chat.id)
          .orderBy('sendOn', descending: true)
          // .startAfter(products)
          .startAfterDocument(_docSnapshot!)
          .limit(20)
          .get()
          .then((value) {
        for (var element in value.docs) {
          /// List<QueryDocumentSnapshot<Map<String, dynamic>>>
          products.add(Message.fromJson(element.data()));
          _docSnapshot = element;
        }
        _streamController.add(products);
      });
    }
  }

  void onChangeData(
      List<DocumentChange<Map<String, dynamic>>> documentChanges) {
    var isChange = false;
    documentChanges.forEach((productChange) {
      if (productChange.type == DocumentChangeType.removed) {
        products.removeWhere((product) {
          return productChange.doc.id == product.id;
        });
        isChange = true;
      } else {
        if (productChange.type == DocumentChangeType.modified) {
          int indexWhere = products.indexWhere((product) {
            return productChange.doc.id == product.id;
          });
          if (indexWhere >= 0) {
            products[indexWhere] = Message.fromJson(productChange.doc.data()!);
          }
          isChange = true;
        } else if (productChange.type == DocumentChangeType.added) {
          products.add(Message.fromJson(documentChanges[0].doc.data()!));
          isChange = true;
        }
      }
    });
    if (isChange) {
      _streamController.add(products);
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    _streamController.close();
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
              sendMessage(message);
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Message>? messageList = snapshot.data;
            // (messageList != null && messageList.length < 20)
            //     ? SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            //         controller.jumpTo(controller.position.maxScrollExtent);
            //       })
            //     : null;
            if (jump) {
              print('Jumb in ListView : $jump');
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                controller.jumpTo(controller.position.maxScrollExtent);
              });
            }

            debugPrint(
                'snapshot / messageList.lenght : ${messageList?.length}');
            return ListView.builder(
              controller: controller,
              itemCount: messageList!.length,
              itemBuilder: (context, index) {
                var sortList = messageList;
                sortList.sort(
                  (a, b) => a.sendOn.compareTo(b.sendOn),
                );
                var message = sortList[index];

                if (message.status.toLowerCase() == 'offline') {
                  // add internet connection state
                  networkStatus == NetworkStatus.connected
                      ? setMessageStatus(message.id, 'online')
                      : null;
                } else if (message.status.toLowerCase() == 'online' &&
                    message.sender['id'] != ref.watch(userProvider).id) {
                  networkStatus == NetworkStatus.connected
                      ? setMessageStatus(message.id, 'seen')
                      : null;
                }

                var date =
                    DateFormat('dd/MM/yyyy HH:mm').format(message.sendOn);

                return message.sender['id'] == ref.watch(userProvider).id
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 45,
                            minWidth: 70,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$index. ${message.text}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '$date ${message.status}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 45,
                            minWidth: 70,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$index. ${message.text}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  date,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                // }
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_chat_research/chat/models/chat.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
// import 'package:uuid/uuid.dart';
// import '../../../auth/models/user.dart';
// import '../../../core/share/core_provider.dart';
// import '../../models/message.dart';
// import '../../share/chat_provider.dart';
// import 'atu_chat_page.dart';

class MessageListPage1 extends ConsumerStatefulWidget {
  final Chat chat;
  const MessageListPage1({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MessageListState1();
}

class _MessageListState1 extends ConsumerState<MessageListPage1> {
  Stream<List<Message>> getMessage() {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .where('chatId', isEqualTo: widget.chat.id)
        .snapshots()
        .map((event) {
      // QuerySnapshot<Map<String, dynamic>>
      List<Message> messageList = [];
      for (var element in event.docs) {
        // List<QueryDocumentSnapshot<Map<String, dynamic>>>
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
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .where('chatId', isEqualTo: widget.chat.id)
        .snapshots()
        .listen((data) {
      // QuerySnapshot<Map<String, dynamic>>
      // var snapData = data.docs;
      // debugPrint('listen / snapData : $snapData');
      // List<Message> messageList = [];
      // for (var element in snapData) {
      // List<QueryDocumentSnapshot<Map<String, dynamic>>>
      //   messageList.add(Message.fromJson(element.data()));
      // }
      // Logger().log(Level.warning, 'listen / messageList : $messageList');
      // debugPrint('listen / messageList[0] : ${messageList.length}');

      var snapDataChange = data.docChanges;
      // debugPrint('listen / snapDataChange : $snapDataChange');
      debugPrint('snapDataChange / length : ${snapDataChange.length}');
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
                } else if (message.status.toLowerCase() == 'online' &&
                    message.sender['id'] != ref.watch(userProvider).id) {
                  networkStatus == NetworkStatus.connected
                      ? setMessageStatus(message.id, 'seen')
                      : null;
                }

                return message.sender['id'] == ref.watch(userProvider).id
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 45,
                            minWidth: 70,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '$index. ${message.text} sent by ${message.sender['name']}  ${message.status}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 45,
                            minWidth: 70,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '$index. ${message.text} sent by ${message.sender['name']}  ${message.status}',
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
