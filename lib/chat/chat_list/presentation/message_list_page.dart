// import 'dart:async';
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

// class MessageListPage extends ConsumerStatefulWidget {
//   final Chat chat;
//   const MessageListPage({
//     super.key,
//     required this.chat,
//   });

//   @override
//   ConsumerState<ConsumerStatefulWidget> createState() => _MessageListState();
// }

// class _MessageListState extends ConsumerState<MessageListPage> {
//   final _streamController = StreamController<List<DocumentSnapshot>>();
//   List<DocumentSnapshot> _products = [];

//   bool _isRequesting = false;
//   bool _isFinish = false;

//   Stream<List<Message>> getMessage() {
//     return FirebaseFirestore.instance
//         .collection('org')
//         .doc('org_id')
//         .collection('messages')
//         .where('chatId', isEqualTo: widget.chat.id)
//         .snapshots()
//         .map((event) {
//       // QuerySnapshot<Map<String, dynamic>>
//       List<Message> messageList = [];
//       for (var element in event.docs) {
//         // List<QueryDocumentSnapshot<Map<String, dynamic>>>
//         messageList.add(Message.fromJson(element.data()));
//       }
//       return messageList;
//     });
//   }

//   String generateRandomString(int lengthOfString) {
//     final random = Random();
//     const allChars = 'ABCDEFGabcdefghijklmnopqrstuvwxyz';

//     final randomString = List.generate(lengthOfString,
//         (index) => allChars[random.nextInt(allChars.length)]).join();
//     return randomString;
//   }

//   Future<void> sendMessage(Message message) async {
//     await FirebaseFirestore.instance
//         .collection('org')
//         .doc('org_id')
//         .collection('messages')
//         .doc(message.id)
//         .set(message.toJson());
//   }

//   Future<void> setMessageStatus(String messageId, String status) async {
//     await FirebaseFirestore.instance
//         .collection('org')
//         .doc('org_id')
//         .collection('messages')
//         .doc(messageId)
//         .update({
//       'status': status,
//     });
//   }

//   void onChangeData(List<DocumentChange> documentChanges) {
//     var isChange = false;
//     debugPrint('MessageListPage : onChangeData : start');

//     // ignore: avoid_function_literals_in_foreach_calls
//     documentChanges.forEach((productChange) {
//       if (productChange.type == DocumentChangeType.removed) {
//         _products.removeWhere((product) {
//           return productChange.doc.id == product.id;
//         });
//         isChange = true;
//       } else {
//         if (productChange.type == DocumentChangeType.modified) {
//           int indexWhere = _products.indexWhere((product) {
//             return productChange.doc.id == product.id;
//           });

//           if (indexWhere >= 0) {
//             _products[indexWhere] = productChange.doc;
//           }
//           isChange = true;
//         }
//       }
//     });

//     if (isChange) {
//       _streamController.add(_products);
//     }
//   }

//   void requestNextPage() async {
//     debugPrint('MessageListPage : requestNextPage : start');
//     debugPrint(
//         'MessageListPage : requestNextPage : $_isRequesting, $_isFinish');
//     if (!_isRequesting && !_isFinish) {
//       debugPrint(
//           'MessageListPage : requestNextPage : !_isRequesting && !_isFinish');

//       QuerySnapshot querySnapshot;
//       _isRequesting = true;
//       if (_products.isEmpty) {
//         querySnapshot = await FirebaseFirestore.instance
//             .collection('org')
//             .doc('org_id')
//             .collection('messages')
//             .where('chatId', isEqualTo: widget.chat.id)
//             .orderBy('index')
//             .limit(5)
//             .get();
//         debugPrint(querySnapshot.docs.toString());
//       } else {
//         debugPrint(
//             'MessageListPage : requestNextPage : Else : !_isRequesting && !_isFinish');
//         querySnapshot = await FirebaseFirestore.instance
//             .collection('org')
//             .doc('org_id')
//             .collection('messages')
//             .where('chatId', isEqualTo: widget.chat.id)
//             .orderBy('index')
//             .startAfterDocument(_products[_products.length - 1])
//             .limit(5)
//             .get();
//       }

//       if (querySnapshot != null) {
//         int oldSize = _products.length;
//         _products.addAll(querySnapshot.docs);
//         int newSize = _products.length;
//         if (oldSize != newSize) {
//           _streamController.add(_products);
//         } else {
//           _isFinish = true;
//         }
//       }
//       _isRequesting = false;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     FirebaseFirestore.instance
//         .collection('products')
//         .snapshots()
//         .listen((data) => onChangeData(data.docChanges));

//     requestNextPage();
//   }

//   @override
//   void dispose() {
//     _streamController.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var networkStatus = ref.watch(networkStatusProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.chat.name),
//         actions: [
//           IconButton(
//             onPressed: () => Navigator.of(context).push(MaterialPageRoute(
//               builder: (context) => UserListPage(chat: widget.chat),
//             )),
//             icon: const Icon(Icons.person_add),
//           ),
//           IconButton(
//             onPressed: () {
//               var text = generateRandomString(7);
//               User user = ref.watch(userProvider);
//               Message message = Message(
//                 chatId: widget.chat.id,
//                 id: const Uuid().v4(),
//                 sender: user.toJson(),
//                 text: text,
//                 sendOn: DateTime.now(),
//                 status: 'offline',
//               );
//               debugPrint(
//                   'SendMessage : status-offline : ${message.toJson().toString()}');
//               sendMessage(message);
//             },
//             icon: const Icon(Icons.send),
//           ),
//         ],
//       ),
//       body: NotificationListener<ScrollNotification>(
//         onNotification: (ScrollNotification scrollInfo) {
//           if (scrollInfo.metrics.maxScrollExtent == scrollInfo.metrics.pixels) {
//             requestNextPage();
//           }
//           return true;
//         },
//         child: StreamBuilder<List<DocumentSnapshot>>(
//           stream: _streamController.stream,
//           builder: (context, snapshot) {
//             // if (snapshot.connectionState == ConnectionState.waiting) {
//             //   return const Loader();
//             // }
//             debugPrint('snapshot : $snapshot');

//             if (snapshot.hasData) {
//               if (snapshot.data!.isEmpty) {
//                 return const NoData();
//               }
//               var snaplist = snapshot.data;
//               List<Message> messages = [];
//               for (var element in snaplist!) {
//                 // List<QueryDocumentSnapshot<Map<String, dynamic>>>
//                 messages.add(
//                     Message.fromJson(element.data() as Map<String, dynamic>));
//               }
//               return ListView.builder(
//                 itemCount: messages.length,
//                 itemBuilder: (context, index) {
//                   messages.sort(
//                     (a, b) => a.sendOn.compareTo(b.sendOn),
//                   );
//                   var message = messages[index];

//                   if (message.status.toLowerCase() == 'offline' &&
//                       message.sender['id'] == ref.watch(userProvider).id) {
//                     networkStatus == NetworkStatus.connected
//                         ? setMessageStatus(message.id, 'online')
//                         : null;
//                   } else if (message.status.toLowerCase() == 'online' &&
//                       message.sender['id'] != ref.watch(userProvider).id) {
//                     networkStatus == NetworkStatus.connected
//                         ? setMessageStatus(message.id, 'seen')
//                         : null;
//                   }

//                   return message.sender['id'] == ref.watch(userProvider).id
//                       ? Align(
//                           alignment: Alignment.centerRight,
//                           child: ConstrainedBox(
//                             constraints: BoxConstraints(
//                               maxWidth: MediaQuery.of(context).size.width - 45,
//                               minWidth: 70,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Text(
//                                 '$index. ${message.text} sent by ${message.sender['name']}  ${message.status}',
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             ),
//                           ),
//                         )
//                       : Align(
//                           alignment: Alignment.centerLeft,
//                           child: ConstrainedBox(
//                             constraints: BoxConstraints(
//                               maxWidth: MediaQuery.of(context).size.width - 45,
//                               minWidth: 70,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Text(
//                                 '$index. ${message.text} sent by ${message.sender['name']}',
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             ),
//                           ),
//                         );
//                   // }
//                 },
//               );
//             } else {
//               return const Loader();
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
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
