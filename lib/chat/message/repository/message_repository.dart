import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final messageRepositoryProvider = Provider((ref) {
  return MessageRepository();
});

class MessageRepository {
  Future<List<DocumentSnapshot>> requestFirstPage(String chatId) async {
    return await FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('sendOn', descending: true)
        .limit(20)
        .get()
        .then((value) => value.docs);
  }

  Future<List<DocumentSnapshot>> requestNextPage(
      String chatId, DocumentSnapshot docSnapshot) async {
    return await FirebaseFirestore.instance
        .collection('org')
        .doc('org_id')
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('sendOn', descending: true)
        .startAfterDocument(docSnapshot)
        .limit(20)
        .get()
        .then((value) => value.docs);
  }
}
