import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huellitas_a_casa/domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    required super.alias,
    required super.createdAt,
    required super.fcmToken,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      alias: data['alias'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'email': email,
      'alias': alias,
      'createdAt': Timestamp.fromDate(createdAt),
      'fcmToken': fcmToken,
    };
  }
}
