import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:huellitas_a_casa/data/models/pet_model.dart';
import 'package:huellitas_a_casa/data/models/sighting_model.dart';
import 'package:huellitas_a_casa/domain/entities/pet.dart';
import 'package:rxdart/rxdart.dart';

class MapReport {
  const MapReport({
    required this.id,
    required this.type,
    required this.ownerUid,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.createdAt,
    required this.isReunited,
  });

  final String id;
  final String type;
  final String ownerUid;
  final String title;
  final String description;
  final String imageUrl;
  final GeoPoint location;
  final DateTime createdAt;
  final bool isReunited;

  String get reportKey => '${type}_$id';
}

class ReportsRepository {
  ReportsRepository(this._firestore, this._storage) : _geo = GeoFlutterFire();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final GeoFlutterFire _geo;

  Stream<List<MapReport>> nearbyReports({
    required GeoPoint centerPoint,
    required double radiusKm,
  }) {
    final center = _geo.point(
      latitude: centerPoint.latitude,
      longitude: centerPoint.longitude,
    );

    final lostStream = _geo
        .collection(collectionRef: _firestore.collection('lost_pets'))
        .within(
          center: center,
          radius: radiusKm,
          field: 'position',
          strictMode: true,
        )
        .map((docs) => docs
            .whereType<DocumentSnapshot<Map<String, dynamic>>>()
            .map(_mapLostDoc)
            .toList());

    final sightingsStream = _geo
        .collection(collectionRef: _firestore.collection('sightings'))
        .within(
          center: center,
          radius: radiusKm,
          field: 'position',
          strictMode: true,
        )
        .map((docs) => docs
            .whereType<DocumentSnapshot<Map<String, dynamic>>>()
            .map(_mapSightingDoc)
            .toList());

    return Rx.combineLatest2<List<MapReport>, List<MapReport>, List<MapReport>>(
      lostStream,
      sightingsStream,
      (lost, sightings) {
        final merged = <MapReport>[...lost, ...sightings];
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return merged;
      },
    );
  }

  Future<void> createLostPet({
    required String ownerUid,
    required String name,
    required String species,
    required String description,
    required DateTime lostAt,
    required GeoPoint location,
    required File imageFile,
  }) async {
    final imageUrl = await _uploadImage(
      ownerUid: ownerUid,
      imageFile: imageFile,
      folder: 'lost_pets',
    );
    final geoData = _geo.point(
      latitude: location.latitude,
      longitude: location.longitude,
    ).data;

    final model = PetModel(
      id: '',
      ownerId: ownerUid,
      name: name,
      species: species,
      description: description,
      imageUrl: imageUrl,
      lostAt: lostAt,
      location: location,
      createdAt: DateTime.now(),
      reunited: false,
    );
    await _firestore.collection('lost_pets').add(model.toFirestore(geoData: geoData));
  }

  Future<void> createSighting({
    required String reporterUid,
    required String species,
    required String description,
    required GeoPoint location,
    required File imageFile,
  }) async {
    final imageUrl = await _uploadImage(
      ownerUid: reporterUid,
      imageFile: imageFile,
      folder: 'sightings',
    );
    final geoData = _geo.point(
      latitude: location.latitude,
      longitude: location.longitude,
    ).data;

    final model = SightingModel(
      id: '',
      reporterId: reporterUid,
      species: species,
      description: description,
      imageUrl: imageUrl,
      location: location,
      createdAt: DateTime.now(),
    );
    final sightingRef = await _firestore
        .collection('sightings')
        .add(model.toFirestore(geoData: geoData));

    // Esta colección deja preparado el trigger para Cloud Functions + FCM.
    await _firestore.collection('notification_jobs').add(<String, dynamic>{
      'type': 'nearby_sighting',
      'sightingId': sightingRef.id,
      'radiusKm': 2,
      'title': '¡Avistamiento cerca!',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Pet>> myLostPets(String uid) {
    return _firestore
        .collection('lost_pets')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PetModel.fromFirestore).toList());
  }

  Future<void> markAsReunited(String petId) async {
    await _firestore.collection('lost_pets').doc(petId).update(<String, dynamic>{
      'reunited': true,
      'reunitedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _uploadImage({
    required String ownerUid,
    required File imageFile,
    required String folder,
  }) async {
    final path = 'users/$ownerUid/$folder/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref(path);
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }

  MapReport _mapLostDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final pet = PetModel.fromFirestore(doc);
    return MapReport(
      id: pet.id,
      type: 'lost',
      ownerUid: pet.ownerId,
      title: pet.name,
      description: pet.description,
      imageUrl: pet.imageUrl,
      location: pet.location,
      createdAt: pet.createdAt,
      isReunited: pet.reunited,
    );
  }

  MapReport _mapSightingDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final sighting = SightingModel.fromFirestore(doc);
    return MapReport(
      id: sighting.id,
      type: 'sighting',
      ownerUid: sighting.reporterId,
      title: 'Avistamiento ${sighting.species}',
      description: sighting.description,
      imageUrl: sighting.imageUrl,
      location: sighting.location,
      createdAt: sighting.createdAt,
      isReunited: false,
    );
  }
}
