import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huellitas_a_casa/data/repositories/account_repository.dart';
import 'package:huellitas_a_casa/data/repositories/auth_repository.dart';
import 'package:huellitas_a_casa/data/repositories/moderation_repository.dart';
import 'package:huellitas_a_casa/data/repositories/reports_repository.dart';
import 'package:huellitas_a_casa/data/services/location_service.dart';
import 'package:huellitas_a_casa/domain/entities/pet.dart';
import 'package:rxdart/rxdart.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final storageProvider = Provider<FirebaseStorage>((_) => FirebaseStorage.instance);
final messagingProvider = Provider<FirebaseMessaging>((_) => FirebaseMessaging.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
    ref.read(messagingProvider),
  );
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(
    ref.read(firestoreProvider),
    ref.read(storageProvider),
  );
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(ref.read(firestoreProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
    ref.read(storageProvider),
  );
});

final locationServiceProvider = Provider<LocationService>((_) => LocationService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.signIn(email: email, password: password),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String alias,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.signUp(email: email, password: password, alias: alias),
    );
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}

final centerPointProvider =
    NotifierProvider<CenterPointNotifier, GeoPoint?>(CenterPointNotifier.new);
final mapRadiusKmProvider =
    NotifierProvider<MapRadiusNotifier, double>(MapRadiusNotifier.new);

class CenterPointNotifier extends Notifier<GeoPoint?> {
  @override
  GeoPoint? build() => null;

  set value(GeoPoint? point) => state = point;
}

class MapRadiusNotifier extends Notifier<double> {
  @override
  double build() => 2;
}

final nearbyReportsProvider = StreamProvider.autoDispose<List<MapReport>>((ref) {
  final center = ref.watch(centerPointProvider);
  if (center == null) {
    return const Stream<List<MapReport>>.empty();
  }
  final radius = ref.watch(mapRadiusKmProvider);
  final uid = ref.read(firebaseAuthProvider).currentUser?.uid;

  final repo = ref.read(reportsRepositoryProvider);
  final moderation = ref.read(moderationRepositoryProvider);
  final source = repo.nearbyReports(centerPoint: center, radiusKm: radius);
  if (uid == null) {
    return source;
  }

  return Rx.combineLatest3<List<MapReport>, Set<String>, Set<String>, List<MapReport>>(
    source,
    moderation.hiddenPostIds(uid),
    moderation.blockedUserIds(uid),
    (reports, hiddenPosts, blockedUsers) {
      return reports
          .where((r) => !hiddenPosts.contains(r.reportKey))
          .where((r) => !blockedUsers.contains(r.ownerUid))
          .toList();
    },
  );
});

final myPetsProvider = StreamProvider.autoDispose<List<Pet>>((ref) {
  final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) {
    return const Stream<List<Pet>>.empty();
  }
  return ref.read(reportsRepositoryProvider).myLostPets(uid);
});

final reportControllerProvider = AsyncNotifierProvider<ReportController, void>(
  ReportController.new,
);

class ReportController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createLostPet({
    required String name,
    required String species,
    required String description,
    required DateTime lostAt,
    required GeoPoint location,
    required File imageFile,
  }) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) {
      state = AsyncError('Debes iniciar sesión.', StackTrace.current);
      return;
    }
    final repo = ref.read(reportsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repo.createLostPet(
        ownerUid: uid,
        name: name,
        species: species,
        description: description,
        lostAt: lostAt,
        location: location,
        imageFile: imageFile,
      ),
    );
  }

  Future<void> createSighting({
    required String species,
    required String description,
    required GeoPoint location,
    required File imageFile,
  }) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) {
      state = AsyncError('Debes iniciar sesión.', StackTrace.current);
      return;
    }
    final repo = ref.read(reportsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repo.createSighting(
        reporterUid: uid,
        species: species,
        description: description,
        location: location,
        imageFile: imageFile,
      ),
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> deleteAccountAndData() async {
    final accountRepo = ref.read(accountRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(accountRepo.deleteAccountAndData);
  }

  Future<void> markReunited(String petId) async {
    final reportsRepo = ref.read(reportsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => reportsRepo.markAsReunited(petId));
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
