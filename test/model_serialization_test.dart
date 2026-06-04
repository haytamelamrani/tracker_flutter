import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_flutter/domain/models/fuel_entry.dart';
import 'package:tracker_flutter/domain/models/maintenance.dart';
import 'package:tracker_flutter/domain/models/maintenance_category.dart';
import 'package:tracker_flutter/domain/models/vehicle.dart';

void main() {
  group('Domain models', () {
    test('Vehicle maps to and from Firestore data', () {
      const vehicle = Vehicle(
        id: 'vehicle-1',
        marque: 'Renault',
        modele: 'Clio',
        annee: 2022,
        immatriculation: 'ABC-123',
      );

      expect(Vehicle.fromMap(vehicle.toMap()), vehicle);
    });

    test('FuelEntry maps to and from Firestore data', () {
      final entry = FuelEntry(
        id: 'fuel-1',
        vehicleId: 'vehicle-1',
        date: DateTime.utc(2026, 6, 4),
        litres: 42.5,
        montant: 620,
        kilometrage: 12000,
      );

      expect(FuelEntry.fromMap(entry.toMap()), entry);
    });

    test('Maintenance maps to and from Firestore data', () {
      final maintenance = Maintenance(
        id: 'maintenance-1',
        vehicleId: 'vehicle-1',
        date: DateTime.utc(2026, 6, 4),
        categoryId: 'oil-change',
        description: 'Vidange moteur',
        cout: 450,
      );

      expect(Maintenance.fromMap(maintenance.toMap()), maintenance);
    });

    test('MaintenanceCategory maps to and from Firestore data', () {
      const category = MaintenanceCategory(id: 'oil-change', nom: 'Vidange');

      expect(MaintenanceCategory.fromMap(category.toMap()), category);
    });
  });
}
