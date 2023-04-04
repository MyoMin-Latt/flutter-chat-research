// import 'dart:async';
// import 'dart:math';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:flutter_chat_research/chat/models/chat.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';

// import 'package:flutter_chat_research/chat/chat_list/presentation/user_list.dart';
// import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';

// import '../../../auth/models/user.dart';
// import '../../../core/share/core_provider.dart';
// import '../../../core/utils/firebase_function.dart';
// import '../../models/message.dart';
// import '../../share/chat_provider.dart';
// import 'message_detail_page.dart';

// class MessageListStreamPage extends ConsumerStatefulWidget {
//   final Chat chat;
//   const MessageListStreamPage({
//     super.key,
//     required this.chat,
//   });

//   @override
//   ConsumerState<ConsumerStatefulWidget> createState() => _MessageListState();
// }

// class _MessageListState extends ConsumerState<MessageListStreamPage> {
//   final controller = ScrollController();
//   bool jump = true;
//   final _streamController = StreamController<List<Message>>();
//   List<Message> products = [];
//   DocumentSnapshot<Object?>? _docSnapshot;

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
//     debugPrint('sendMessage : $message');
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

//   Future<void> addReceiverId(Message message, String userId) async {
//     await FirebaseFirestore.instance
//         .collection('org')
//         .doc('org_id')
//         .collection('messages')
//         .doc(message.id)
//         .update({
//       'receiverIds': [...message.receiverIds, userId]
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     var networkStatus = ref.watch(networkStatusProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: widget.chat.isGroup
//             ? Text(widget.chat.name)
//             : Text(widget.chat.peerUserName),
//         actions: [
//           widget.chat.isGroup
//               ? IconButton(
//                   onPressed: () => getGroupChat(widget.chat.id)
//                       .then((value) => Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   UserListPage(chat: value, addUser: 'adduser'),
//                             ),
//                           )),
//                   icon: const Icon(Icons.person_add),
//                 )
//               : const SizedBox(),
//           IconButton(
//             onPressed: () {
//               var text = generateRandomString(7);
//               User currentUser = ref.watch(userProvider)!;
//               Message message = Message(
//                 chatId: widget.chat.id,
//                 id: const Uuid().v4(),
//                 senderId: currentUser.id,
//                 receiverIds: widget.chat.isGroup
//                     ? [currentUser.id]
//                     : [widget.chat.peerUserId],
//                 text: text,
//                 sendOn: DateTime.now(),
//                 status: 'offline',
//               );

//               // final id = const Uuid().v4();
//               Chat currentUserChat = Chat(
//                 id: widget.chat.id,
//                 name: currentUser.name,
//                 photo: '',
//                 isGroup: false,
//                 peerUserId: currentUser.id,
//                 peerUserName: currentUser.name,
//                 userIds: [],
//                 adminIds: [currentUser.id, widget.chat.peerUserId],
//                 allUserIds: [currentUser.id, widget.chat.peerUserId],
//                 lastMessage: '',
//               );

//               Chat peerUserChat = Chat(
//                 id: widget.chat.id,
//                 name: widget.chat.name.toString(),
//                 photo: '',
//                 isGroup: false,
//                 peerUserId: widget.chat.peerUserId,
//                 peerUserName: widget.chat.peerUserName,
//                 userIds: [],
//                 adminIds: [currentUser.id, widget.chat.peerUserId],
//                 allUserIds: [currentUser.id, widget.chat.peerUserId],
//                 lastMessage: '',
//               );
//               widget.chat.isGroup
//                   ? addGroupChat(widget.chat)
//                   : {
//                       addChatWithId(currentUserChat, widget.chat.peerUserId),
//                       addChatWithId(peerUserChat, currentUser.id)
//                     };
//               sendMessage(message);
//             },
//             icon: const Icon(Icons.send),
//           ),
//         ],
//       ),
//       body: StreamBuilder<List<Message>>(
//         stream: getMessage(),
//         builder: (context, snapshot) {
//           if (snapshot.hasData) {
//             List<Message>? messageList = snapshot.data;
//             if (jump) {
//               SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
//                 controller.jumpTo(controller.position.maxScrollExtent);
//               });
//             }

//             return ListView.builder(
//               controller: controller,
//               itemCount: messageList!.length,
//               itemBuilder: (context, index) {
//                 var sortList = messageList;
//                 sortList.sort(
//                   (a, b) => a.sendOn.compareTo(b.sendOn),
//                 );
//                 var message = sortList[index];

//                 if (message.status.toLowerCase() == 'offline') {
//                   networkStatus == NetworkStatus.connected
//                       ? setMessageStatus(message.id, 'online')
//                       : null;
//                 } else if (message.status.toLowerCase() == 'online' &&
//                     message.senderId != ref.watch(userProvider)!.id) {
//                   networkStatus == NetworkStatus.connected
//                       ? setMessageStatus(message.id, 'seen')
//                       : null;
//                 } else if (!message.receiverIds
//                     .contains(ref.watch(userProvider)!.id)) {
//                   networkStatus == NetworkStatus.connected
//                       ? addReceiverId(message, ref.watch(userProvider)!.id)
//                       : null;
//                 }

//                 var date =
//                     DateFormat('dd/MM/yyyy HH:mm').format(message.sendOn);

//                 return message.senderId == ref.watch(userProvider)!.id
//                     ? Align(
//                         alignment: Alignment.centerRight,
//                         child: ConstrainedBox(
//                           constraints: BoxConstraints(
//                             maxWidth: MediaQuery.of(context).size.width - 45,
//                             minWidth: 70,
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   '$index. ${message.text}',
//                                   style: const TextStyle(fontSize: 16),
//                                 ),
//                                 Text(
//                                   '$date ${message.status}',
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       )
//                     : InkWell(
//                         onTap: () {
//                           messageDetial(context, message);
//                         },
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child: ConstrainedBox(
//                             constraints: BoxConstraints(
//                               maxWidth: MediaQuery.of(context).size.width - 45,
//                               minWidth: 70,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     '$index. ${message.text}',
//                                     style: const TextStyle(fontSize: 16),
//                                   ),
//                                   Text(
//                                     date,
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                 // }
//               },
//             );
//           } else {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//         },
//       ),
//     );
//   }

//   Future<void> messageDetial(BuildContext context, Message message) {
//     return showModalBottomSheet<void>(
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       context: context,
//       builder: (BuildContext context) => DraggableScrollableSheet(
//         initialChildSize: 0.9,
//         minChildSize: 0.5,
//         maxChildSize: 0.9,
//         builder: (_, controller) => Container(
//           decoration: const BoxDecoration(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//               color: Colors.white),
//           child: MessageDetailPage(message, controller),
//         ),
//       ),
//     );
//   }
// }
