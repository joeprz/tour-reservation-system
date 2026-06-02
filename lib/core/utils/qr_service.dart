// lib/core/utils/qr_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/reservation.dart';

class QRService {
  /// ─────────────────────────────────────────────
  /// GENERAR TEXTO QR
  /// ─────────────────────────────────────────────
  static String generateQRData(
    Reservation reservation,
  ) {
    final payload = {
      'prefix':
          AppConstants.qrPrefix,
      'id': reservation.id,
      'token':
          reservation.token,
      'code': reservation.code,
    };

    return base64Url.encode(
      utf8.encode(
        jsonEncode(payload),
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// LEER QR
  /// ─────────────────────────────────────────────
  static Map<String, String>?
      parseQRData(
    String rawData,
  ) {
    try {
      final decoded =
          utf8.decode(
        base64Url.decode(
          rawData,
        ),
      );

      final map = jsonDecode(
        decoded,
      ) as Map<String, dynamic>;

      if (map['prefix'] !=
          AppConstants.qrPrefix) {
        return null;
      }

      return {
        'id':
            map['id'] as String,
        'token':
            map['token']
                as String,
        'code':
            map['code']
                as String,
      };
    } catch (_) {
      return null;
    }
  }

  /// ─────────────────────────────────────────────
  /// TEXTO WHATSAPP MEJORADO
  /// ─────────────────────────────────────────────
  static String
      generateWhatsAppText(
    Reservation r,
  ) {
    final notes =
        r.notes ?? '';

    final hasCamping =
        notes.contains(
      'Camping:SI',
    );

    String extract(
      String key,
    ) {
      final line =
          notes
              .split('\n')
              .firstWhere(
                (e) =>
                    e.startsWith(
                  key,
                ),
                orElse:
                    () => '',
              );

      return line
          .replaceFirst(
        key,
        '',
      )
          .trim();
    }

    final nights =
        extract(
      'Noches:',
    );

    final tents =
        extract(
      'Casas:',
    );

    final campingExtra =
        extract(
      'CampingExtra:',
    );

    final tentExtra =
        extract(
      'CasaExtra:',
    );

    return '''
✨ *Tour de Luciérnagas - ${AppConstants.businessName}* ✨

📋 *Folio:* ${r.code}
👤 *Cliente:* ${r.customerName}
📞 *Teléfono:* ${r.customerPhone}

📅 *Fecha:* ${r.date}
⏰ *Horario:* ${r.timeSlot}

👥 *Visitantes:* ${r.totalPeople}
👨 Adultos: ${r.adults}
👦 Niños: ${r.children}

${hasCamping ? '''
🏕 *Camping:* Sí
🌙 Noches: $nights
⛺ Casas: $tents
💵 Extra camping: \$${campingExtra} MXN
💵 Casas campaña: \$${tentExtra} MXN

''' : ''}💰 *Total:* \$${r.total.toStringAsFixed(2)} MXN
💵 *Anticipo:* \$${r.deposit.toStringAsFixed(2)} MXN
🔄 *Saldo pendiente:* \$${r.balance.toStringAsFixed(2)} MXN

Presenta el código QR adjunto al ingresar 🌿

¡Te esperamos!
''';
  }

  /// ─────────────────────────────────────────────
  /// COMPARTIR QR + TEXTO
  /// ─────────────────────────────────────────────
  static Future<void>
      shareReservationQR(
    Reservation r,
  ) async {
    final qrData =
        generateQRData(r);

    final painter =
        QrPainter(
      data: qrData,
      version:
          QrVersions.auto,
      gapless: true,
    );

    final imageData =
        await painter
            .toImageData(
      900,
    );

    if (imageData == null) {
      return;
    }

    final Uint8List bytes =
        imageData.buffer
            .asUint8List();

    final dir =
        await getTemporaryDirectory();

    final file = File(
      '${dir.path}/${r.code}_qr.png',
    );

    await file.writeAsBytes(
      bytes,
    );

    await Share.shareXFiles(
      [
        XFile(
          file.path,
        ),
      ],
      text:
          generateWhatsAppText(
        r,
      ),
    );
  }
}