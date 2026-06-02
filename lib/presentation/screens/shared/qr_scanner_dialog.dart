// lib/presentation/screens/shared/qr_scanner_dialog.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/utils/qr_service.dart';

enum QRScannerResult { success, error, cancelled }

class QRScannerDialog extends StatefulWidget {
  final Function(String token, String id, String code)? onScanned;
  final Function(QRScannerResult result, String? error)? onResult;

  const QRScannerDialog({
    super.key,
    this.onScanned,
    this.onResult,
  });

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _torchOn = false;
  bool _scanning = true;
  String? _errorMsg;

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (!_scanning) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;

    setState(() => _scanning = false);
    await _scanCtrl.stop();

    // Parse QR
    final parsed = QRService.parseQRData(rawValue);
    
    if (parsed == null) {
      setState(() {
        _errorMsg = 'Código QR inválido.\nEste código no pertenece a Luciérnagas Control.';
      });
      widget.onResult?.call(QRScannerResult.error, _errorMsg);
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      }
      return;
    }

    // Success
    widget.onScanned?.call(
      parsed['token']!,
      parsed['id']!,
      parsed['code']!,
    );
    widget.onResult?.call(QRScannerResult.success, null);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _scanCtrl,
            onDetect: _handleBarcode,
          ),

          // Custom overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Escanear código QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      widget.onResult?.call(QRScannerResult.cancelled, null);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _torchOn ? Icons.flashlight_off : Icons.flashlight_on,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _scanCtrl.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                  Text(
                    'Apunta al código QR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Error overlay
          if (_errorMsg != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMsg!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanSize = 220.0;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final rect = Rect.fromLTWH(left, top, scanSize, scanSize);

    final dimPaint = Paint()..color = Colors.black54;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      dimPaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLen = 32.0;
    // Top-left
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(left + scanSize - cornerLen, top), Offset(left + scanSize, top), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top), Offset(left + scanSize, top + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, top + scanSize - cornerLen), Offset(left, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanSize), Offset(left + cornerLen, top + scanSize), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(left + scanSize - cornerLen, top + scanSize), Offset(left + scanSize, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top + scanSize - cornerLen), Offset(left + scanSize, top + scanSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}