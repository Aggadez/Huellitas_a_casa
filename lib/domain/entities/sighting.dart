import 'package:cloud_firestore/cloud_firestore.dart';

class Sighting {
  const Sighting({
    required this.id,
    required this.reporterId,
    required this.species,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String species;
  final String description;
  final String imageUrl;
  final GeoPoint location;
  final DateTime createdAt;
}
