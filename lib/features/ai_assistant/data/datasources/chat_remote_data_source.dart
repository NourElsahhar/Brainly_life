import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(FirebaseFirestore firestore, String uid)
    : _firestore = firestore,
      _conversation = firestore
          .collection('users')
          .doc(uid)
          .collection('aiConversations')
          .doc('assistant');

  final FirebaseFirestore _firestore;
  final DocumentReference<Map<String, dynamic>> _conversation;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _conversation.collection('messages');

  String nextMessageId() => _messages.doc().id;

  Future<List<ChatMessage>> load() async {
    final snapshot = await _messages
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.reversed.map((doc) {
      final data = doc.data();
      return ChatMessage(
        id: doc.id,
        role: ChatRole.values.byName(data['role'] as String),
        text: data['text'] as String,
        actions: ChatMessage.parseActions(data['actions']),
        createdAt: ((data['createdAt'] ?? data['clientCreatedAt']) as Timestamp)
            .toDate()
            .toUtc(),
      );
    }).toList();
  }

  Future<void> save(ChatMessage message) async {
    final ref = _messages.doc(message.id);
    await _firestore.runTransaction((transaction) async {
      final parent = await transaction.get(_conversation);
      final existing = await transaction.get(ref);
      if (existing.exists) return;
      transaction.set(_conversation, {
        'title': 'Baseet AI',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!parent.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(ref, {
        'role': message.role.name,
        'text': message.text,
        'actions': message.actions.map((action) => action.toJson()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'clientCreatedAt': Timestamp.fromDate(message.createdAt),
      });
    });
  }

  Future<void> clear() async {
    final cutoff = Timestamp.now();
    while (true) {
      final page = await _messages
          .where('createdAt', isLessThanOrEqualTo: cutoff)
          .limit(200)
          .get();
      if (page.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
