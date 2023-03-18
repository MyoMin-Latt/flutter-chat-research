import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_research/chat/models/chat.dart';

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

Future<void> addUserInChat(User user, Chat chat) async {
  await FirebaseFirestore.instance
      .collection('org')
      .doc('org_id')
      .collection('chats')
      .doc(chat.id)
      .update({
    'users': [...chat.users, user.toJson()]
  });
}
