/// Constantes de base de l'application Tracker Flutter.
///
/// Contient les noms de collections Firestore et les clés de champs
/// utilisées dans l'ensemble de l'application.
library;

// ---------------------------------------------------------------------------
// Collections Firestore
// ---------------------------------------------------------------------------

/// Collection des véhicules.
const String kVehiclesCollection = 'vehicles';

/// Collection des entrées de carburant.
const String kFuelEntriesCollection = 'fuel_entries';

/// Collection des maintenances.
const String kMaintenancesCollection = 'maintenances';

/// Collection des catégories de maintenance.
const String kMaintenanceCategoriesCollection = 'maintenance_categories';

// ---------------------------------------------------------------------------
// Clés Firestore — Vehicle
// ---------------------------------------------------------------------------

const String kVehicleFieldId = 'id';
const String kVehicleFieldMarque = 'marque';
const String kVehicleFieldModele = 'modele';
const String kVehicleFieldAnnee = 'annee';
const String kVehicleFieldImmatriculation = 'immatriculation';

// ---------------------------------------------------------------------------
// Clés Firestore — FuelEntry
// ---------------------------------------------------------------------------

const String kFuelEntryFieldId = 'id';
const String kFuelEntryFieldVehicleId = 'vehicleId';
const String kFuelEntryFieldDate = 'date';
const String kFuelEntryFieldLitres = 'litres';
const String kFuelEntryFieldMontant = 'montant';
const String kFuelEntryFieldKilometrage = 'kilometrage';

// ---------------------------------------------------------------------------
// Clés Firestore — Maintenance
// ---------------------------------------------------------------------------

const String kMaintenanceFieldId = 'id';
const String kMaintenanceFieldVehicleId = 'vehicleId';
const String kMaintenanceFieldDate = 'date';
const String kMaintenanceFieldCategoryId = 'categoryId';
const String kMaintenanceFieldDescription = 'description';
const String kMaintenanceFieldCout = 'cout';

// ---------------------------------------------------------------------------
// Clés Firestore — MaintenanceCategory
// ---------------------------------------------------------------------------

const String kMaintenanceCategoryFieldId = 'id';
const String kMaintenanceCategoryFieldNom = 'nom';
