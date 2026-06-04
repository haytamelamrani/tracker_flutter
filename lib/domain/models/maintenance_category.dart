import '../../core/constants.dart';

/// Représente une catégorie de maintenance (ex : Vidange, Freins, Pneus).
class MaintenanceCategory {
  /// Identifiant unique (document Firestore).
  final String id;

  /// Nom de la catégorie.
  final String nom;

  const MaintenanceCategory({
    required this.id,
    required this.nom,
  });

  /// Convertit l'instance en [Map] pour Firestore.
  Map<String, dynamic> toMap() {
    return {
      kMaintenanceCategoryFieldId: id,
      kMaintenanceCategoryFieldNom: nom,
    };
  }

  /// Crée une instance de [MaintenanceCategory] à partir d'une [Map] Firestore.
  factory MaintenanceCategory.fromMap(Map<String, dynamic> map) {
    return MaintenanceCategory(
      id: map[kMaintenanceCategoryFieldId] as String,
      nom: map[kMaintenanceCategoryFieldNom] as String,
    );
  }

  @override
  String toString() => 'MaintenanceCategory(id: $id, nom: $nom)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaintenanceCategory &&
        other.id == id &&
        other.nom == nom;
  }

  @override
  int get hashCode => Object.hash(id, nom);
}
