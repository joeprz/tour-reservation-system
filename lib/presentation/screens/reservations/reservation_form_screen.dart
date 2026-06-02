// lib/presentation/screens/reservations/reservation_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/reservation.dart';
import 'reservation_detail_screen.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  final Reservation? existing;

  const ReservationFormScreen({
    super.key,
    this.existing,
  });

  @override
  ConsumerState<ReservationFormScreen> createState() =>
      _ReservationFormScreenState();
}

class _ReservationFormScreenState extends ConsumerState<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  late final TextEditingController _adultsCtrl;
  late final TextEditingController _childrenCtrl;

  late final TextEditingController _adultPriceCtrl;
  late final TextEditingController _childPriceCtrl;

  late final TextEditingController _depositCtrl;
  late final TextEditingController _notesCtrl;

  DateTime _selectedDate = DateTime.now();

  bool _loading = false;
  bool _pricesLoaded = false;

  String _packageType = 'basic';

  int _tents = 0;

  double _total = 0;
  double _balance = 0;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    _adultsCtrl = TextEditingController(text: '1');
    _childrenCtrl = TextEditingController(text: '0');

    _adultPriceCtrl = TextEditingController();
    _childPriceCtrl = TextEditingController();

    _depositCtrl = TextEditingController(text: '0');
    _notesCtrl = TextEditingController();

    if (widget.existing != null) {
      final existing = widget.existing!;
      _nameCtrl.text = existing.customerName;
      _phoneCtrl.text = existing.customerPhone;
      _adultsCtrl.text = existing.adults.toString();
      _childrenCtrl.text = existing.children.toString();
      _adultPriceCtrl.text = existing.adultPrice.toStringAsFixed(0);
      _childPriceCtrl.text = existing.childPrice.toStringAsFixed(0);
      _depositCtrl.text = existing.deposit.toStringAsFixed(0);
      _notesCtrl.text = existing.notes ?? '';
      _selectedDate = DateTime.tryParse(existing.date) ?? DateTime.now();
      _packageType = existing.packageType;
      _tents = existing.tents;
      _pricesLoaded = true;
    }

    _adultsCtrl.addListener(_recalculate);
    _childrenCtrl.addListener(_recalculate);
    _adultPriceCtrl.addListener(_recalculate);
    _childPriceCtrl.addListener(_recalculate);
    _depositCtrl.addListener(_recalculate);

    _recalculate();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _adultsCtrl.dispose();
    _childrenCtrl.dispose();
    _adultPriceCtrl.dispose();
    _childPriceCtrl.dispose();
    _depositCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _hasCamping =>
      _packageType == 'camping' || _packageType == 'premium';

  String get _packageName {
    switch (_packageType) {
      case 'camping':
        return 'PAQUETE CAMPING';
      case 'premium':
        return 'EXPERIENCE PREMIUM';
      default:
        return 'PAQUETE BÁSICO';
    }
  }

  void _loadPrices(dynamic settings) {
    if (settings == null) return;

    switch (_packageType) {
      case 'camping':
        _adultPriceCtrl.text = settings.campingAdultPrice.toStringAsFixed(0);
        _childPriceCtrl.text = settings.campingChildPrice.toStringAsFixed(0);
        break;

      case 'premium':
        _adultPriceCtrl.text = settings.premiumAdultPrice.toStringAsFixed(0);
        _childPriceCtrl.text = settings.premiumChildPrice.toStringAsFixed(0);
        break;

      default:
        _adultPriceCtrl.text = settings.basicAdultPrice.toStringAsFixed(0);
        _childPriceCtrl.text = settings.basicChildPrice.toStringAsFixed(0);
    }

    _recalculate();
  }

  void _recalculate() {
    final adults = int.tryParse(_adultsCtrl.text) ?? 0;
    final children = int.tryParse(_childrenCtrl.text) ?? 0;
    final adultPrice = double.tryParse(_adultPriceCtrl.text) ?? 0;
    final childPrice = double.tryParse(_childPriceCtrl.text) ?? 0;
    final deposit = double.tryParse(_depositCtrl.text) ?? 0;

    double subtotal = (adults * adultPrice) + (children * childPrice);

    if (_hasCamping && _tents > 0) {
      final settings = ref.read(settingsProvider).value;
      if (settings != null) {
        double tentPrice = 0;
        switch (_tents) {
          case 2:
            tentPrice = settings.tent2PersonPrice;
            break;
          case 4:
            tentPrice = settings.tent4PersonPrice;
            break;
          case 6:
            tentPrice = settings.tent6PersonPrice;
            break;
          case 10:
            tentPrice = settings.tent10PersonPrice;
            break;
        }
        subtotal += tentPrice;
      }
    }

    setState(() {
      _total = subtotal;
      _balance = subtotal - deposit;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      if (widget.existing == null) {
        final reservation = await ref
            .read(
              reservationsProvider.notifier,
            )
            .createReservation(
              customerName: _nameCtrl.text.trim(),
              customerPhone: _phoneCtrl.text.trim(),
              date: DateFormat(
                'yyyy-MM-dd',
              ).format(
                _selectedDate,
              ),
              timeSlot: '5:00PM',
              adults: int.parse(
                _adultsCtrl.text,
              ),
              children: int.parse(
                _childrenCtrl.text,
              ),
              adultPrice: double.parse(
                _adultPriceCtrl.text,
              ),
              childPrice: double.parse(
                _childPriceCtrl.text,
              ),
              deposit: double.tryParse(
                    _depositCtrl.text,
                  ) ??
                  0,
              packageType: _packageType,
              packageName: _packageName,
              tents: _hasCamping ? _tents : 0,
              notes: _notesCtrl.text.trim(),
            );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReservationDetailScreen(
              reservation: reservation,
            ),
          ),
        );
      } else {
        final existing = widget.existing!;
        final updated = existing.copyWith(
          customerName: _nameCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          adults: int.parse(_adultsCtrl.text),
          children: int.parse(_childrenCtrl.text),
          adultPrice: double.parse(_adultPriceCtrl.text),
          childPrice: double.parse(_childPriceCtrl.text),
          total: _total,
          deposit: double.tryParse(_depositCtrl.text) ?? 0,
          balance: _balance,
          packageType: _packageType,
          packageName: _packageName,
          tents: _hasCamping ? _tents : 0,
          notes: _notesCtrl.text.trim(),
        );

        await ref
            .read(
              reservationsProvider.notifier,
            )
            .updateReservation(updated);

        if (!mounted) return;

        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref
        .watch(
          settingsProvider,
        )
        .value;

    if (settings != null && !_pricesLoaded && widget.existing == null) {
      _pricesLoaded = true;
      _loadPrices(settings);
    }

    final fmt = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
    );

    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Nueva Reservación' : 'Editar Reservación',
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(
                right: 8,
              ),
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(
                  Icons.save,
                ),
                label: const Text(
                  'Guardar',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldenFirefly,
                  foregroundColor: AppTheme.deepForest,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _leftColumn(),
                  ),
                  Expanded(
                    flex: 2,
                    child: _rightColumn(
                      fmt,
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  children: [
                    _customerSection(),
                    const SizedBox(height: 16),
                    _dateSection(),
                    const SizedBox(height: 16),
                    _peopleSection(),
                    const SizedBox(height: 16),
                    _pricingSection(
                      fmt,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _leftColumn() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        20,
      ),
      child: Column(
        children: [
          _customerSection(),
          const SizedBox(height: 16),
          _dateSection(),
          const SizedBox(height: 16),
          _peopleSection(),
        ],
      ),
    );
  }

  Widget _rightColumn(
    NumberFormat fmt,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          20,
        ),
        child: _pricingSection(
          fmt,
        ),
      ),
    );
  }

  Widget _customerSection() {
    return _FormSection(
      title: 'Datos del Cliente',
      icon: Icons.person,
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre completo *',
            prefixIcon: Icon(Icons.badge),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Teléfono *',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _dateSection() {
    return _FormSection(
      title: 'Fecha y Paquete',
      icon: Icons.calendar_today,
      children: [
        InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.event),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE d MMMM yyyy', 'es_MX')
                        .format(_selectedDate),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _packageType,
          decoration: const InputDecoration(
            labelText: 'Paquete',
            prefixIcon: Icon(Icons.inventory),
          ),
          items: const [
            DropdownMenuItem(value: 'basic', child: Text('PAQUETE BÁSICO')),
            DropdownMenuItem(value: 'camping', child: Text('PAQUETE CAMPING')),
            DropdownMenuItem(
                value: 'premium', child: Text('EXPERIENCE PREMIUM')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _packageType = v);
            final s = ref.read(settingsProvider).value;
            _loadPrices(s);
          },
        ),
        if (_hasCamping) const SizedBox(height: 14),
        if (_hasCamping)
          DropdownButtonFormField<int?>(
            value: _tents > 0 ? _tents : null,
            decoration: const InputDecoration(
              labelText: 'Casas de campaña (opcional)',
              prefixIcon: Icon(Icons.cabin),
              hintText: 'Selecciona una opción',
            ),
            items: _buildTentOptions(),
            onChanged: (v) {
              setState(() => _tents = v ?? 0);
              _recalculate();
            },
            isExpanded: true,
          ),
      ],
    );
  }

  List<DropdownMenuItem<int?>> _buildTentOptions() {
    final settings = ref.read(settingsProvider).value;

    if (settings == null) {
      return [];
    }

    return [
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Sin casa de campaña'),
      ),
      DropdownMenuItem<int?>(
        value: 2,
        child: Text(
          '2 personas - \$${settings.tent2PersonPrice.toStringAsFixed(0)}',
        ),
      ),
      DropdownMenuItem<int?>(
        value: 4,
        child: Text(
          '4 personas - \$${settings.tent4PersonPrice.toStringAsFixed(0)}',
        ),
      ),
      DropdownMenuItem<int?>(
        value: 6,
        child: Text(
          '6 personas - \$${settings.tent6PersonPrice.toStringAsFixed(0)}',
        ),
      ),
      DropdownMenuItem<int?>(
        value: 10,
        child: Text(
          '10 personas - \$${settings.tent10PersonPrice.toStringAsFixed(0)}',
        ),
      ),
    ];
  }

  Widget _peopleSection() {
    return _FormSection(
      title: 'Personas',
      icon: Icons.group,
      children: [
        Row(
          children: [
            Expanded(
              child: _CounterField(
                label: 'Adultos',
                controller: _adultsCtrl,
                min: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CounterField(
                label: 'Niños',
                controller: _childrenCtrl,
                min: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notas',
            prefixIcon: Icon(Icons.notes),
          ),
        ),
      ],
    );
  }

  Widget _pricingSection(
    NumberFormat fmt,
  ) {
    return _FormSection(
      title: 'Cobro',
      icon: Icons.attach_money,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _adultPriceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adulto',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[\d.]'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _childPriceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Niño',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[\d.]'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _depositCtrl,
          decoration: const InputDecoration(
            labelText: 'Anticipo',
            prefixText: '\$',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[\d.]'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.forestGreen.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _TotalRow(
                label: 'Paquete',
                value: _packageName,
              ),
              const Divider(),
              if (_hasCamping && _tents > 0) ...[
                _TotalRow(
                  label: 'Casas ($_tents personas)',
                  value: () {
                    final settings = ref.read(settingsProvider).value;
                    if (settings == null) return '\$0';

                    double price = 0;
                    switch (_tents) {
                      case 2:
                        price = settings.tent2PersonPrice;
                        break;
                      case 4:
                        price = settings.tent4PersonPrice;
                        break;
                      case 6:
                        price = settings.tent6PersonPrice;
                        break;
                      case 10:
                        price = settings.tent10PersonPrice;
                        break;
                    }
                    return fmt.format(price);
                  }(),
                ),
                const Divider(),
              ],
              _TotalRow(
                label: 'TOTAL',
                value: fmt.format(_total),
                bold: true,
                valueColor: AppTheme.forestGreen,
              ),
              const SizedBox(height: 4),
              _TotalRow(
                label: 'Anticipo',
                value:
                    '- ${fmt.format(double.tryParse(_depositCtrl.text) ?? 0)}',
              ),
              const SizedBox(height: 4),
              _TotalRow(
                label: 'Saldo',
                value: fmt.format(_balance < 0 ? 0 : _balance),
                bold: true,
                valueColor: _balance > 0
                    ? AppTheme.statusPending
                    : AppTheme.statusCheckedIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.forestGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CounterField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final int min;

  const _CounterField({
    required this.label,
    required this.controller,
    required this.min,
  });

  @override
  State<_CounterField> createState() => _CounterFieldState();
}

class _CounterFieldState extends State<_CounterField> {
  int get _value =>
      int.tryParse(
        widget.controller.text,
      ) ??
      widget.min;

  void _inc() {
    widget.controller.text = (_value + 1).toString();
    setState(() {});
  }

  void _dec() {
    if (_value > widget.min) {
      widget.controller.text = (_value - 1).toString();
      setState(() {});
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
            ),
            child: Text(
              widget.label,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _dec,
                icon: const Icon(
                  Icons.remove,
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (_, value, __) {
                      final current = int.tryParse(value.text) ?? widget.min;

                      return Text(
                        '$current',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: _inc,
                icon: const Icon(
                  Icons.add,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
