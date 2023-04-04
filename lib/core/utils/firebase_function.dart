import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';

import '../../auth/models/user.dart';

// Stream<List<Message>> getMessage() {
//   return FirebaseFirestore.instance
//       .collection('org')
//       .doc('org_id')
//       .collection('messages')
//       .where('chatId', isEqualTo: widget.chat.id)
//       .snapshots()
//       .map((event) {
//     // QuerySnapshot<Map<String, dynamic>>
//     List<Message> messageList = [];
//     for (var element in event.docs) {
//       // List<QueryDocumentSnapshot<Map<String, dynamic>>>
//       messageList.add(Message.fromJson(element.data()));
//     }
//     return messageList;
//   });
// }

// add user
Future<void> addUser(User user) async {
  await FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('users')
      .doc(user.id)
      .set(user.toJson());
}

// get users
Stream<List<User>> getUsers(List<String> groupUserIds, String currentUserId) {
  if (groupUserIds.isEmpty) {
    return FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((event) {
      List<User> userList = [];
      for (var element in event.docs) {
        userList.add(User.fromJson(element.data()));
      }
      return userList;
    });
  }

  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('users')
      // .where('id', isNotEqualTo: ref.watch(userProvider)!.id)
      .where('id', whereNotIn: groupUserIds)
      .snapshots()
      .map((event) {
    List<User> userList = [];
    for (var element in event.docs) {
      userList.add(User.fromJson(element.data()));
    }
    return userList;
  });
}

// Future<User?> getUserInLocal(String userId, WidgetRef ref) async {
//   return FirebaseFirestore.instance
//       .collection('org')
//       .doc('org_id')
//       .collection('users')
//       .doc(userId)
//       .get()
//       .then((DocumentSnapshot documentSnapshot) {
//     if (documentSnapshot.exists) {
//       var docData = documentSnapshot.data() as Map<String, dynamic>;
//       var user = User.fromJson(docData);
//       // print('Document data: ${documentSnapshot.data()}');
//       ref.read(userProvider.notifier).update((state) => user);
//       return user;
//     } else {
//       // print('Document does not exist on the database');
//       return null;
//     }
//   });
// }

// receiverUser > msg detail
Future<User?> getUser(String userId) {
  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('users')
      .doc(userId)
      .get()
      .then((DocumentSnapshot documentSnapshot) {
    if (documentSnapshot.exists) {
      var docData = documentSnapshot.data() as Map<String, dynamic>;
      var userMapData = User.fromJson(docData);
      // print('Document data: ${documentSnapshot.data()}');
      // print('userMapData data: $userMapData');
      return userMapData;
    } else {
      // print('Document does not exist on the database');
      return null;
    }
  });
}

// login, register
Future<User?> getUserWithName(String name) {
  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('users')
      .where('name', isEqualTo: name)
      .get()
      .then((documentSnapshot) {
    if (documentSnapshot.docs.isNotEmpty) {
      var docData = documentSnapshot.docs[0].data();
      var userMapData = User.fromJson(docData);
      return userMapData;
    } else {
      return null;
    }
  });
}

// add user in group > user list
Future<void> addUserInGroupChat(List<String> userList, Chat chat) async {
  await FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('groupChats')
      .doc(chat.id)
      .update({
    'allUserIds': [...userList]
  });
}

Future<void> addChatWithId(Chat chat, String userId) async {
  await FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('chatUsers')
      .doc(userId)
      .collection('chats')
      .doc(chat.id)
      .set(chat.toJson());
}

Future<void> addGroupChat(Chat chat) async {
  await FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('groupChats')
      .doc(chat.id)
      .set(chat.toJson());
}

// stream chat/ peer
Stream<List<Chat>> getPeerChats(User user) {
  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('chatUsers')
      .doc(user.id)
      .collection('chats')
      .where('allUserIds', arrayContainsAny: [user.id])
      .snapshots()
      .map((event) {
        List<Chat> messageList = [];
        for (var element in event.docs) {
          messageList.add(Chat.fromJson(element.data()));
        }
        return messageList;
      });
}

// stream chat/ group
Stream<List<Chat>> getGroupChats(User user) {
  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('groupChats')
      .where('allUserIds', arrayContainsAny: [user.id])
      .snapshots()
      .map((event) {
        List<Chat> messageList = [];
        for (var element in event.docs) {
          messageList.add(Chat.fromJson(element.data()));
        }
        return messageList;
      });
}

// group chat
Future<Chat?> getGroupChat(String chatId) {
  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('groupChats')
      .doc(chatId)
      .get()
      .then((documentSnapshot) {
    var docData = documentSnapshot.data();
    if (docData != null) {
      var chat = Chat.fromJson(docData);
      return chat;
    } else {
      return null;
    }
  });
}

// peer chat > user list
Future<Chat?> getPeerChat(String userId, String peerUserId) {
  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('chatUsers')
      .doc(userId)
      .collection('chats')
      .where('peerUserId', isEqualTo: peerUserId)
      .get()
      .then((documentSnapshot) {
    if (documentSnapshot.docs.isNotEmpty) {
      var docData = documentSnapshot.docs[0].data();
      var chat = Chat.fromJson(docData);
      return chat;
    } else {
      return null;
    }
  });
}
