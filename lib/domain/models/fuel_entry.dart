import '../../core/constants.dart';

/// Représente une entrée de carburant (plein de gasoil) pour un véhicule.
class FuelEntry {
  /// Identifiant unique (document Firestore).
  final String id;

  /// Identifiant du véhicule associé.
  final String vehicleId;

  /// Date du plein.
  final DateTime date;

  /// Quantité de carburant en litres.
  final double litres;

  /// Montant payé en devise locale.
  final double montant;

  /// Kilométrage au moment du plein.
  final double kilometrage;

  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.litres,
    required this.montant,
    required this.kilometrage,
  });

  /// Convertit l'instance en [Map] pour Firestore.
  Map<String, dynamic> toMap() {
    return {
      kFuelEntryFieldId: id,
      kFuelEntryFieldVehicleId: vehicleId,
      kFuelEntryFieldDate: date.toIso8601String(),
      kFuelEntryFieldLitres: litres,
      kFuelEntryFieldMontant: montant,
      kFuelEntryFieldKilometrage: kilometrage,
    };
  }

  /// Crée une instance de [FuelEntry] à partir d'une [Map] Firestore.
  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map[kFuelEntryFieldId]?.toString() ?? '',
      vehicleId: map[kFuelEntryFieldVehicleId]?.toString() ?? '',
      date:
          DateTime.tryParse(map[kFuelEntryFieldDate]?.toString() ?? '') ??
          DateTime.now(),
      litres: (map[kFuelEntryFieldLitres] as num?)?.toDouble() ?? 0.0,
      montant: (map[kFuelEntryFieldMontant] as num?)?.toDouble() ?? 0.0,
      kilometrage: (map[kFuelEntryFieldKilometrage] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'FuelEntry(id: $id, vehicleId: $vehicleId, date: $date, '
        'litres: $litres, montant: $montant, kilometrage: $kilometrage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FuelEntry &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.date == date &&
        other.litres == litres &&
        other.montant == montant &&
        other.kilometrage == kilometrage;
  }

  @override
  int get hashCode {
    return Object.hash(id, vehicleId, date, litres, montant, kilometrage);
  }
}
