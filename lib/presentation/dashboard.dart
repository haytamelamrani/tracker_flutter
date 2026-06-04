import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/vehicle_provider.dart';
import 'widgets/add_dialogs.dart';

// =============================================================================
// Palette locale
// =============================================================================

const Color _kNavy = Color(0xFF0F1B2D);
const Color _kAccentBlue = Color(0xFF3B82F6);
const Color _kAccentCyan = Color(0xFF06B6D4);
const Color _kGreen = Color(0xFF10B981);
const Color _kOrange = Color(0xFFF59E0B);
const Color _kRed = Color(0xFFEF4444);
const Color _kSurface = Color(0xFFF8FAFC);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);

/// Dashboard premium — vue d'ensemble de la flotte.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final budgetAsync = ref.watch(budgetBreakdownProvider);

    final String userName;
    if (authState is AuthAuthenticated) {
      userName = authState.user.email ?? 'Utilisateur';
    } else {
      userName = 'Utilisateur';
    }

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text('Tracker Fleet'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  tooltip: 'Déconnexion',
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vehiclesProvider);
          ref.invalidate(budgetBreakdownProvider);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Tableau de bord',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vue d\'ensemble de votre flotte et de vos dépenses',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  // ─── Budget Breakdown ───────────────────────────────
                  budgetAsync.when(
                    loading: () => const _ShimmerCard(height: 200),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (budget) => _BudgetSection(budget: budget),
                  ),

                  const SizedBox(height: 28),

                  // ─── Vehicles ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mes véhicules',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => showAddVehicleDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  vehiclesAsync.when(
                    loading: () => const _ShimmerCard(height: 160),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (vehicles) {
                      if (vehicles.isEmpty) {
                        return const _EmptyState(
                          icon: Icons.directions_car_outlined,
                          title: 'Aucun véhicule',
                          subtitle:
                              'Ajoutez votre premier véhicule pour commencer le suivi.',
                        );
                      }

                      if (isWide) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: vehicles
                              .map(
                                (v) => SizedBox(
                                  width: (constraints.maxWidth - 96 - 32) / 3,
                                  child: _VehicleCard(vehicle: v),
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Column(
                        children: vehicles
                            .map(
                              (v) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _VehicleCard(vehicle: v),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// Budget Section — Répartition 70/30
// =============================================================================

class _BudgetSection extends StatelessWidget {
  final BudgetBreakdown budget;
  const _BudgetSection({required this.budget});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI cards row
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.local_gas_station_rounded,
                  iconColor: _kAccentBlue,
                  label: 'Gasoil total',
                  value: '${budget.actualFuel.toStringAsFixed(2)} MAD',
                  subtitle:
                      '${(budget.actualFuelRatio * 100).toStringAsFixed(1)}% du budget',
                  accentColor: _kAccentBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  icon: Icons.build_rounded,
                  iconColor: _kOrange,
                  label: 'Maintenance totale',
                  value: '${budget.actualMaintenance.toStringAsFixed(2)} MAD',
                  subtitle:
                      '${(budget.actualMaintenanceRatio * 100).toStringAsFixed(1)}% du budget',
                  accentColor: _kOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: _kGreen,
                  label: 'Dépenses totales',
                  value: '${budget.actualTotal.toStringAsFixed(2)} MAD',
                  subtitle: 'Tous véhicules confondus',
                  accentColor: _kGreen,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _KpiCard(
                icon: Icons.local_gas_station_rounded,
                iconColor: _kAccentBlue,
                label: 'Gasoil total',
                value: '${budget.actualFuel.toStringAsFixed(2)} MAD',
                subtitle:
                    '${(budget.actualFuelRatio * 100).toStringAsFixed(1)}% du budget',
                accentColor: _kAccentBlue,
              ),
              const SizedBox(height: 14),
              _KpiCard(
                icon: Icons.build_rounded,
                iconColor: _kOrange,
                label: 'Maintenance totale',
                value: '${budget.actualMaintenance.toStringAsFixed(2)} MAD',
                subtitle:
                    '${(budget.actualMaintenanceRatio * 100).toStringAsFixed(1)}% du budget',
                accentColor: _kOrange,
              ),
              const SizedBox(height: 14),
              _KpiCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: _kGreen,
                label: 'Dépenses totales',
                value: '${budget.actualTotal.toStringAsFixed(2)} MAD',
                subtitle: 'Tous véhicules confondus',
                accentColor: _kGreen,
              ),
            ],
          ),

        const SizedBox(height: 20),

        // Budget bar
        _BudgetBarCard(budget: budget),
      ],
    );
  }
}

// =============================================================================
// KPI Card
// =============================================================================

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Budget Bar Card — Visualisation de la répartition
// =============================================================================

class _BudgetBarCard extends StatelessWidget {
  final BudgetBreakdown budget;
  const _BudgetBarCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final fuelPct = budget.actualFuelRatio;
    final maintPct = budget.actualMaintenanceRatio;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Répartition budgétaire',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Objectif : 70% / 30%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  Expanded(
                    flex: (fuelPct * 100).round().clamp(1, 100),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kAccentBlue, _kAccentCyan],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${(fuelPct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (maintPct > 0)
                    Expanded(
                      flex: (maintPct * 100).round().clamp(1, 100),
                      child: Container(
                        color: _kOrange,
                        alignment: Alignment.center,
                        child: Text(
                          '${(maintPct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Theoretical bar (reference)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: 70,
                    child: Container(
                      color: _kAccentBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  Expanded(
                    flex: 30,
                    child: Container(color: _kOrange.withValues(alpha: 0.2)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              _LegendDot(color: _kAccentBlue, label: 'Gasoil'),
              const SizedBox(width: 24),
              _LegendDot(color: _kOrange, label: 'Maintenance'),
              const Spacer(),
              // Variance indicator
              _VarianceBadge(label: 'Écart gasoil', value: budget.fuelVariance),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: _kTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _VarianceBadge extends StatelessWidget {
  final String label;
  final double value;
  const _VarianceBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive ? _kGreen : _kRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_down_rounded
                : Icons.trending_up_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '-' : '+'}${value.abs().toStringAsFixed(0)} MAD',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Vehicle Card — carte premium par véhicule avec dépenses
// =============================================================================

class _VehicleCard extends ConsumerWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(
      monthlyExpensesByVehicleProvider(vehicle.id),
    );
    final fuelAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kNavy, _kNavy.withValues(alpha: 0.9)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.marque} ${vehicle.modele}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        vehicle.immatriculation,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${vehicle.annee}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fuel consumption
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: fuelAsync.when(
              loading: () => const _MiniLoader(),
              error: (e, _) => Text(
                'Erreur: $e',
                style: const TextStyle(fontSize: 12, color: _kRed),
              ),
              data: (entries) {
                final totalLitres = entries.fold<double>(
                  0,
                  (sum, e) => sum + e.litres,
                );
                final totalMontant = entries.fold<double>(
                  0,
                  (sum, e) => sum + e.montant,
                );
                final avgPrix = totalLitres > 0
                    ? totalMontant / totalLitres
                    : 0.0;

                return Row(
                  children: [
                    _MiniStat(
                      icon: Icons.water_drop_rounded,
                      iconColor: _kAccentCyan,
                      label: 'Litres',
                      value: totalLitres.toStringAsFixed(1),
                    ),
                    const SizedBox(width: 20),
                    _MiniStat(
                      icon: Icons.payments_rounded,
                      iconColor: _kGreen,
                      label: 'Montant',
                      value: '${totalMontant.toStringAsFixed(0)} MAD',
                    ),
                    const SizedBox(width: 20),
                    _MiniStat(
                      icon: Icons.speed_rounded,
                      iconColor: _kOrange,
                      label: 'Prix/L',
                      value: '${avgPrix.toStringAsFixed(2)} MAD',
                    ),
                  ],
                );
              },
            ),
          ),

          // Monthly expenses
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: expensesAsync.when(
              loading: () => const _MiniLoader(),
              error: (e, _) => Text(
                'Erreur: $e',
                style: const TextStyle(fontSize: 12, color: _kRed),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: _kTextSecondary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Aucune dépense enregistrée',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show latest 3 months
                final recent = expenses.take(3).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: _kBorder),
                    const SizedBox(height: 14),
                    const Text(
                      'Dépenses récentes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recent.map((e) => _MonthRow(expense: e)),
                  ],
                );
              },
            ),
          ),

          // ACTIONS
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => showAddMaintenanceDialog(context, ref, vehicle.id),
                  icon: const Icon(Icons.build_rounded, size: 16, color: _kOrange),
                  label: const Text('Maintenance', style: TextStyle(color: _kOrange)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => showAddFuelDialog(context, ref, vehicle.id),
                  icon: const Icon(Icons.local_gas_station_rounded, size: 16, color: _kAccentBlue),
                  label: const Text('Gasoil', style: TextStyle(color: _kAccentBlue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mini Stat pill
// =============================================================================

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Monthly expense row
// =============================================================================

class _MonthRow extends StatelessWidget {
  final MonthlyExpense expense;
  const _MonthRow({required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = expense.total;
    final fuelFrac = total > 0 ? expense.totalFuel / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              expense.month,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: (fuelFrac * 100).round().clamp(0, 100),
                      child: Container(color: _kAccentBlue),
                    ),
                    Expanded(
                      flex: ((1 - fuelFrac) * 100).round().clamp(0, 100),
                      child: Container(color: _kOrange),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '${total.toStringAsFixed(0)} MAD',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared utility widgets
// =============================================================================

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: _kAccentBlue),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _kRed, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kAccentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 30, color: _kAccentBlue),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kAccentBlue),
        ),
      ),
    );
  }
}
