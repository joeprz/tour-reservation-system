import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/reservation.dart';
import '../../core/network/supabase_service.dart';

class ReservationRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ───────────────── CUSTOMERS ─────────────────

  Future<Customer> createOrGetCustomer({
    required String name,
    required String phone,
  }) async {
    final existing = await _db.queryWhere(
      AppConstants.tableCustomers,
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (existing.isNotEmpty) {
      return Customer.fromMap(existing.first);
    }

    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );

    await _db.insert(
      AppConstants.tableCustomers,
      customer.toMap(),
    );

    return customer;
  }

  // ───────────────── CREATE RESERVATION ─────────────────

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
    final customer = await createOrGetCustomer(
      name: customerName,
      phone: customerPhone,
    );

    final id = _uuid.v4();
    final code = 'LCT-${DateTime.now().millisecondsSinceEpoch}';
    final token = _generateToken(id);

    final total = (adults * adultPrice) + (children * childPrice);

    final balance = total - deposit;

    final now = DateTime.now();

    final reservation = Reservation(
      id: id,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      code: code,
      token: token,
      date: date,
      timeSlot: timeSlot,
      adults: adults,
      children: children,
      adultPrice: adultPrice,
      childPrice: childPrice,
      total: total,
      deposit: deposit,
      balance: balance,
      packageType: packageType,
      packageName: packageName,
      tents: tents,
      status:
          deposit > 0 ? ReservationStatus.confirmed : ReservationStatus.pending,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await SupabaseService.client.from('reservations').insert(
          reservation.toMap(),
        );

    return reservation;
  }

  // ───────────────── GETTERS ─────────────────

  Future<List<Reservation>> getAllReservations() async {
    final data = await SupabaseService.client
        .from('reservations')
        .select()
        .order('date', ascending: false);

    return data
        .map<Reservation>(
          (e) => Reservation.fromMap(e),
        )
        .toList();
  }

  Future<List<Reservation>> getReservationsByDate(
    String date,
  ) async {
    final data = await SupabaseService.client
        .from('reservations')
        .select()
        .eq('date', date)
        .order('time_slot');

    return data
        .map<Reservation>(
          (e) => Reservation.fromMap(e),
        )
        .toList();
  }

  Future<List<Reservation>> getReservationsByRange(
    String from,
    String to,
  ) async {
    final data = await SupabaseService.client
        .from('reservations')
        .select()
        .gte('date', from)
        .lte('date', to)
        .order('date', ascending: true)
        .order('time_slot', ascending: true);

    return (data as List<dynamic>)
        .map((e) => Reservation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Reservation?> getReservationById(
    String id,
  ) async {
    final data = await SupabaseService.client
        .from('reservations')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    return Reservation.fromMap(data);
  }

  Future<Reservation?> getReservationByToken(
    String token,
  ) async {
    final data = await SupabaseService.client
        .from('reservations')
        .select()
        .eq('token', token)
        .maybeSingle();

    if (data == null) return null;

    return Reservation.fromMap(data);
  }

  // ───────────────── UPDATE ─────────────────

  Future<Reservation> updateReservation(
    Reservation r,
  ) async {
    final updated = r.copyWith(
      updatedAt: DateTime.now(),
    );

    await SupabaseService.client
        .from('reservations')
        .update(
          updated.toMap(),
        )
        .eq('id', updated.id);

    return updated;
  }

  Future<void> checkIn(
    String id, {
    String? checkedInBy,
  }) async {
    await SupabaseService.client.from('reservations').update({
      'status': 'checked_in',
      'checked_in_at': DateTime.now().toIso8601String(),
      'checked_in_by': checkedInBy,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<Expense> createExpense({
    required String concept,
    required double amount,
    required String date,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final expense = Expense(
      id: id,
      concept: concept,
      amount: amount,
      date: date,
      createdAt: now,
    );

    await SupabaseService.client
        .from(AppConstants.tableExpenses)
        .insert(expense.toMap());

    return expense;
  }

  Future<List<Expense>> getExpensesByDate(
    String date,
  ) async {
    final data = await SupabaseService.client
        .from(AppConstants.tableExpenses)
        .select()
        .eq('date', date)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => Expense.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final data = await SupabaseService.client
        .from(AppConstants.tableExpenses)
        .select()
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => Expense.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> updateExpense(Expense expense) async {
    final response = await SupabaseService.client
        .from(AppConstants.tableExpenses)
        .update({
          'concept': expense.concept,
          'amount': expense.amount,
          'date': expense.date,
          'created_at': expense.createdAt.toIso8601String(),
        })
        .eq('id', expense.id)
        .select();

    final rows = response as List;
    if (rows.isEmpty) {
      throw Exception('No se actualizó ningún gasto');
    }

    return expense;
  }

  Future<void> deleteExpense(String id) async {
    final response = await SupabaseService.client
        .from(AppConstants.tableExpenses)
        .delete()
        .eq('id', id)
        .select();

    final rows = response as List;
    if (rows.isEmpty) {
      throw Exception('No se eliminó ningún gasto');
    }
  }

  Future<double> getTotalExpensesByDate(
    String date,
  ) async {
    final rows = await getExpensesByDate(date);
    return rows.fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> cancelReservation(String id) async {
    final r = await getReservationById(id);
    if (r == null) return;

    await updateReservation(
      r.copyWith(
        status: ReservationStatus.cancelled,
      ),
    );
  }

  Future<void> deleteReservation(
    String id,
  ) async {
    await SupabaseService.client.from('reservations').delete().eq('id', id);
  }

  // ───────────────── SEARCH ─────────────────

  Future<List<Reservation>> searchReservations({
    String? nameQuery,
    String? phoneQuery,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final rows = await getAllReservations();

    return rows.where((r) {
      if (nameQuery != null &&
          nameQuery.isNotEmpty &&
          !r.customerName.toLowerCase().contains(
                nameQuery.toLowerCase(),
              )) {
        return false;
      }

      if (status != null && status.isNotEmpty && r.status.value != status) {
        return false;
      }

      return true;
    }).toList();
  }

  // ───────────────── DASHBOARD ─────────────────

  Future<Map<String, dynamic>> getDashboardStats(
    String date,
  ) async {
    final list = await getReservationsByDate(date);
    final expenses = await getExpensesByDate(date);

    double total = 0;
    double deposit = 0;
    double balance = 0;

    double basicRevenue = 0;
    double campingRevenue = 0;
    double premiumRevenue = 0;

    int adults = 0;
    int children = 0;

    int checked = 0;
    int noShow = 0;

    int basicCount = 0;
    int campingCount = 0;
    int premiumCount = 0;
    int basicPeople = 0;
    int campingPeople = 0;
    int premiumPeople = 0;
    int tents2Count = 0;
    int tents4Count = 0;
    int tents6Count = 0;
    int tents10Count = 0;

    int rentedTentsCount = 0;

    for (final r in list) {
      total += r.total;
      deposit += r.deposit;
      balance += r.balance;

      adults += r.adults;
      children += r.children;

      if (r.tents > 0) {
        rentedTentsCount++;
      }

      if (r.tents == 2) tents2Count++;
      if (r.tents == 4) tents4Count++;
      if (r.tents == 6) tents6Count++;
      if (r.tents == 10) tents10Count++;

      if (r.isCheckedIn) {
        checked++;
      }

      if (r.status == ReservationStatus.noShow) {
        noShow++;
      }

      final people = r.adults + r.children;

      switch (r.packageType) {
        case 'camping':
          campingCount++;
          campingRevenue += r.total;
          campingPeople += people;
          break;

        case 'premium':
          premiumCount++;
          premiumRevenue += r.total;
          premiumPeople += people;
          break;

        default:
          basicCount++;
          basicRevenue += r.total;
          basicPeople += people;
      }
    }

    return {
      'total_reservations': list.length,
      'total_adults': adults,
      'total_children': children,
      'expected_revenue': total,
      'collected_revenue': deposit,
      'pending_payments': balance,
      'checked_in_count': checked,
      'no_show_count': noShow,
      'basic_count': basicCount,
      'camping_count': campingCount,
      'premium_count': premiumCount,
      'basic_people': basicPeople,
      'camping_people': campingPeople,
      'premium_people': premiumPeople,
      'tents_2_count': tents2Count,
      'tents_4_count': tents4Count,
      'tents_6_count': tents6Count,
      'tents_10_count': tents10Count,
      'tents_count': rentedTentsCount,
      'basic_revenue': basicRevenue,
      'camping_revenue': campingRevenue,
      'premium_revenue': premiumRevenue,
      'total_expenses': expenses.fold(0.0, (sum, item) => sum + item.amount),
    };
  }

  // ───────────────── HELPERS ─────────────────
  Future<void> upsertFromSync(
    Map<String, dynamic> data,
  ) async {
    final table = data['entity_type'] as String;

    final entity = Map<String, dynamic>.from(
      data['entity'],
    );

    final clean = Map<String, dynamic>.from(entity);

    clean.remove('customer_name');
    clean.remove('customer_phone');

    await _db.insert(
      table,
      clean,
    );
  }

  String _generateToken(String id) {
    final bytes = utf8.encode(
      '$id-${DateTime.now().millisecondsSinceEpoch}',
    );

    return sha256.convert(bytes).toString().substring(0, 20);
  }
}
