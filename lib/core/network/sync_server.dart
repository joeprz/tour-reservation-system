import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../data/repositories/reservation_repository.dart';

class SyncServer {
  HttpServer? _server;

  final ReservationRepository _repo = ReservationRepository();

  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;

    final router = Router();

    // ───────── HEALTH ─────────

    router.get('/ping', (_) {
      return _json({
        'ok': true,
        'server': 'luciernagas',
      });
    });

    router.get('/health', (_) {
      return _json({
        'ok': true,
        'time': DateTime.now().toIso8601String(),
      });
    });

    // ───────── ALL RESERVATIONS ─────────

    router.get(
      '${AppConstants.syncApiPrefix}/reservations',
      (Request req) async {
        try {
          final list = await _repo.getAllReservations();

          return _json(
            list.map((e) => e.toJson()).toList(),
          );
        } catch (e) {
          return _error(e);
        }
      },
    );

    // ───────── BY DATE ─────────

    router.get(
      '${AppConstants.syncApiPrefix}/reservations/date/<date>',
      (Request req, String date) async {
        try {
          final list = await _repo.getReservationsByDate(
            date,
          );

          return _json(
            list.map((e) => e.toJson()).toList(),
          );
        } catch (e) {
          return _error(e);
        }
      },
    );
    router.post(
      '${AppConstants.syncApiPrefix}/reservations',
      (Request req) async {
        try {
          final body = jsonDecode(
            await req.readAsString(),
          );

          // Remove fields that are not stored in the reservations table.
          final clean = Map<String, dynamic>.from(body);
          clean.remove('customer_name');
          clean.remove('customer_phone');

          await _repo.upsertFromSync({
            'entity_type': AppConstants.tableReservations,
            'entity': clean,
          });

          return _json({
            'success': true,
          });
        } catch (e) {
          return _error(e);
        }
      },
    );
    // ───────── GET BY ID ─────────

    router.get(
      '${AppConstants.syncApiPrefix}/reservations/<id>',
      (Request req, String id) async {
        try {
          final r = await _repo.getReservationById(id);

          if (r == null) {
            return Response.notFound(
              jsonEncode({'error': 'Reservación no encontrada'}),
            );
          }

          return _json(r.toJson());
        } catch (e) {
          return _error(e);
        }
      },
    );

    // ───────── CHECK IN ─────────

    router.post(
      '${AppConstants.syncApiPrefix}/checkin',
      (Request req) async {
        try {
          final body = jsonDecode(
            await req.readAsString(),
          );

          final token = body['token']?.toString();

          if (token == null || token.isEmpty) {
            return Response(
              400,
              body: jsonEncode({'error': 'Token requerido'}),
            );
          }

          final reservation = await _repo.getReservationByToken(
            token,
          );

          if (reservation == null) {
            return Response(
              404,
              body: jsonEncode({
                'error': 'Reservación no encontrada',
                'notFound': true,
              }),
            );
          }

          // NUEVA REGLA:
          // si debe saldo no entra

          if (reservation.balance > 0) {
            return Response(
              403,
              body: jsonEncode({
                'error': 'Saldo pendiente. Pase a recepción.',
                'pendingBalance': true,
                'reservation': reservation.toJson(),
              }),
            );
          }

          if (reservation.isCheckedIn) {
            return Response(
              409,
              body: jsonEncode({
                'error': 'Ya ingresó',
                'alreadyCheckedIn': true,
                'reservation': reservation.toJson(),
              }),
            );
          }

          await _repo.checkIn(
            reservation.id,
          );

          final updated = await _repo.getReservationById(
            reservation.id,
          );

          return _json({
            'success': true,
            'reservation': updated?.toJson(),
          });
        } catch (e) {
          return _error(e);
        }
      },
    );

    // ───────── EXPORT DB ─────────

    router.get(
      '${AppConstants.syncApiPrefix}/export',
      (_) async {
        try {
          final data = await DatabaseHelper.instance.exportAll();

          return _json(data);
        } catch (e) {
          return _error(e);
        }
      },
    );

    final handler = const Pipeline()
        .addMiddleware(
          logRequests(),
        )
        .addMiddleware(
          _cors(),
        )
        .addHandler(
          router.call,
        );

    _server = await io.serve(
      handler,
      InternetAddress.anyIPv4,
      AppConstants.syncServerPort,
    );
  }

  Future<void> stop() async {
    await _server?.close(
      force: true,
    );

    _server = null;
  }

  // ───────── HELPERS ─────────

  Response _json(dynamic data) {
    return Response.ok(
      jsonEncode(data),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  Response _error(dynamic e) {
    return Response.internalServerError(
      body: jsonEncode({
        'error': e.toString(),
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  Middleware _cors() {
    return (inner) {
      return (req) async {
        final res = await inner(req);

        return res.change(
          headers: {
            ...res.headers,
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': '*',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
          },
        );
      };
    };
  }
}
