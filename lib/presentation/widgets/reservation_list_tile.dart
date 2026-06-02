// lib/presentation/widgets/reservation_list_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../screens/reservations/reservation_detail_screen.dart';
import '../../domain/entities/reservation.dart';

class ReservationListTile extends StatelessWidget {
  final Reservation reservation;

  const ReservationListTile({super.key, required this.reservation});

  String get _packageShort {
    switch (reservation.packageType) {
      case 'camping':
        return 'CAMPING';
      case 'premium':
        return 'PREMIUM';
      default:
        return 'BÁSICO';
    }
  }

  String get _tentSizeLabel {
    if (reservation.tents <= 0) return '';
    return '${reservation.tents} personas';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final statusColor = AppTheme.statusColor(reservation.status.value);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReservationDetailScreen(reservation: reservation),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Left: status indicator + icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _statusIcon(reservation.status),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Center: name, details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
  children: [
    Expanded(
      child: Text(
        reservation.code,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    ),

    const SizedBox(width: 8),

    Flexible(
      child: _StatusChip(
        status: reservation.status,
      ),
    ),
  ],
),
                    const SizedBox(height: 2),
                    Text(
  reservation.customerName,
  style: const TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w700,
    fontSize: 15,
  ),
),

const SizedBox(height: 4),

Wrap(
  spacing: 6,
  runSpacing: 4,
  children: [
    _MiniBadge(
      text: _packageShort,
      color: Colors.deepPurple,
    ),

    if (_tentSizeLabel.isNotEmpty)
      _MiniBadge(
        text: 'Tienda ${_tentSizeLabel}',
        color: Colors.teal,
      ),

    if (reservation.status ==
        ReservationStatus.checkedIn)
      _MiniBadge(
        text: 'INGRESÓ',
        color: Colors.green,
      ),

    if (reservation.balance > 0)
      _MiniBadge(
        text: 'DEBE',
        color: Colors.red,
      ),
  ],
),

const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          reservation.timeSlot,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.people, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${reservation.adults}A ${reservation.children}N',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: financial info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(reservation.total),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (reservation.balance > 0)
                    Text(
                      'Saldo: ${fmt.format(reservation.balance)}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppTheme.statusPending,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Text(
                      'Pagado ✓',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppTheme.statusCheckedIn,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending: return Icons.hourglass_empty;
      case ReservationStatus.confirmed: return Icons.check_circle_outline;
      case ReservationStatus.checkedIn: return Icons.how_to_reg;
      case ReservationStatus.cancelled: return Icons.cancel_outlined;
      case ReservationStatus.noShow: return Icons.person_off;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final ReservationStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status.value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}