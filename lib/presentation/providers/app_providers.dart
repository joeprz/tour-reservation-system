// lib/presentation/providers/app_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/sync_client.dart';
import '../../core/network/sync_server.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/app_settings.dart';
import '../../core/network/supabase_service.dart';

// ─── Shared Preferences ────────────────────────────────────────────────────

// 🔔 dispara un “tick” cada vez que hay sync
final syncStateProvider = StateProvider<int>((ref) => 0);
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ─── Device Role ────────────────────────────────────────────────────────────

final deviceRoleProvider = FutureProvider<AppRole?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final roleStr = prefs.getString(AppConstants.keyDeviceRole);
  if (roleStr == null) return null;
  return roleStr == 'reception' ? AppRole.reception : AppRole.checkin;
});

class DeviceRoleNotifier extends Notifier<AppRole?> {
  @override
  AppRole? build() => null;

  Future<void> setRole(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyDeviceRole,
      role == AppRole.reception ? 'reception' : 'checkin',
    );
    state = role;
  }

  Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyDeviceRole);
    state = null;
  }
}

final deviceRoleNotifierProvider =
    NotifierProvider<DeviceRoleNotifier, AppRole?>(
  DeviceRoleNotifier.new,
);

final scannerNameProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyScannerName);
});

// ─── Theme Mode ─────────────────────────────────────────────────────────────

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyThemeMode);
    if (saved == 'dark') state = ThemeMode.dark;
    if (saved == 'system') state = ThemeMode.system;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setString(
      AppConstants.keyThemeMode,
      state == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

// ─── Repositories ───────────────────────────────────────────────────────────

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// ─── Settings ────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier(ref.read(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repo.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(AppSettings settings) async {
    final updated = await _repo.updateSettings(settings);
    state = AsyncValue.data(updated);
  }
}

// ─── Selected Date ──────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final selectedDateStringProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return DateFormat('yyyy-MM-dd').format(date);
});

final dailyExpensesProvider =
    FutureProvider.autoDispose<List<Expense>>((ref) async {
  final date = ref.watch(selectedDateStringProvider);
  final repo = ref.read(reservationRepositoryProvider);
  return await repo.getExpensesByDate(date);
});

final allExpensesProvider =
    FutureProvider.autoDispose<List<Expense>>((ref) async {
  final repo = ref.read(reservationRepositoryProvider);
  return await repo.getAllExpenses();
});

// ─── Dashboard Stats ─────────────────────────────────────────────────────────

final dashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final date = ref.watch(selectedDateStringProvider);
  final repo = ref.read(reservationRepositoryProvider);
  return await repo.getDashboardStats(date);
});

// ─── Reservations List ───────────────────────────────────────────────────────

final reservationsProvider =
    StateNotifierProvider<ReservationsNotifier, AsyncValue<List<Reservation>>>(
        (ref) {
  return ReservationsNotifier(
    ref.read(reservationRepositoryProvider),
    ref,
  );
});

/// Manages reservation state, data sync and search filters.
class ReservationsNotifier
    extends StateNotifier<AsyncValue<List<Reservation>>> {
  final ReservationRepository _repo;
  final Ref ref;

  ReservationsNotifier(this._repo, this.ref)
      : super(const AsyncValue.loading()) {
    loadAll();
  }
  Future<void> updateReservation(
    Reservation r,
  ) async {
    await _repo.updateReservation(r);
    await loadAll();
  }

  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    try {
      final reservations = await _repo.getAllReservations();
      state = AsyncValue.data(reservations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadByDate(String date) async {
    state = const AsyncValue.loading();
    try {
      final reservations = await _repo.getReservationsByDate(date);
      state = AsyncValue.data(reservations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a reservation and syncs it if a server IP is configured.
  Future<Reservation> createReservation({
    required String customerName,
    required String customerPhone,
    required String date,
    required String timeSlot,
    required int adults,
    required int children,
    required double adultPrice,
    required double childPrice,
    required double deposit,
    required String packageType,
    required String packageName,
    required int tents,
    String? notes,
  }) async {
    final reservation = await _repo.createReservation(
      customerName: customerName,
      customerPhone: customerPhone,
      date: date,
      timeSlot: timeSlot,
      adults: adults,
      children: children,
      adultPrice: adultPrice,
      childPrice: childPrice,
      deposit: deposit,
      packageType: packageType,
      packageName: packageName,
      tents: tents,
      notes: notes,
    );

    await _pushReservationIfServerConfigured(reservation);
    await loadAll();

    return reservation;
  }

  /// Pushes a reservation to the sync server if the server IP is configured.
  Future<void> _pushReservationIfServerConfigured(
    Reservation reservation,
  ) async {
    final ip = ref.read(serverIpProvider);
    if (ip == null || ip.isEmpty) return;

    final client = SyncClient()..serverIp = ip;
    await client.pushReservation(reservation.toMap());
    ref.read(syncStateProvider.notifier).state++;
  }

  Future<void> updateStatus(String id, ReservationStatus status) async {
    final r = await _repo.getReservationById(id);

    if (r != null) {
      await _repo.updateReservation(
        r.copyWith(status: status),
      );
    }
    await loadAll();
  }

  Future<void> checkIn(String id, {String? checkedInBy}) async {
    await _repo.checkIn(id, checkedInBy: checkedInBy);
    final r = await _repo.getReservationById(id);
    if (r != null) {
      await _pushReservationIfServerConfigured(r);
    }
    await loadAll();
  }

  Future<void> search({
    String? name,
    String? phone,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final results = await _repo.searchReservations(
        nameQuery: name,
        phoneQuery: phone,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelReservation(
    String id,
  ) async {
    await SupabaseService.client.from('reservations').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteReservation(
    String id,
  ) async {
    await SupabaseService.client.from('reservations').delete().eq('id', id);
  }
}

// ─── Sync ────────────────────────────────────────────────────────────────────

final syncServerProvider = Provider<SyncServer>((ref) => SyncServer());
final syncClientProvider = Provider<SyncClient>((ref) => SyncClient());

final syncStatusProvider = StateProvider<String>((ref) => 'Desconectado');
final serverRunningProvider = StateProvider<bool>((ref) => false);
final serverIpProvider = StateProvider<String?>((ref) => null);

// ─── Search / Filter state ─────────────────────────────────────────────────

class ReservationFilter {
  final String? nameQuery;
  final String? phoneQuery;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const ReservationFilter({
    this.nameQuery,
    this.phoneQuery,
    this.status,
    this.dateFrom,
    this.dateTo,
  });

  ReservationFilter copyWith({
    String? nameQuery,
    String? phoneQuery,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return ReservationFilter(
      nameQuery: nameQuery ?? this.nameQuery,
      phoneQuery: phoneQuery ?? this.phoneQuery,
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

final reservationFilterProvider = StateProvider<ReservationFilter>((ref) {
  return const ReservationFilter();
});
