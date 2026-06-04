import '../../core/constants.dart';

/// Représente un véhicule dans le système de suivi.
class Vehicle {
  /// Identifiant unique (document Firestore).
  final String id;

  /// Marque du véhicule (ex : Renault, Toyota).
  final String marque;

  /// Modèle du véhicule (ex : Clio, Corolla).
  final String modele;

  /// Année de mise en circulation.
  final int annee;

  /// Numéro d'immatriculation.
  final String immatriculation;

  const Vehicle({
    required this.id,
    required this.marque,
    required this.modele,
    required this.annee,
    required this.immatriculation,
  });

  /// Convertit l'instance en [Map] pour Firestore.
  Map<String, dynamic> toMap() {
    return {
      kVehicleFieldId: id,
      kVehicleFieldMarque: marque,
      kVehicleFieldModele: modele,
      kVehicleFieldAnnee: annee,
      kVehicleFieldImmatriculation: immatriculation,
    };
  }

  /// Crée une instance de [Vehicle] à partir d'une [Map] Firestore.
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map[kVehicleFieldId]?.toString() ?? '',
      marque: map[kVehicleFieldMarque]?.toString() ?? 'Inconnu',
      modele: map[kVehicleFieldModele]?.toString() ?? 'Inconnu',
      annee: (map[kVehicleFieldAnnee] as num?)?.toInt() ?? 0,
      immatriculation: map[kVehicleFieldImmatriculation]?.toString() ?? 'N/A',
    );
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, marque: $marque, modele: $modele, '
        'annee: $annee, immatriculation: $immatriculation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle &&
        other.id == id &&
        other.marque == marque &&
        other.modele == modele &&
        other.annee == annee &&
        other.immatriculation == immatriculation;
  }

  @override
  int get hashCode {
    return Object.hash(id, marque, modele, annee, immatriculation);
  }
}
