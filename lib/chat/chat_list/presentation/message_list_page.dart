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
import '../../../core/utils/firebase_function.dart';
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
        debugPrint('products empty : true');
        requestPage();
      } else {
        jump = false;
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
        List<Message> setProducts = products.toSet().toList();
        _streamController.add(setProducts);
      });
    } else {
      await FirebaseFirestore.instance
          .collection('org')
          .doc('org_id')
          .collection('messages')
          .where('chatId', isEqualTo: widget.chat.id)
          .orderBy('sendOn', descending: true)
          .startAfterDocument(_docSnapshot!)
          .limit(20)
          .get()
          .then((value) {
        for (var element in value.docs) {
          /// List<QueryDocumentSnapshot<Map<String, dynamic>>>
          products.add(Message.fromJson(element.data()));
          _docSnapshot = element;
        }
        List<Message> setProducts = products.toSet().toList();
        _streamController.add(setProducts);
      });
    }
  }

  void onChangeData(
      List<DocumentChange<Map<String, dynamic>>> documentChanges) {
    var isChange = false;
    List<Message> setProducts = products.toSet().toList();
    products.clear();
    products = setProducts;
    _streamController.add(setProducts);
    documentChanges.forEach((productChange) {
      if (productChange.type == DocumentChangeType.removed) {
        // print('onchange : before removed : $products');
        products.removeWhere((product) {
          return productChange.doc.id == product.id;
        });
        // print('onchange : after removed : $products');
        isChange = true;
      } else {
        if (productChange.type == DocumentChangeType.modified) {
          int indexWhere = products.indexWhere((product) {
            return productChange.doc.id == product.id;
          });
          if (indexWhere >= 0) {
            // print('onchange : before modified : $products');
            products[indexWhere] = Message.fromJson(productChange.doc.data()!);
            // print('onchange : after modified : $products');
          }
          isChange = true;
        } else if (productChange.type == DocumentChangeType.added) {
          // print('onchange : before added : $products');
          products.add(Message.fromJson(documentChanges[0].doc.data()!));
          // print('onchange : after added : $products');
          isChange = true;
          if (mounted) {
            var msg = Message.fromJson(productChange.doc.data()!);
            if (msg.senderId == ref.watch(userProvider)!.id) {
              SchedulerBinding.instance.addPostFrameCallback(
                (timeStamp) {
                  controller.jumpTo(controller.position.maxScrollExtent);
                },
              );
            }
          }
        }
      }
    });
    if (isChange) {
      List<Message> setProducts = products.toSet().toList();
      products.clear();
      products = setProducts;
      _streamController.add(products);
    }
  }

  @override
  Widget build(BuildContext context) {
    var networkStatus = ref.watch(networkStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: widget.chat.isGroup
            ? Text(widget.chat.name)
            : Text(widget.chat.peerUserName),
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
              User currentUser = ref.watch(userProvider)!;
              Message message = Message(
                chatId: widget.chat.id,
                id: const Uuid().v4(),
                senderId: currentUser.id,
                receiverIds: [widget.chat.peerUserId],
                text: text,
                sendOn: DateTime.now(),
                status: 'offline',
              );

              // final id = const Uuid().v4();
              Chat currentUserChat = Chat(
                id: widget.chat.id,
                name: currentUser.name,
                photo: '',
                isGroup: false,
                peerUserId: currentUser.id,
                peerUserName: currentUser.name,
                userIds: [],
                adminIds: [currentUser.id, widget.chat.peerUserId],
                allUserIds: [currentUser.id, widget.chat.peerUserId],
                lastMessage: '',
              );

              Chat peerUserChat = Chat(
                id: widget.chat.id,
                name: widget.chat.name.toString(),
                photo: '',
                isGroup: false,
                peerUserId: widget.chat.peerUserId,
                peerUserName: widget.chat.peerUserName,
                userIds: [],
                adminIds: [currentUser.id, widget.chat.peerUserId],
                allUserIds: [currentUser.id, widget.chat.peerUserId],
                lastMessage: '',
              );

              addChatWithId(currentUserChat, widget.chat.id);
              addChatWithId(peerUserChat, currentUser.id);
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
            if (jump) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                controller.jumpTo(controller.position.maxScrollExtent);
              });
            }

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
                  networkStatus == NetworkStatus.connected
                      ? setMessageStatus(message.id, 'online')
                      : null;
                } else if (message.status.toLowerCase() == 'online' &&
                    message.senderId != ref.watch(userProvider)!.id) {
                  networkStatus == NetworkStatus.connected
                      ? setMessageStatus(message.id, 'seen')
                      : null;
                }

                var date =
                    DateFormat('dd/MM/yyyy HH:mm').format(message.sendOn);

                return message.senderId == ref.watch(userProvider)!.id
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
