import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';
import 'package:flutter_chat_research/chat/share/chat_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/models/user.dart';

// add user
Future<void> addUser(User user) async {
  await FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('users')
      .doc(user.id)
      .set(user.toJson());
}

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

Future<void> addUserInChat(User user, Chat chat) async {
  await FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('chats')
      .doc(chat.id)
      .update({
    'userIds': [...chat.userIds, user..id]
  });
}

Future<User?> getUserInLocal(String userId, WidgetRef ref) async {
  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('users')
      .doc(userId)
      .get()
      .then((DocumentSnapshot documentSnapshot) {
    if (documentSnapshot.exists) {
      var docData = documentSnapshot.data() as Map<String, dynamic>;
      var user = User.fromJson(docData);
      // print('Document data: ${documentSnapshot.data()}');
      ref.read(userProvider.notifier).update((state) => user);
      return user;
    } else {
      // print('Document does not exist on the database');
      return null;
    }
  });
}

Future<Chat?> getPeerChat(String userId, String peerUserId) {
  debugPrint('getPeerChat : start');
  debugPrint('getPeerChat : $userId, $peerUserId');

  return FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('chatUsers')
      .doc(userId)
      .collection('chats')
      .where('peerUserId', isEqualTo: peerUserId)
      .get()
      .then((documentSnapshot) {
    print('getPeerChat : ${documentSnapshot.docs.length}');
    if (documentSnapshot.docs.isNotEmpty) {
      var docData = documentSnapshot.docs[0].data();
      var chat = Chat.fromJson(docData);
      print('getPeerChat data: $chat');
      return chat;
    } else {
      // print('getPeerChat does not exist on the database');
      return null;
    }
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
