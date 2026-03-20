import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:huellitas_a_casa/data/models/user_model.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._messaging);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _upsertFcmToken();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String alias,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final token = await _messaging.getToken();
    final user = UserModel(
      id: cred.user!.uid,
      email: email,
      alias: alias,
      createdAt: DateTime.now(),
      fcmToken: token,
    );
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _upsertFcmToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    await _firestore.collection('users').doc(uid).set(
      <String, dynamic>{'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}
