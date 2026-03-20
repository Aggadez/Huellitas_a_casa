import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huellitas_a_casa/domain/entities/pet.dart';

class PetModel extends Pet {
  const PetModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.species,
    required super.description,
    required super.imageUrl,
    required super.lostAt,
    required super.location,
    required super.createdAt,
    required super.reunited,
  });

  factory PetModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final position = data['position'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return PetModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      species: data['species'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      lostAt: (data['lostAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: position['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reunited: data['reunited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore({required Map<String, dynamic> geoData}) {
    return <String, dynamic>{
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'description': description,
      'imageUrl': imageUrl,
      'lostAt': Timestamp.fromDate(lostAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'reunited': reunited,
      'position': geoData,
    };
  }
}
