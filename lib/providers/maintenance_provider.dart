import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/maintenance.dart';
import 'auth_provider.dart';

// =============================================================================
// Paramètre de filtre pour les maintenances
// =============================================================================

/// Paramètres de requête pour l'historique de maintenance d'un véhicule.
///
/// [vehicleId] est obligatoire. [startDate] et [endDate] permettent
/// de filtrer par plage de dates côté client.
class MaintenanceFilter {
  final String vehicleId;
  final DateTime? startDate;
  final DateTime? endDate;

  const MaintenanceFilter({
    required this.vehicleId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaintenanceFilter &&
        other.vehicleId == vehicleId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(vehicleId, startDate, endDate);
}

// =============================================================================
// Maintenances Provider — Historique par véhicule avec filtre par date
// =============================================================================

/// Provider asynchrone qui récupère les maintenances d'un véhicule
/// et applique un filtre par plage de dates.
///
/// Utilise [FutureProvider.family] pour paramétrer la requête.
/// Les états loading / error / data sont gérés automatiquement par Riverpod.
final maintenancesByVehicleProvider =
    FutureProvider.family<List<Maintenance>, MaintenanceFilter>((
      ref,
      filter,
    ) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];

      final firestoreService = ref.watch(firestoreServiceProvider);
      final allMaintenances = await firestoreService.getMaintenancesByVehicle(
        userId,
        filter.vehicleId,
      );

      // Filtrage côté client par plage de dates.
      return allMaintenances.where((m) {
        if (filter.startDate != null && m.date.isBefore(filter.startDate!)) {
          return false;
        }
        if (filter.endDate != null && m.date.isAfter(filter.endDate!)) {
          return false;
        }
        return true;
      }).toList();
    });

/// Stream réactif des maintenances d'un véhicule (temps réel, sans filtre).
final maintenancesStreamByVehicleProvider =
    StreamProvider.family<List<Maintenance>, String>((ref, vehicleId) {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return Stream.value([]);

      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.watchMaintenancesByVehicle(userId, vehicleId);
    });

/// Provider asynchrone pour toutes les maintenances du client (tous véhicules).
final allMaintenancesProvider = FutureProvider<List<Maintenance>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMaintenances(userId);
});
