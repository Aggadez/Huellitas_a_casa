import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationRepository {
  ModerationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<Set<String>> hiddenPostIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('hidden_posts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<Set<String>> blockedUserIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('blocked_users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> reportPost({
    required String actorUid,
    required String reportKey,
    required String ownerUid,
    required String reason,
  }) async {
    final batch = _firestore.batch();
    final hiddenRef = _firestore
        .collection('users')
        .doc(actorUid)
        .collection('hidden_posts')
        .doc(reportKey);
    batch.set(hiddenRef, <String, dynamic>{
      'ownerUid': ownerUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final reportRef = _firestore.collection('ugc_reports').doc();
    batch.set(reportRef, <String, dynamic>{
      'actorUid': actorUid,
      'ownerUid': ownerUid,
      'reportKey': reportKey,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> blockUser({
    required String actorUid,
    required String blockedUid,
  }) async {
    await _firestore
        .collection('users')
        .doc(actorUid)
        .collection('blocked_users')
        .doc(blockedUid)
        .set(<String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
