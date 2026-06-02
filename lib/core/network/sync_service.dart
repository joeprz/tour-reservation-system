// lib/core/sync/sync_service.dart

abstract class SyncService {
  Future<void> pull();

  Future<void> pushReservation(
    Map<String, dynamic> reservation,
  );

  Future<bool> isAvailable();
}