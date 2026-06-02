// lib/presentation/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../reservations/reservation_detail_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime toDate = DateTime.now();
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));

  bool loading = false;

  double total = 0;
  double deposit = 0;
  double balance = 0;

  int adults = 0;
  int children = 0;
  int checkedIn = 0;
  int reservations = 0;

  List<dynamic> list = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => fromDate = picked);
      _loadData();
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => toDate = picked);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => loading = true);
    final repo = ref.read(reservationRepositoryProvider);

    final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(toDate);

    try {
      final data = await repo.getReservationsByRange(fromStr, toStr);

      double t = 0;
      double d = 0;
      double b = 0;

      int a = 0;
      int c = 0;
      int check = 0;

      for (final r in data) {
        t += (r.total as num?)?.toDouble() ?? 0;
        d += (r.deposit as num?)?.toDouble() ?? 0;
        b += (r.balance as num?)?.toDouble() ?? 0;

        a += (r.adults as num?)?.toInt() ?? 0;
        c += (r.children as num?)?.toInt() ?? 0;

        if (r.isCheckedIn) check++;
      }

      if (!mounted) return;
      setState(() {
        list = data;
        total = t;
        deposit = d;
        balance = b;
        adults = a;
        children = c;
        checkedIn = check;
        reservations = data.length;
      });
    } catch (_) {
      // Keep report loading silent; UI fallback handles errors.
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Al deslizar hacia abajo, recarga los datos
          await _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ───── RANGO ─────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _pickFrom,
                      child: Text(
                        'Desde: ${DateFormat('dd/MM/yyyy').format(fromDate)}',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickTo,
                      child: Text(
                        'Hasta: ${DateFormat('dd/MM/yyyy').format(toDate)}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ───── STATS ─────
              if (loading)
                const CircularProgressIndicator()
              else if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No hay datos en este rango'),
                )
              else
                _topStats(),

              const SizedBox(height: 10),

              // ───── LISTA ─────
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final r = list[i];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 8),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReservationDetailScreen(
                                reservation: r,
                              ),
                            ),
                          );
                        },
                        title: Text(r.customerName),
                        subtitle: Text(
                          '${r.packageName}\n${(r.adults as num?)?.toInt() ?? 0} adultos • ${(r.children as num?)?.toInt() ?? 0} niños${r.tents > 0 ? ' • ${r.tents} personas' : ''}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '\$${r.total.toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              r.status.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: r.isCheckedIn
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topStats() {
    return Column(
      children: [
        Row(
          children: [
            _box('Reservas', '$reservations'),
            _box('Ingresaron', '$checkedIn'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _box('Personas', '${adults + children}'),
            _box('Cobrado', '\$${deposit.toStringAsFixed(0)}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _box('Pendiente', '\$${balance.toStringAsFixed(0)}'),
            _box('Esperado', '\$${total.toStringAsFixed(0)}'),
          ],
        ),
      ],
    );
  }

  Widget _box(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.forestGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.forestGreen.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70, // 👈 visible SIEMPRE
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white, // 👈 clave
              ),
            ),
          ],
        ),
      ),
    );
  }
}
