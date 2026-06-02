import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/qr_service.dart';
import '../../providers/app_providers.dart';
import '../../../domain/entities/reservation.dart';
import 'reservation_form_screen.dart';

class ReservationDetailScreen extends ConsumerStatefulWidget {
  final Reservation reservation;

  const ReservationDetailScreen({
    super.key,
    required this.reservation,
  });

  @override
  ConsumerState<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState
    extends ConsumerState<ReservationDetailScreen> {
  final ScreenshotController _shot = ScreenshotController();

  late Reservation _reservation;

  bool get _hasCamping => _reservation.tents > 0;

  String get _packageName => _reservation.packageName;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    final fmt = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
    );

    final qrData = QRService.generateQRData(_reservation);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reserva ${_reservation.code}',
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'share') {
                _shareWhatsApp(
                  context,
                  _reservation,
                );
              }

              if (value == 'edit') {
                final updated = await Navigator.push<Reservation>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationFormScreen(
                      existing: _reservation,
                    ),
                  ),
                );

                if (updated != null && mounted) {
                  setState(() {
                    _reservation = updated;
                  });
                }
              }

              if (value == 'cancel') {
                await ref
                    .read(
                      reservationsProvider.notifier,
                    )
                    .cancelReservation(
                      _reservation.id,
                    );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }

              if (value == 'delete') {
                await ref
                    .read(
                      reservationsProvider.notifier,
                    )
                    .deleteReservation(
                      _reservation.id,
                    );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'share',
                child: Text(
                  'Compartir WhatsApp',
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Text(
                  'Editar reserva',
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Text(
                  'Cancelar reserva',
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Eliminar reserva',
                ),
              ),
            ],
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _detailColumn(
                    context,
                    fmt,
                  ),
                ),
                Expanded(
                  child: _qrColumn(
                    context,
                    qrData,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _qrSection(
                    context,
                    qrData,
                  ),
                  _detailSection(
                    context,
                    fmt,
                  ),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────

  Widget _detailColumn(
    BuildContext context,
    NumberFormat fmt,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _detailSection(
        context,
        fmt,
      ),
    );
  }

  Widget _detailSection(
    BuildContext context,
    NumberFormat fmt,
  ) {
    final r = _reservation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _StatusBadge(
                status: r.status,
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(
                  Icons.how_to_reg,
                ),
                label: const Text(
                  'Registrar ingreso',
                ),
                onPressed: () async {
                  await ref
                      .read(
                        reservationsProvider.notifier,
                      )
                      .checkIn(r.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ingreso registrado',
                        ),
                      ),
                    );

                    Navigator.pop(
                      context,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        _InfoCard(
          title: 'Cliente',
          icon: Icons.person,
          children: [
            _InfoRow(
              label: 'Nombre',
              value: r.customerName,
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 6,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 110,
                    child: Text(
                      'Teléfono',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.customerPhone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.phone,
                        size: 16,
                      ),
                      label: const Text(
                        'Llamar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final Uri uri = Uri.parse(
                          'tel:${r.customerPhone}',
                        );

                        await launchUrl(uri);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        _InfoCard(
          title: 'Visita',
          icon: Icons.calendar_today,
          children: [
            _InfoRow(
              label: 'Fecha',
              value: r.date,
            ),
            _InfoRow(
              label: 'Hora de llegada',
              value: r.timeSlot,
            ),
            _InfoRow(
              label: 'Personas',
              value: '${r.totalPeople}',
            ),
            _InfoRow(
              label: 'Paquete',
              value: _packageName,
            ),
            if (_hasCamping)
              _InfoRow(
                label: 'Casas de campaña',
                value: '${_reservation.tents} personas',
              ),
            if (r.isCheckedIn && r.checkedInBy != null)
              _InfoRow(
                label: 'Check-in hecho por',
                value: r.checkedInBy ?? 'N/A',
              ),
            if (r.checkedInAt != null)
              _InfoRow(
                label: 'Hora del check-in',
                value: DateFormat('HH:mm').format(r.checkedInAt!),
              ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        _InfoCard(
          title: 'Pago',
          icon: Icons.attach_money,
          children: [
            _InfoRow(
              label: 'Total',
              value: fmt.format(
                r.total,
              ),
            ),
            _InfoRow(
              label: 'Anticipo',
              value: fmt.format(
                r.deposit,
              ),
            ),
            _InfoRow(
              label: 'Saldo',
              value: fmt.format(
                r.balance,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 60,
        ),
      ],
    );
  }

  Widget _qrColumn(
    BuildContext context,
    String qrData,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _qrSection(
            context,
            qrData,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────

  Widget _qrSection(
    BuildContext context,
    String qrData,
  ) {
    final r = _reservation;

    return Column(
      children: [
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  r.code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 16),

                Screenshot(
                  controller: _shot,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  r.customerName,
                  textAlign: TextAlign.center,
                ),

                Text(
                  '${r.date} · ${r.timeSlot}',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                /// WhatsApp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'Enviar por WhatsApp',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _shareWhatsApp(
                      context,
                      r,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Enviar QR por WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _shareQrWhatsApp(context, r),
                  ),
                ),

                const SizedBox(height: 12),

                /// Mercado Pago
                if (r.balance > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: Text(
                        'Cobrar \$${r.balance.toStringAsFixed(2)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFFDB15,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _openMercadoPago(
                        context,
                        r,
                      ),
                    ),
                  ),

                if (r.balance > 0) const SizedBox(height: 12),

                /// Liquidado
                if (r.balance > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.check_circle,
                      ),
                      label: const Text(
                        'Marcar liquidado',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await ref
                            .read(
                              reservationsProvider.notifier,
                            )
                            .updateReservation(
                              r.copyWith(
                                deposit: r.total,
                                balance: 0,
                                status: ReservationStatus.confirmed,
                                updatedAt: DateTime.now(),
                              ),
                            );

                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Reserva liquidada',
                              ),
                            ),
                          );

                          final dateStr = ref.read(selectedDateStringProvider);

                          await ref
                              .read(reservationsProvider.notifier)
                              .loadByDate(dateStr);

                          ref.invalidate(dashboardStatsProvider);

                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────

  Future<void> _shareWhatsApp(
    BuildContext context,
    Reservation r,
  ) async {
    try {
      // Limpia el número: quita espacios, guiones, paréntesis
      final rawPhone = r.customerPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      // Agrega código de país si no lo tiene (ajusta 52 a tu país)
      final phone = rawPhone.startsWith('+')
          ? rawPhone.replaceFirst('+', '')
          : '52$rawPhone'; // México por defecto

      final text = Uri.encodeComponent(
        QRService.generateWhatsAppText(r),
      );

      final uri = Uri.parse('whatsapp://send?phone=$phone&text=$text');
      final webUri = Uri.parse('https://wa.me/$phone?text=$text');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        // Fallback: abre WhatsApp Web si la app no está instalada
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp no está disponible')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareQrWhatsApp(
    BuildContext context,
    Reservation r,
  ) async {
    try {
      final bytes = await _shot.capture();

      if (bytes == null) return;

      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/${r.code}_qr.png',
      );

      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [
          XFile(file.path),
        ],
        text: 'QR de tu reservación',
        sharePositionOrigin: const Rect.fromLTWH(
          0,
          0,
          1,
          1,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error QR: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openMercadoPago(
    BuildContext context,
    Reservation r,
  ) async {
    try {
      final amount = r.balance.toStringAsFixed(2);

      await Clipboard.setData(
        ClipboardData(text: amount),
      );

      // Opción 1: Usar AndroidIntent para control nativo
      if (Platform.isAndroid) {
        try {
          final AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'mercadopago://home',
            package: 'com.mercadopago.wallet',
          );
          await intent.launch();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Saldo \$${amount} copiado. Abriendo Mercado Pago...',
                ),
              ),
            );
          }
          return;
        } catch (e) {
          // Si falla con AndroidIntent, intenta con deep link directo
          final Uri appUri = Uri.parse('mercadopago://home');
          if (await canLaunchUrl(appUri)) {
            await launchUrl(
              appUri,
              mode: LaunchMode.externalApplication,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Saldo \$${amount} copiado. Abriendo Mercado Pago...',
                  ),
                ),
              );
            }
            return;
          }
        }
      }

      // Opción 2: Fallback a Play Store si la app no está
      final Uri playStoreUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.mercadopago.wallet',
      );

      await launchUrl(
        playStoreUri,
        mode: LaunchMode.externalApplication,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mercado Pago no está instalado. Abriendo Play Store para descargarlo.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ReservationStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.label,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
