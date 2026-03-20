class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.alias,
    required this.createdAt,
    required this.fcmToken,
  });

  final String id;
  final String email;
  final String alias;
  final DateTime createdAt;
  final String? fcmToken;
}
