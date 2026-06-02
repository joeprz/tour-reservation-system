// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/expense.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reservation_list_tile.dart';
import '../reservations/reservation_form_screen.dart';
import '../reservations/reservations_list_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../checkin/checkin_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

 Widget _buildScreen() {
  switch (_selectedIndex) {
    case 0:
      return const _HomeTab();
    case 1:
      return const ReservationsListScreen();
    case 2:
      return const ReportsScreen();
    case 3:
      return const SettingsScreen();
    default:
      return const _HomeTab();
  }
}

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                  extended: MediaQuery.of(context).size.width > 1000,
                  backgroundColor: AppTheme.forestGreen,
                  selectedIconTheme: const IconThemeData(color: AppTheme.goldenFirefly),
                  unselectedIconTheme: const IconThemeData(color: Colors.white54),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.goldenFirefly,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Nunito',
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        if (MediaQuery.of(context).size.width > 1000)
                          const Text(
                            'Luciérnagas',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Inicio'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Reservas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Reportes'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Ajustes'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _buildScreen()),
              ],
            )
          : Column(
              children: [
                Expanded(child: _buildScreen()),
                NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Inicio',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: 'Reservas',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: 'Reportes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Ajustes',
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? Builder(
              builder: (context) {
                final size = MediaQuery.of(context).size;
                final isWide = size.width > 700;
                final isLandscape = size.width > size.height;

                if (isWide || isLandscape) {
                  return FloatingActionButton.extended(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReservationFormScreen(),
                        ),
                      );
                      final dateStr =
    ref.read(selectedDateStringProvider);

await ref
    .read(reservationsProvider.notifier)
    .loadByDate(dateStr);

ref.invalidate(dashboardStatsProvider);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva reserva'),
                    backgroundColor: AppTheme.forestGreen,
                    foregroundColor: Colors.white,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 68, right: 4),
                  child: FloatingActionButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReservationFormScreen(),
                        ),
                      );
                      final dateStr =
    ref.read(selectedDateStringProvider);

await ref
    .read(reservationsProvider.notifier)
    .loadByDate(dateStr);

ref.invalidate(dashboardStatsProvider);
                    },
                    backgroundColor: AppTheme.forestGreen,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Home Tab ───────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  void _openCheckInScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CheckInScreen(),
      ),
    );
  }

  Future<void> _showAddExpenseDialog(BuildContext context, WidgetRef ref) async {
    final conceptController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Agregar gasto'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: conceptController,
                  decoration: const InputDecoration(labelText: 'Concepto'),
                  validator: (value) => value?.trim().isEmpty == true ? 'Ingresa un concepto' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Cantidad', prefixText: r'$ '),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final trimmed = value?.trim();
                    if (trimmed == null || trimmed.isEmpty) return 'Ingresa una cantidad';
                    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Cantidad inválida';
                    return null;
                  },

                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                final concept = conceptController.text.trim();
                final amount = double.parse(amountController.text.trim().replaceAll(',', '.'));
                final dateStr = ref.read(selectedDateStringProvider);
                await ref.read(reservationRepositoryProvider).createExpense(
                  concept: concept,
                  amount: amount,
                  date: dateStr,
                );
                ref.invalidate(dailyExpensesProvider);
                ref.invalidate(allExpensesProvider);
                ref.invalidate(dashboardStatsProvider);
                if (context.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditExpenseDialog(BuildContext context, WidgetRef ref, Expense expense) async {
    final conceptController = TextEditingController(text: expense.concept);
    final amountController = TextEditingController(text: expense.amount.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar gasto'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: conceptController,
                  decoration: const InputDecoration(labelText: 'Concepto'),
                  validator: (value) => value?.trim().isEmpty == true ? 'Ingresa un concepto' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Cantidad', prefixText: r'$ '),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final trimmed = value?.trim();
                    if (trimmed == null || trimmed.isEmpty) return 'Ingresa una cantidad';
                    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Cantidad inválida';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                final updated = Expense(
                  id: expense.id,
                  concept: conceptController.text.trim(),
                  amount: double.parse(amountController.text.trim().replaceAll(',', '.')),
                  date: expense.date,
                  createdAt: expense.createdAt,
                );
                try {
                  await ref.read(reservationRepositoryProvider).updateExpense(updated);
                  ref.invalidate(dailyExpensesProvider);
                  ref.invalidate(allExpensesProvider);
                  ref.invalidate(dashboardStatsProvider);
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gasto actualizado')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar gasto: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteExpense(BuildContext context, WidgetRef ref, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar gasto'),
          content: const Text('¿Deseas eliminar este gasto? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(reservationRepositoryProvider).deleteExpense(expense.id);
        ref.invalidate(dailyExpensesProvider);
        ref.invalidate(allExpensesProvider);
        ref.invalidate(dashboardStatsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto eliminado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar gasto: $e')),
          );
        }
      }
    }
  }

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final date = ref.watch(selectedDateProvider);
  final dateStr = ref.watch(selectedDateStringProvider);
  final stats = ref.watch(dashboardStatsProvider);
  final reservations = ref.watch(reservationsProvider);
  final expensesAsync = ref.watch(dailyExpensesProvider);
  final allExpensesAsync = ref.watch(allExpensesProvider);
  final isSmallScreen = MediaQuery.of(context).size.width < 600;
  final expenseList = expensesAsync.when(
      data: (list) => list,
      loading: () => <Expense>[],
      error: (_, __) => <Expense>[],
    );
    final allExpenseList = allExpensesAsync.when(
      data: (list) => list,
      loading: () => <Expense>[],
      error: (_, __) => <Expense>[],
    );
    final totalExpenses = expenseList.fold(0.0, (sum, item) => sum + item.amount);
    final globalExpensesTotal = allExpenseList.fold(0.0, (sum, item) => sum + item.amount);

  return Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          // Ícono de luciérnaga / brillo
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.goldenFirefly.withOpacity(0.15),
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 18)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Panel de Control'),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'es_MX').format(date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white60,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (!isSmallScreen)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Escanear QR',
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _openCheckInScreen(context),
                color: AppTheme.goldenFirefly,
                iconSize: 22,
              ),
            ),
          ),
        
        Padding(
          padding: EdgeInsets.only(right: isSmallScreen ? 4 : 8),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.goldenFirefly.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppTheme.goldenFirefly.withOpacity(0.4),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 12,
                vertical: isSmallScreen ? 4 : 6,
              ),
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                locale: const Locale('es', 'MX'),
              );
              if (picked != null) {
                final dateStr = DateFormat('yyyy-MM-dd').format(picked);
                ref.read(selectedDateProvider.notifier).state = picked;
                await ref.read(reservationsProvider.notifier).loadByDate(dateStr);
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(dailyExpensesProvider);
              }
            },
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.goldenFirefly,
              size: isSmallScreen ? 14 : 18,
            ),
            label: Text(
              DateFormat('dd MMM', 'es_MX').format(date).toUpperCase(),
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 12,
              ),
            ),
          ),
        ),
        
        if (isSmallScreen)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'qr') {
                _openCheckInScreen(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 18),
                    SizedBox(width: 8),
                    Text('Escanear QR'),
                  ],
                ),
              ),
            ],
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.goldenFirefly,
            ),
          ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(dailyExpensesProvider);
        await ref.read(reservationsProvider.notifier).loadByDate(dateStr);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            stats.when(
              data: (s) => _StatsGrid(
                stats: s,
                globalExpensesTotal: globalExpensesTotal,
                totalExpenses: totalExpenses,
                expenses: expenseList,
                onAddExpense: () => _showAddExpenseDialog(context, ref),
                onEditExpense: (expense) => _showEditExpenseDialog(context, ref, expense),
                onDeleteExpense: (expense) => _confirmDeleteExpense(context, ref, expense),
              ),
              loading: () => const _StatsGridSkeleton(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 22),
            // Today's reservations header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.goldenFirefly,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Reservaciones de hoy',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.list, size: 18),
                  label: const Text('Ver todas'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReservationsListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            reservations.when(
              data: (list) {
                final todayList = list.where((r) => r.date == dateStr).toList();
                if (todayList.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  children: todayList
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ReservationListTile(reservation: r),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    )
  );
  }
}


// ─── Stats Grid ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final double globalExpensesTotal;
  final double totalExpenses;
  final List<Expense> expenses;
  final VoidCallback onAddExpense;
  final void Function(Expense) onEditExpense;
  final void Function(Expense) onDeleteExpense;

  const _StatsGrid({
    required this.stats,
    required this.globalExpensesTotal,
    required this.totalExpenses,
    required this.expenses,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final totalAdults = stats['total_adults'] ?? 0;
    final totalChildren = stats['total_children'] ?? 0;
    final expectedRevenue = (stats['expected_revenue'] as num?)?.toDouble() ?? 0;
    final collectedRevenue = (stats['collected_revenue'] as num?)?.toDouble() ?? 0;
    final pendingPayments = (stats['pending_payments'] as num?)?.toDouble() ?? 0;
    final expensesValue = (stats['total_expenses'] as num?)?.toDouble() ?? totalExpenses;
    final totalReservations = stats['total_reservations'] ?? 0;
    final checkedIn = stats['checked_in_count'] ?? 0;
    final noShow = stats['no_show_count'] ?? 0;
    final pending = totalReservations - checkedIn - noShow;

    return Column(
      children: [
        _SummaryCard(
          icon: Icons.groups_rounded,
          accentColor: const Color(0xFF4A9EFF),
          gradientColors: [const Color(0xFF0D2137), const Color(0xFF0A1A2E)],
          title: 'Operación',
          rows: [
            _StatRow(icon: Icons.bookmark_rounded, label: 'Reservaciones', value: '$totalReservations'),
            _StatRow(icon: Icons.people_alt_rounded, label: 'Visitantes', value: '${totalAdults + totalChildren}'),
            _StatRow(icon: Icons.person_rounded, label: 'Adultos / Niños', value: '$totalAdults · $totalChildren'),
            _StatRow(icon: Icons.local_offer_rounded, label: 'Básico', value: '${stats['basic_people'] ?? 0}'),
            _StatRow(icon: Icons.cabin_rounded, label: 'Camping', value: '${stats['camping_people'] ?? 0}'),
            _StatRow(icon: Icons.workspace_premium_rounded, label: 'Premium', value: '${stats['premium_people'] ?? 0}'),
            _StatRow(icon: Icons.house_rounded, label: 'Casas rentadas', value: '${stats['tents_count'] ?? 0}'),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          icon: Icons.monetization_on_rounded,
          accentColor: AppTheme.goldenFirefly,
          gradientColors: [const Color(0xFF1E1600), const Color(0xFF140E00)],
          title: 'Ingresos',
          rows: [
            _StatRow(icon: Icons.trending_up_rounded, label: 'Esperado', value: fmt.format(expectedRevenue)),
            _StatRow(icon: Icons.check_circle_outline_rounded, label: 'Cobrado', value: fmt.format(collectedRevenue), valueColor: Colors.greenAccent.shade400),
            _StatRow(icon: Icons.schedule_rounded, label: 'Por cobrar', value: fmt.format(pendingPayments), valueColor: AppTheme.goldenFirefly),
            _StatRow(icon: Icons.money_off, label: 'Gastos', value: fmt.format(expensesValue), valueColor: Colors.redAccent.shade200),
            _StatRow(icon: Icons.account_balance_wallet_rounded, label: 'Neto', value: fmt.format(expectedRevenue - expensesValue), valueColor: Colors.white),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          icon: Icons.receipt_long,
          accentColor: const Color(0xFFCF6C3D),
          gradientColors: [const Color(0xFF281208), const Color(0xFF2B120F)],
          title: 'Gastos',
          rows: [
            _StatRow(icon: Icons.public, label: 'Gastos globales', value: fmt.format(globalExpensesTotal), valueColor: Colors.redAccent.shade100),
            _StatRow(icon: Icons.today, label: 'Gastos del día', value: fmt.format(totalExpenses), valueColor: Colors.redAccent.shade200),
          ],
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (expenses.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                ...expenses.map(
                  (expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.concept,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy', 'es_MX').format(expense.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(expense.amount),
                          style: TextStyle(
                            color: Colors.redAccent.shade100,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          color: Theme.of(context).colorScheme.surface,
                          icon: Icon(Icons.more_vert, color: Colors.white70, size: 18),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEditExpense(expense);
                            } else if (value == 'delete') {
                              onDeleteExpense(expense);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Agregar gasto'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.22)),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onAddExpense,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          icon: Icons.verified_rounded,
          accentColor: const Color(0xFF50E090),
          gradientColors: [const Color(0xFF071A0E), const Color(0xFF041208)],
          title: 'Estado',
          rows: [
            _StatRow(icon: Icons.login_rounded, label: 'Llegaron', value: '$checkedIn', valueColor: Colors.greenAccent.shade400),
            _StatRow(icon: Icons.hourglass_top_rounded, label: 'Pendientes', value: '$pending', valueColor: AppTheme.goldenFirefly),
            _StatRow(icon: Icons.cancel_outlined, label: 'No Show', value: '$noShow', valueColor: noShow > 0 ? Colors.redAccent.shade200 : null),
          ],
        ),
      ],
    );
  }
}

// ─── Stat Row ────────────────────────────────────────────────────────────────

class _StatRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

// ─── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final String title;
  final List<_StatRow> rows;
  final Widget? footer;

  const _SummaryCard({
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.title,
    required this.rows,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                    color: Colors.white.withOpacity(0.95),
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                // Línea decorativa de acento
                Container(
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Divider sutil
            Divider(color: accentColor.withOpacity(0.15), height: 1),
            const SizedBox(height: 12),
            // Rows
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Icon(row.icon, size: 14, color: accentColor.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withOpacity(0.55),
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        row.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: row.valueColor ?? Colors.white.withOpacity(0.9),
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )),
            if (footer != null) ...[
              const SizedBox(height: 10),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text(
            'No hay reservaciones para hoy',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Usa el botón "Nueva reserva" para agregar',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}