import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huellitas_a_casa/domain/entities/sighting.dart';

class SightingModel extends Sighting {
  const SightingModel({
    required super.id,
    required super.reporterId,
    required super.species,
    required super.description,
    required super.imageUrl,
    required super.location,
    required super.createdAt,
  });

  factory SightingModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final position = data['position'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return SightingModel(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      species: data['species'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      location: position['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({required Map<String, dynamic> geoData}) {
    return <String, dynamic>{
      'reporterId': reporterId,
      'species': species,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'position': geoData,
    };
  }
}
