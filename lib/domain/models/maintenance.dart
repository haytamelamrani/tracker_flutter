import '../../core/constants.dart';

/// Représente une opération de maintenance effectuée sur un véhicule.
class Maintenance {
  /// Identifiant unique (document Firestore).
  final String id;

  /// Identifiant du véhicule associé.
  final String vehicleId;

  /// Date de la maintenance.
  final DateTime date;

  /// Identifiant de la catégorie de maintenance.
  final String categoryId;

  /// Description libre de l'opération.
  final String description;

  /// Coût de la maintenance en devise locale.
  final double cout;

  const Maintenance({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.categoryId,
    required this.description,
    required this.cout,
  });

  /// Convertit l'instance en [Map] pour Firestore.
  Map<String, dynamic> toMap() {
    return {
      kMaintenanceFieldId: id,
      kMaintenanceFieldVehicleId: vehicleId,
      kMaintenanceFieldDate: date.toIso8601String(),
      kMaintenanceFieldCategoryId: categoryId,
      kMaintenanceFieldDescription: description,
      kMaintenanceFieldCout: cout,
    };
  }

  /// Crée une instance de [Maintenance] à partir d'une [Map] Firestore.
  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map[kMaintenanceFieldId]?.toString() ?? '',
      vehicleId: map[kMaintenanceFieldVehicleId]?.toString() ?? '',
      date: DateTime.tryParse(map[kMaintenanceFieldDate]?.toString() ?? '') ?? DateTime.now(),
      categoryId: map[kMaintenanceFieldCategoryId]?.toString() ?? '',
      description: map[kMaintenanceFieldDescription]?.toString() ?? '',
      cout: (map[kMaintenanceFieldCout] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'Maintenance(id: $id, vehicleId: $vehicleId, date: $date, '
        'categoryId: $categoryId, description: $description, cout: $cout)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Maintenance &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.date == date &&
        other.categoryId == categoryId &&
        other.description == description &&
        other.cout == cout;
  }

  @override
  int get hashCode {
    return Object.hash(id, vehicleId, date, categoryId, description, cout);
  }
}
