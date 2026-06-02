import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../domain/entities/reservation.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncResult {
  final SyncStatus status;
  final String message;
  final int syncedCount;

  const SyncResult({
    required this.status,
    required this.message,
    this.syncedCount = 0,
  });
}

class SyncClient {
  final ReservationRepository _repo = ReservationRepository();

  // Local sync server settings. The client connects to the tablet/host device.
  String? serverIp;
  int serverPort = AppConstants.syncServerPort;
  Duration timeout = const Duration(seconds: 5);

  String get _baseUrl => 'http://$serverIp:$serverPort';

  Future<void> pushReservation(
    Map<String, dynamic> reservation,
  ) async {
    if (serverIp == null) return;

    await http.post(
      Uri.parse(
        '$_baseUrl${AppConstants.syncApiPrefix}/reservations',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(reservation),
    );
  }
  // ───────── HEALTH CHECK ─────────

  Future<bool> isServerReachable() async {
    if (serverIp == null || serverIp!.isEmpty) {
      return false;
    }

    try {
      final res = await http
          .get(
            Uri.parse(
              '$_baseUrl/health',
            ),
          )
          .timeout(timeout);

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ───────── PULL RESERVATIONS ─────────

  Future<SyncResult> pullReservations() async {
    if (serverIp == null) {
      return const SyncResult(
        status: SyncStatus.error,
        message: 'IP del servidor no configurada',
      );
    }

    try {
      final res = await http
          .get(
            Uri.parse(
              '$_baseUrl${AppConstants.syncApiPrefix}/reservations',
            ),
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        return SyncResult(
          status: SyncStatus.error,
          message: 'Error ${res.statusCode}',
        );
      }

      final list = jsonDecode(res.body) as List;

      int count = 0;

      for (final item in list) {
        await _repo.upsertFromSync({
          'entity_type': AppConstants.tableReservations,
          'entity': Map<String, dynamic>.from(
            item,
          ),
        });

        count++;
      }

      return SyncResult(
        status: SyncStatus.success,
        message: 'Sincronización correcta',
        syncedCount: count,
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Error conexión: $e',
      );
    }
  }

  // ───────── REMOTE CHECKIN ─────────

  Future<Map<String, dynamic>> remoteCheckIn(
    String token,
  ) async {
    if (serverIp == null) {
      return {
        'success': false,
        'offline': true,
        'message': 'Servidor no configurado',
      };
    }

    try {
      final res = await http
          .post(
            Uri.parse(
              '$_baseUrl${AppConstants.syncApiPrefix}/checkin',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'token': token,
            }),
          )
          .timeout(timeout);

      final body = jsonDecode(
        res.body,
      );

      // éxito
      if (res.statusCode == 200) {
        final data = body['reservation'];

        await _repo.upsertFromSync({
          'entity_type': AppConstants.tableReservations,
          'entity': Map<String, dynamic>.from(
            data,
          ),
        });

        return {
          'success': true,
          'reservation': data,
        };
      }

      // saldo pendiente
      if (res.statusCode == 403) {
        return {
          'success': false,
          'pendingBalance': true,
          'message': body['error'],
          'reservation': body['reservation'],
        };
      }

      // duplicado
      if (res.statusCode == 409) {
        return {
          'success': false,
          'alreadyCheckedIn': true,
          'message': body['error'],
          'reservation': body['reservation'],
        };
      }

      // no encontrado
      if (res.statusCode == 404) {
        return {
          'success': false,
          'notFound': true,
          'message': body['error'],
        };
      }

      return {
        'success': false,
        'message': body['error'] ?? 'Error',
      };
    } catch (e) {
      return {
        'success': false,
        'offline': true,
        'message': 'Sin conexión: $e',
      };
    }
  }

  // ───────── TOKEN LOOKUP ─────────

  Future<Reservation?> getReservationByToken(
    String token,
  ) async {
    return await _repo.getReservationByToken(
      token,
    );
  }
}
