// lib/presentation/screens/reservations/reservations_list_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/sync_client.dart';
import '../../../core/network/supabase_service.dart';
import '../../../domain/entities/reservation.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reservation_list_tile.dart';

class ReservationsListScreen extends ConsumerStatefulWidget {
  const ReservationsListScreen({super.key});

  @override
  ConsumerState<ReservationsListScreen> createState() =>
      _ReservationsListScreenState();
}

class _ReservationsListScreenState
    extends ConsumerState<ReservationsListScreen> {
  Timer? _syncTimer;
  bool _isSyncing = false;
  final _searchCtrl = TextEditingController();
  String? _statusFilter;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();

    SupabaseService.client
        .channel('reservations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reservations',
          callback: (payload) async {
            final dateStr = ref.read(selectedDateStringProvider);
            await ref.read(reservationsProvider.notifier).loadByDate(dateStr);
            ref.invalidate(dashboardStatsProvider);
          },
        )
        .subscribe();

    ref.listenManual(syncStateProvider, (_, __) async {
      final dateStr = ref.read(selectedDateStringProvider);
      await ref.read(reservationsProvider.notifier).loadByDate(dateStr);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dateStr = ref.read(selectedDateStringProvider);
      ref.read(reservationsProvider.notifier).loadByDate(dateStr);

      final ip = ref.read(serverIpProvider);
      if (ip != null && ip.isNotEmpty) {
        _startAutoSync(ip);
      }
    });
  }

  void _startAutoSync(String ip) {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        if (_isSyncing) return;
        _isSyncing = true;

        try {
          final client = SyncClient()..serverIp = ip;
          final result = await client.pullReservations();

          if (result.status == SyncStatus.success) {
            ref.read(syncStateProvider.notifier).state++;
          }
        } catch (_) {
          // Network sync failed silently to preserve UI responsiveness.
        }

        _isSyncing = false;
      },
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim();

    final today = DateTime.now();

    final date = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    ref
        .read(
          reservationsProvider.notifier,
        )
        .search(
          name: q.isNotEmpty ? q : null,
          status: _statusFilter,
          dateFrom: date,
          dateTo: date,
        );
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(reservationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservaciones'),
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: () {
              final today = DateTime.now();

              final date = '${today.year.toString().padLeft(4, '0')}-'
                  '${today.month.toString().padLeft(2, '0')}-'
                  '${today.day.toString().padLeft(2, '0')}';

              ref
                  .read(
                    reservationsProvider.notifier,
                  )
                  .loadByDate(date);
            },
            tooltip: 'Actualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showFilters ? 120 : 60),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applySearch(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o teléfono...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applySearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
              if (_showFilters)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      const Text('Estado:',
                          style: TextStyle(
                              color: Colors.white70, fontFamily: 'Nunito')),
                      const SizedBox(width: 8),
                      ...[
                        null,
                        'pending',
                        'confirmed',
                        'checked_in',
                        'no_show',
                        'cancelled'
                      ].map((s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(s == null
                                  ? 'Todos'
                                  : ReservationStatus.fromString(s).label),
                              selected: _statusFilter == s,
                              onSelected: (_) {
                                setState(() => _statusFilter = s);
                                _applySearch();
                              },
                              selectedColor: s == null
                                  ? AppTheme.forestGreen
                                  : AppTheme.statusColor(s),
                              labelStyle: TextStyle(
                                color: _statusFilter == s ? Colors.white : null,
                                fontFamily: 'Nunito',
                                fontSize: 12,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: reservations.when(
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyReservations();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final r = list[index];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Dismissible(
                  key: Key(r.id),

                  /// Swipe derecha = cancelar
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(
                      left: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Swipe izquierda = eliminar
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),

                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      return await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text(
                            'Cancelar reserva',
                          ),
                          content: Text(
                            '¿Cancelar ${r.code}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(
                                context,
                                false,
                              ),
                              child: const Text(
                                'No',
                              ),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                context,
                                true,
                              ),
                              child: const Text(
                                'Sí',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text(
                          'Eliminar reserva',
                        ),
                        content: Text(
                          '¿Eliminar ${r.code} permanentemente?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(
                              context,
                              false,
                            ),
                            child: const Text(
                              'No',
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(
                              context,
                              true,
                            ),
                            child: const Text(
                              'Sí',
                            ),
                          ),
                        ],
                      ),
                    );
                  },

                  onDismissed: (direction) async {
                    final id = r.id;

                    try {
                      if (direction == DismissDirection.startToEnd) {
                        await ref
                            .read(
                              reservationsProvider.notifier,
                            )
                            .cancelReservation(id);
                      } else {
                        await ref
                            .read(
                              reservationsProvider.notifier,
                            )
                            .deleteReservation(id);
                      }

                      final dateStr = ref.read(
                        selectedDateStringProvider,
                      );

                      await ref
                          .read(
                            reservationsProvider.notifier,
                          )
                          .loadByDate(dateStr);

                      ref.invalidate(
                        dashboardStatsProvider,
                      );
                    } catch (_) {
                      // Error handled by UI fallback.
                    }
                  },

                  child: ReservationListTile(
                    reservation: r,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EmptyReservations extends StatelessWidget {
  const _EmptyReservations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron reservaciones',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros de búsqueda',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
