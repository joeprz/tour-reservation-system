// lib/core/sync/sync_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../network/sync_client.dart';

class SyncController {
  Timer? _timer;
  bool _isSyncing = false;

  void start(WidgetRef ref, String ip) {
    stop(); // Prevent duplicate sync timers.

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        if (_isSyncing) return;

        _isSyncing = true;

        try {
          final client = SyncClient()..serverIp = ip;

          final result = await client.pullReservations();

          if (result.status == SyncStatus.success) {
            final dateStr = ref.read(selectedDateStringProvider);

            await ref.read(reservationsProvider.notifier).loadByDate(dateStr);

            ref.invalidate(dashboardStatsProvider);
          }
        } catch (_) {}

        _isSyncing = false;
      },
    );
  }

  void stop() {
    _timer?.cancel();
  }
}
