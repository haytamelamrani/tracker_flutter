import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/fuel_entry.dart';
import '../domain/models/maintenance.dart';
import 'auth_provider.dart';

// =============================================================================
// Constantes métier — Répartition budgétaire théorique
// =============================================================================

/// Part théorique du budget allouée au gasoil (70 %).
const double kBudgetRatioFuel = 0.70;

/// Part théorique du budget allouée à la maintenance (30 %).
const double kBudgetRatioMaintenance = 0.30;

// =============================================================================
// Modèles de données pour les dépenses
// =============================================================================

/// Dépenses mensuelles pour un véhicule donné.
class MonthlyExpense {
  /// Clé du mois au format « YYYY-MM ».
  final String month;

  /// Total des dépenses de gasoil sur le mois.
  final double totalFuel;

  /// Total des dépenses de maintenance sur le mois.
  final double totalMaintenance;

  /// Total combiné (gasoil + maintenance).
  double get total => totalFuel + totalMaintenance;

  const MonthlyExpense({
    required this.month,
    required this.totalFuel,
    required this.totalMaintenance,
  });

  @override
  String toString() =>
      'MonthlyExpense(month: $month, fuel: $totalFuel, '
      'maintenance: $totalMaintenance, total: $total)';
}

/// Répartition budgétaire globale du client.
class BudgetBreakdown {
  /// Total réel des dépenses de gasoil.
  final double actualFuel;

  /// Total réel des dépenses de maintenance.
  final double actualMaintenance;

  /// Total réel combiné.
  double get actualTotal => actualFuel + actualMaintenance;

  /// Montant théorique de gasoil selon la règle 70/30.
  double get theoreticalFuel => actualTotal * kBudgetRatioFuel;

  /// Montant théorique de maintenance selon la règle 70/30.
  double get theoreticalMaintenance => actualTotal * kBudgetRatioMaintenance;

  /// Écart gasoil : positif = sous-budget, négatif = dépassement.
  double get fuelVariance => theoreticalFuel - actualFuel;

  /// Écart maintenance : positif = sous-budget, négatif = dépassement.
  double get maintenanceVariance => theoreticalMaintenance - actualMaintenance;

  /// Ratio réel du gasoil (0.0 – 1.0). Retourne 0 si aucun total.
  double get actualFuelRatio =>
      actualTotal > 0 ? actualFuel / actualTotal : 0.0;

  /// Ratio réel de la maintenance (0.0 – 1.0). Retourne 0 si aucun total.
  double get actualMaintenanceRatio =>
      actualTotal > 0 ? actualMaintenance / actualTotal : 0.0;

  const BudgetBreakdown({
    required this.actualFuel,
    required this.actualMaintenance,
  });

  @override
  String toString() =>
      'BudgetBreakdown(fuel: $actualFuel [${(actualFuelRatio * 100).toStringAsFixed(1)}%], '
      'maintenance: $actualMaintenance [${(actualMaintenanceRatio * 100).toStringAsFixed(1)}%], '
      'total: $actualTotal)';
}

// =============================================================================
// Providers de données brutes
// =============================================================================

/// Toutes les entrées carburant du client.
final allFuelEntriesProvider = FutureProvider<List<FuelEntry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFuelEntries(userId);
});

/// Entrées carburant d'un véhicule spécifique.
final fuelEntriesByVehicleProvider =
    FutureProvider.family<List<FuelEntry>, String>((ref, vehicleId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFuelEntriesByVehicle(userId, vehicleId);
});

// =============================================================================
// Dépenses mensuelles par véhicule
// =============================================================================

/// Calcule les dépenses mensuelles pour un véhicule donné.
///
/// Agrège les montants de gasoil et de maintenance par mois (clé « YYYY-MM »),
/// triés du plus récent au plus ancien.
final monthlyExpensesByVehicleProvider =
    FutureProvider.family<List<MonthlyExpense>, String>(
  (ref, vehicleId) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];

    final firestoreService = ref.watch(firestoreServiceProvider);

    // Chargement parallèle des données.
    final results = await Future.wait([
      firestoreService.getFuelEntriesByVehicle(userId, vehicleId),
      firestoreService.getMaintenancesByVehicle(userId, vehicleId),
    ]);

    final fuelEntries = results[0] as List<FuelEntry>;
    final maintenances = results[1] as List<Maintenance>;

    // Agrégation par mois.
    final Map<String, _MutableExpense> monthMap = {};

    for (final entry in fuelEntries) {
      final key = _monthKey(entry.date);
      monthMap.putIfAbsent(key, _MutableExpense.new);
      monthMap[key]!.fuel += entry.montant;
    }

    for (final m in maintenances) {
      final key = _monthKey(m.date);
      monthMap.putIfAbsent(key, _MutableExpense.new);
      monthMap[key]!.maintenance += m.cout;
    }

    // Conversion et tri décroissant.
    final expenses = monthMap.entries
        .map(
          (e) => MonthlyExpense(
            month: e.key,
            totalFuel: e.value.fuel,
            totalMaintenance: e.value.maintenance,
          ),
        )
        .toList()
      ..sort((a, b) => b.month.compareTo(a.month));

    return expenses;
  },
);

// =============================================================================
// Répartition budgétaire globale
// =============================================================================

/// Calcule la répartition budgétaire globale (tous véhicules confondus).
///
/// Compare les dépenses réelles à la répartition théorique 70% gasoil / 30%
/// maintenance définie par la règle métier.
final budgetBreakdownProvider = FutureProvider<BudgetBreakdown>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const BudgetBreakdown(actualFuel: 0, actualMaintenance: 0);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  // Chargement parallèle.
  final results = await Future.wait([
    firestoreService.getFuelEntries(userId),
    firestoreService.getMaintenances(userId),
  ]);

  final fuelEntries = results[0] as List<FuelEntry>;
  final maintenances = results[1] as List<Maintenance>;

  final totalFuel = fuelEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.montant,
  );

  final totalMaintenance = maintenances.fold<double>(
    0,
    (sum, m) => sum + m.cout,
  );

  return BudgetBreakdown(
    actualFuel: totalFuel,
    actualMaintenance: totalMaintenance,
  );
});

/// Répartition budgétaire pour un véhicule spécifique.
final budgetBreakdownByVehicleProvider =
    FutureProvider.family<BudgetBreakdown, String>((ref, vehicleId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const BudgetBreakdown(actualFuel: 0, actualMaintenance: 0);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  final results = await Future.wait([
    firestoreService.getFuelEntriesByVehicle(userId, vehicleId),
    firestoreService.getMaintenancesByVehicle(userId, vehicleId),
  ]);

  final fuelEntries = results[0] as List<FuelEntry>;
  final maintenances = results[1] as List<Maintenance>;

  final totalFuel = fuelEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.montant,
  );

  final totalMaintenance = maintenances.fold<double>(
    0,
    (sum, m) => sum + m.cout,
  );

  return BudgetBreakdown(
    actualFuel: totalFuel,
    actualMaintenance: totalMaintenance,
  );
});

// =============================================================================
// Helpers privés
// =============================================================================

/// Génère une clé « YYYY-MM » à partir d'une [DateTime].
String _monthKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}

/// Accumulateur mutable utilisé lors de l'agrégation par mois.
class _MutableExpense {
  double fuel = 0;
  double maintenance = 0;
}
