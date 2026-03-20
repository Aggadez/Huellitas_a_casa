import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.description,
    required this.imageUrl,
    required this.lostAt,
    required this.location,
    required this.createdAt,
    required this.reunited,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String description;
  final String imageUrl;
  final DateTime lostAt;
  final GeoPoint location;
  final DateTime createdAt;
  final bool reunited;
}
