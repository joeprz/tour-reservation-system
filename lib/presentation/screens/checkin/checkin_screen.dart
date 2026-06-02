// lib/presentation/screens/checkin/checkin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/qr_service.dart';
import '../../../domain/entities/reservation.dart';
import '../settings/settings_screen.dart';

enum _ScanState { scanning, loading, success, error, duplicate }

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final MobileScannerController _scanCtrl = MobileScannerController();
  _ScanState _state = _ScanState.scanning;
  Reservation? _scannedReservation;
  String? _errorMsg;
  String? _admittedBy;
  bool _torchOn = false;
  DateTime? _lastScan;

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    // Debounce: ignore scans within 3 seconds of the last one
    final now = DateTime.now();
    if (_lastScan != null &&
        now.difference(_lastScan!) < const Duration(seconds: 3)) return;
    if (_state != _ScanState.scanning) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;

    _lastScan = now;
    await _scanCtrl.stop();
    setState(() => _state = _ScanState.loading);

    // Parse QR
    final parsed = QRService.parseQRData(rawValue);
    if (parsed == null) {
      setState(() {
        _state = _ScanState.error;
        _errorMsg =
            'Código QR inválido.\nEste código no pertenece a Luciérnagas Control.';
      });
      return;
    }

    final repo = ref.read(reservationRepositoryProvider);
    final reservation = await repo.getReservationByToken(
      parsed['token']!,
    );

    if (reservation == null) {
      setState(() {
        _state = _ScanState.error;
        _errorMsg = 'Reservación no encontrada.';
      });

      return;
    }

    if (reservation.isCheckedIn) {
      setState(() {
        _state = _ScanState.duplicate;

        _scannedReservation = reservation;

        _errorMsg = 'Esta persona ya ingresó.';
      });

      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(AppConstants.keyDeviceRole);
    final currentScanner = prefs.getString(AppConstants.keyScannerName);

// Determinar si es admin o scanner
    final isAdmin = roleStr == 'reception';
    final admittedName = isAdmin
        ? 'admin'
        : (currentScanner?.trim().isNotEmpty == true
            ? currentScanner!.trim()
            : 'Usuario');

    await ref
        .read(
          reservationsProvider.notifier,
        )
        .checkIn(reservation.id, checkedInBy: admittedName);

    final updated = await repo.getReservationById(
      reservation.id,
    );

    setState(() {
      _state = _ScanState.success;
      _scannedReservation = updated;
      _admittedBy = admittedName;
    });
  }

  Future<void> _resetScan() async {
    setState(() {
      _state = _ScanState.scanning;
      _scannedReservation = null;
      _errorMsg = null;
      _admittedBy = null;
      _lastScan = null; // resetear debounce
    });
    await _scanCtrl.start(); // el widget ya está montado, esto funciona
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Control de Acceso',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flashlight_off : Icons.flashlight_on,
                color: Colors.white),
            onPressed: () {
              _scanCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Siempre montado, nunca sale del árbol
          MobileScanner(
            controller: _scanCtrl,
            onDetect: _handleBarcode,
          ),

          if (_state == _ScanState.scanning) _ScanOverlay(),

          if (_state == _ScanState.loading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Verificando...',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontSize: 18)),
                ],
              ),
            ),

          if (_state == _ScanState.success && _scannedReservation != null)
            _SuccessPanel(
              reservation: _scannedReservation!,
              onContinue: _resetScan,
              admittedBy: _admittedBy,
            ),

          if (_state == _ScanState.error)
            _ErrorPanel(
                message: _errorMsg ?? 'Error desconocido', onRetry: _resetScan),

          if (_state == _ScanState.duplicate && _scannedReservation != null)
            _DuplicatePanel(
                reservation: _scannedReservation!,
                message: _errorMsg ?? 'Ya ingresó',
                onContinue: _resetScan),

          if (_state == _ScanState.scanning)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: const Text(
                'Apunta la cámara al código QR de la reservación',
                style: TextStyle(
                    color: Colors.white70, fontFamily: 'Nunito', fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Scan Overlay ──────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.7;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final rect = Rect.fromLTWH(left, top, scanSize, scanSize);

    final dimPaint = Paint()..color = Colors.black54;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      dimPaint,
    );

    final cornerPaint = Paint()
      ..color = AppTheme.goldenFirefly
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLen = 32.0;
    // Top-left
    canvas.drawLine(
        Offset(left, top + cornerLen), Offset(left, top), cornerPaint);
    canvas.drawLine(
        Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(left + scanSize - cornerLen, top),
        Offset(left + scanSize, top), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top),
        Offset(left + scanSize, top + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, top + scanSize - cornerLen),
        Offset(left, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanSize),
        Offset(left + cornerLen, top + scanSize), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(left + scanSize - cornerLen, top + scanSize),
        Offset(left + scanSize, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top + scanSize - cornerLen),
        Offset(left + scanSize, top + scanSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Result Panels ─────────────────────────────────────────────────────────

class _SuccessPanel extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onContinue;
  final String? admittedBy;

  const _SuccessPanel({
    required this.reservation,
    required this.onContinue,
    this.admittedBy,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppTheme.statusCheckedIn,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡ACCESO PERMITIDO!',
                  style: TextStyle(
                    color: AppTheme.statusCheckedIn,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ResultRow(
                          icon: Icons.badge,
                          label: reservation.code,
                          large: true),
                      const Divider(color: Colors.white24, height: 24),
                      _ResultRow(
                          icon: Icons.person, label: reservation.customerName),
                      const SizedBox(height: 8),
                      _ResultRow(
                          icon: Icons.phone, label: reservation.customerPhone),
                      const SizedBox(height: 8),
                      _ResultRow(
                          icon: Icons.schedule, label: reservation.timeSlot),
                      const SizedBox(height: 8),
                      _ResultRow(
                        icon: Icons.people,
                        label:
                            '${reservation.adults} adultos · ${reservation.children} niños',
                      ),
                      if (reservation.tents > 0) ...[
                        const SizedBox(height: 8),
                        _ResultRow(
                          icon: Icons.cabin,
                          label:
                              'Casas de campaña: ${reservation.tents} personas',
                        ),
                      ],
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        children: [
                          const Icon(Icons.payments,
                              color: Colors.white60, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Saldo: ${fmt.format(reservation.balance)}',
                            style: TextStyle(
                              color: reservation.balance > 0
                                  ? AppTheme.statusPending
                                  : AppTheme.statusCheckedIn,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (reservation.balance > 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: AppTheme.statusPending, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '⚠️ Cobrar saldo al ingresar',
                                style: TextStyle(
                                  color: AppTheme.statusPending,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (admittedBy != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.person_pin,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                admittedBy == 'admin'
                                    ? 'Admitido por admin'
                                    : 'Admitido por $admittedBy',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear siguiente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusCheckedIn,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppTheme.statusCancelled,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ACCESO DENEGADO',
                  style: TextStyle(
                    color: AppTheme.statusCancelled,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Nunito',
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Intentar de nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onRetry,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DuplicatePanel extends StatelessWidget {
  final Reservation reservation;
  final String message;
  final VoidCallback onContinue;

  const _DuplicatePanel({
    required this.reservation,
    required this.message,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppTheme.statusPending,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.warning, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DUPLICADO',
                  style: TextStyle(
                    color: AppTheme.statusPending,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Nunito',
                      fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                if (reservation.checkedInAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ingreso registrado: ${DateFormat('dd/MM/yyyy HH:mm').format(reservation.checkedInAt!)}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Nunito',
                        fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _ResultRow(icon: Icons.badge, label: reservation.code),
                      const SizedBox(height: 6),
                      _ResultRow(
                          icon: Icons.person, label: reservation.customerName),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Continuar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool large;

  const _ResultRow(
      {required this.icon, required this.label, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: large ? 22 : 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
              fontWeight: large ? FontWeight.w700 : FontWeight.w500,
              fontSize: large ? 18 : 15,
            ),
          ),
        ),
      ],
    );
  }
}
