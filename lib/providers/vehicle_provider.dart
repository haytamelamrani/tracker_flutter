import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/vehicle.dart';
import 'auth_provider.dart';

// =============================================================================
// Vehicles Provider — Liste des véhicules du client connecté
// =============================================================================

/// Provider asynchrone qui récupère la liste des véhicules de l'utilisateur.
///
/// Dépend de [currentUserIdProvider] : si l'utilisateur n'est pas connecté,
/// retourne une liste vide. Gère automatiquement les états
/// loading / error / data via [AsyncValue].
final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getVehicles(userId);
});

/// Provider stream pour écouter les changements en temps réel.
final vehiclesStreamProvider = StreamProvider<List<Vehicle>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchVehicles(userId);
});

/// Provider family pour récupérer un véhicule par son ID.
final vehicleByIdProvider =
    FutureProvider.family<Vehicle?, String>((ref, vehicleId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getVehicle(userId, vehicleId);
});
