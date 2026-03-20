import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AccountRepository {
  AccountRepository(this._auth, this._firestore, this._storage);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> deleteAccountAndData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa.');
    }

    final uid = user.uid;
    await _deleteUserOwnedDocuments(uid);
    await _deleteUserStorage(uid);
    await _firestore.collection('users').doc(uid).delete();
    await user.delete();
  }

  Future<void> _deleteUserOwnedDocuments(String uid) async {
    final batch = _firestore.batch();
    final lost = await _firestore.collection('lost_pets').where('ownerId', isEqualTo: uid).get();
    final sightings =
        await _firestore.collection('sightings').where('reporterId', isEqualTo: uid).get();
    final reports = await _firestore.collection('ugc_reports').where('actorUid', isEqualTo: uid).get();

    for (final doc in lost.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in sightings.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in reports.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _deleteUserStorage(String uid) async {
    final root = _storage.ref('users/$uid');
    await _deleteFolderRecursively(root);
  }

  Future<void> _deleteFolderRecursively(Reference reference) async {
    final listResult = await reference.listAll();
    for (final item in listResult.items) {
      await item.delete();
    }
    for (final prefix in listResult.prefixes) {
      await _deleteFolderRecursively(prefix);
    }
  }
}
