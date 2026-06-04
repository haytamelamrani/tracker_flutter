import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../domain/models/fuel_entry.dart';
import '../../domain/models/maintenance.dart';
import '../../domain/models/maintenance_category.dart';
import '../../domain/models/vehicle.dart';

/// Service Firestore isolé par client.
///
/// Règle métier : « Chaque client a sa propre base de données. »
/// Toutes les opérations ciblent des sous-collections sous
/// `/users/{userId}/…` pour garantir l'isolation des données.
class FirestoreService {
  final FirebaseFirestore _db;

  /// Permet l'injection de dépendance pour les tests.
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  // -------------------------------------------------------------------------
  // Helpers — références de sous-collections scopées par userId
  // -------------------------------------------------------------------------

  /// Référence à la sous-collection des véhicules du client [userId].
  CollectionReference<Map<String, dynamic>> _vehiclesRef(String userId) =>
      _db.collection('users').doc(userId).collection(kVehiclesCollection);

  /// Référence à la sous-collection des entrées carburant du client [userId].
  CollectionReference<Map<String, dynamic>> _fuelEntriesRef(String userId) =>
      _db.collection('users').doc(userId).collection(kFuelEntriesCollection);

  /// Référence à la sous-collection des maintenances du client [userId].
  CollectionReference<Map<String, dynamic>> _maintenancesRef(String userId) =>
      _db.collection('users').doc(userId).collection(kMaintenancesCollection);

  /// Référence à la sous-collection des catégories de maintenance.
  CollectionReference<Map<String, dynamic>> _maintenanceCategoriesRef(
    String userId,
  ) => _db
      .collection('users')
      .doc(userId)
      .collection(kMaintenanceCategoriesCollection);

  // =========================================================================
  // VEHICLE — CRUD
  // =========================================================================

  /// Ajoute un véhicule. L'ID Firestore est généré automatiquement.
  Future<Vehicle> addVehicle(String userId, Vehicle vehicle) async {
    final docRef = _vehiclesRef(userId).doc();
    final created = Vehicle(
      id: docRef.id,
      marque: vehicle.marque,
      modele: vehicle.modele,
      annee: vehicle.annee,
      immatriculation: vehicle.immatriculation,
    );
    await docRef.set(created.toMap());
    return created;
  }

  /// Récupère un véhicule par son [vehicleId].
  Future<Vehicle?> getVehicle(String userId, String vehicleId) async {
    final doc = await _vehiclesRef(userId).doc(vehicleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _vehicleFromDocument(doc);
  }

  /// Retourne la liste de tous les véhicules du client.
  Future<List<Vehicle>> getVehicles(String userId) async {
    final snapshot = await _vehiclesRef(userId).get();
    return snapshot.docs.map(_vehicleFromDocument).toList();
  }

  /// Stream réactif de tous les véhicules du client.
  Stream<List<Vehicle>> watchVehicles(String userId) {
    return _vehiclesRef(
      userId,
    ).snapshots().map((snap) => snap.docs.map(_vehicleFromDocument).toList());
  }

  /// Met à jour un véhicule existant.
  Future<void> updateVehicle(String userId, Vehicle vehicle) async {
    await _vehiclesRef(userId).doc(vehicle.id).update(vehicle.toMap());
  }

  /// Supprime un véhicule par son [vehicleId].
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    await _vehiclesRef(userId).doc(vehicleId).delete();
  }

  // =========================================================================
  // FUEL ENTRY — CRUD
  // =========================================================================

  /// Ajoute une entrée carburant. L'ID Firestore est généré automatiquement.
  Future<FuelEntry> addFuelEntry(String userId, FuelEntry entry) async {
    final docRef = _fuelEntriesRef(userId).doc();
    final created = FuelEntry(
      id: docRef.id,
      vehicleId: entry.vehicleId,
      date: entry.date,
      litres: entry.litres,
      montant: entry.montant,
      kilometrage: entry.kilometrage,
    );
    await docRef.set(
      _firestoreData(created.toMap(), dateFields: [kFuelEntryFieldDate]),
    );
    return created;
  }

  /// Récupère une entrée carburant par son [entryId].
  Future<FuelEntry?> getFuelEntry(String userId, String entryId) async {
    final doc = await _fuelEntriesRef(userId).doc(entryId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fuelEntryFromDocument(doc);
  }

  /// Retourne toutes les entrées carburant du client.
  Future<List<FuelEntry>> getFuelEntries(String userId) async {
    final snapshot = await _fuelEntriesRef(userId).get();
    return snapshot.docs.map(_fuelEntryFromDocument).toList();
  }

  /// Retourne les entrées carburant d'un véhicule spécifique.
  Future<List<FuelEntry>> getFuelEntriesByVehicle(
    String userId,
    String vehicleId,
  ) async {
    final snapshot = await _fuelEntriesRef(userId)
        .where(kFuelEntryFieldVehicleId, isEqualTo: vehicleId)
        .orderBy(kFuelEntryFieldDate, descending: true)
        .get();
    return snapshot.docs.map(_fuelEntryFromDocument).toList();
  }

  /// Stream réactif des entrées carburant d'un véhicule.
  Stream<List<FuelEntry>> watchFuelEntriesByVehicle(
    String userId,
    String vehicleId,
  ) {
    return _fuelEntriesRef(userId)
        .where(kFuelEntryFieldVehicleId, isEqualTo: vehicleId)
        .orderBy(kFuelEntryFieldDate, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fuelEntryFromDocument).toList());
  }

  /// Met à jour une entrée carburant existante.
  Future<void> updateFuelEntry(String userId, FuelEntry entry) async {
    await _fuelEntriesRef(userId)
        .doc(entry.id)
        .update(
          _firestoreData(entry.toMap(), dateFields: [kFuelEntryFieldDate]),
        );
  }

  /// Supprime une entrée carburant par son [entryId].
  Future<void> deleteFuelEntry(String userId, String entryId) async {
    await _fuelEntriesRef(userId).doc(entryId).delete();
  }

  // =========================================================================
  // MAINTENANCE — CRUD
  // =========================================================================

  /// Ajoute une maintenance. L'ID Firestore est généré automatiquement.
  Future<Maintenance> addMaintenance(
    String userId,
    Maintenance maintenance,
  ) async {
    final docRef = _maintenancesRef(userId).doc();
    final created = Maintenance(
      id: docRef.id,
      vehicleId: maintenance.vehicleId,
      date: maintenance.date,
      categoryId: maintenance.categoryId,
      description: maintenance.description,
      cout: maintenance.cout,
    );
    await docRef.set(
      _firestoreData(created.toMap(), dateFields: [kMaintenanceFieldDate]),
    );
    return created;
  }

  /// Récupère une maintenance par son [maintenanceId].
  Future<Maintenance?> getMaintenance(
    String userId,
    String maintenanceId,
  ) async {
    final doc = await _maintenancesRef(userId).doc(maintenanceId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _maintenanceFromDocument(doc);
  }

  /// Retourne toutes les maintenances du client.
  Future<List<Maintenance>> getMaintenances(String userId) async {
    final snapshot = await _maintenancesRef(userId).get();
    return snapshot.docs.map(_maintenanceFromDocument).toList();
  }

  /// Retourne les maintenances d'un véhicule spécifique.
  Future<List<Maintenance>> getMaintenancesByVehicle(
    String userId,
    String vehicleId,
  ) async {
    final snapshot = await _maintenancesRef(userId)
        .where(kMaintenanceFieldVehicleId, isEqualTo: vehicleId)
        .orderBy(kMaintenanceFieldDate, descending: true)
        .get();
    return snapshot.docs.map(_maintenanceFromDocument).toList();
  }

  /// Stream réactif des maintenances d'un véhicule.
  Stream<List<Maintenance>> watchMaintenancesByVehicle(
    String userId,
    String vehicleId,
  ) {
    return _maintenancesRef(userId)
        .where(kMaintenanceFieldVehicleId, isEqualTo: vehicleId)
        .orderBy(kMaintenanceFieldDate, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_maintenanceFromDocument).toList());
  }

  /// Met à jour une maintenance existante.
  Future<void> updateMaintenance(String userId, Maintenance maintenance) async {
    await _maintenancesRef(userId)
        .doc(maintenance.id)
        .update(
          _firestoreData(
            maintenance.toMap(),
            dateFields: [kMaintenanceFieldDate],
          ),
        );
  }

  /// Supprime une maintenance par son [maintenanceId].
  Future<void> deleteMaintenance(String userId, String maintenanceId) async {
    await _maintenancesRef(userId).doc(maintenanceId).delete();
  }

  // =========================================================================
  // MAINTENANCE CATEGORY — CRUD
  // =========================================================================

  /// Ajoute une catégorie de maintenance.
  Future<MaintenanceCategory> addMaintenanceCategory(
    String userId,
    MaintenanceCategory category,
  ) async {
    final docRef = _maintenanceCategoriesRef(userId).doc();
    final created = MaintenanceCategory(id: docRef.id, nom: category.nom);
    await docRef.set(created.toMap());
    return created;
  }

  /// Retourne toutes les catégories de maintenance du client.
  Future<List<MaintenanceCategory>> getMaintenanceCategories(
    String userId,
  ) async {
    final snapshot = await _maintenanceCategoriesRef(userId).get();
    return snapshot.docs.map(_maintenanceCategoryFromDocument).toList();
  }

  /// Stream réactif des catégories de maintenance.
  Stream<List<MaintenanceCategory>> watchMaintenanceCategories(String userId) {
    return _maintenanceCategoriesRef(userId).snapshots().map(
      (snap) => snap.docs.map(_maintenanceCategoryFromDocument).toList(),
    );
  }

  /// Met à jour une catégorie de maintenance existante.
  Future<void> updateMaintenanceCategory(
    String userId,
    MaintenanceCategory category,
  ) async {
    await _maintenanceCategoriesRef(
      userId,
    ).doc(category.id).update(category.toMap());
  }

  /// Supprime une catégorie de maintenance par son [categoryId].
  Future<void> deleteMaintenanceCategory(
    String userId,
    String categoryId,
  ) async {
    await _maintenanceCategoriesRef(userId).doc(categoryId).delete();
  }

  Vehicle _vehicleFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Vehicle.fromMap(_documentData(doc, kVehicleFieldId));
  }

  FuelEntry _fuelEntryFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return FuelEntry.fromMap(_documentData(doc, kFuelEntryFieldId));
  }

  Maintenance _maintenanceFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Maintenance.fromMap(_documentData(doc, kMaintenanceFieldId));
  }

  MaintenanceCategory _maintenanceCategoryFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MaintenanceCategory.fromMap(
      _documentData(doc, kMaintenanceCategoryFieldId),
    );
  }

  Map<String, dynamic> _documentData(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String idField,
  ) {
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    data.putIfAbsent(idField, () => doc.id);
    return data.map(
      (key, value) => MapEntry(key, _normalizeFirestoreValue(value)),
    );
  }

  Object? _normalizeFirestoreValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    return value;
  }

  Map<String, dynamic> _firestoreData(
    Map<String, dynamic> data, {
    List<String> dateFields = const [],
  }) {
    final normalized = Map<String, dynamic>.from(data);
    for (final field in dateFields) {
      final value = normalized[field];
      if (value is DateTime) {
        normalized[field] = Timestamp.fromDate(value);
      } else if (value is String) {
        final parsedDate = DateTime.tryParse(value);
        if (parsedDate != null) {
          normalized[field] = Timestamp.fromDate(parsedDate);
        }
      }
    }
    return normalized;
  }
}
