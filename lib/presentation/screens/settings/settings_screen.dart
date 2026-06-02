// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../auth/role_selection_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return _PinLockScreen(
        onUnlocked: () => setState(() => _unlocked = true),
      );
    }
    return const _SettingsContent();
  }
}

// ─── PIN Lock ───────────────────────────────────────────────────────────────

class _PinLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const _PinLockScreen({required this.onUnlocked});

  @override
  ConsumerState<_PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<_PinLockScreen> {
  final _pinCtrl = TextEditingController();
  String? _error;

  Future<void> _verify() async {
    final repo = ref.read(settingsRepositoryProvider);
    final valid = await repo.verifyPin(_pinCtrl.text);
    if (valid) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'PIN incorrecto';
        _pinCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 360,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: AppTheme.forestGreen,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingresa el PIN de administrador',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    maxLength: 8,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 8,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                    onSubmitted: (_) => _verify(),
                    decoration: InputDecoration(
                      errorText: _error,
                      hintText: '••••',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _verify,
                      child: const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MANEJO POR ADMIN',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Settings Content ────────────────────────────────────────────────────────

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent();

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  Widget _priceRow(
    String title,
    TextEditingController adult,
    TextEditingController child,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          Expanded(
            child: TextFormField(
              controller: adult,
              decoration: const InputDecoration(
                labelText: 'Adulto',
                prefixText: '\$',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: child,
              decoration: const InputDecoration(
                labelText: 'Niño',
                prefixText: '\$',
              ),
            ),
          ),
        ],
      ),
    );
  }

  final _basicAdultCtrl = TextEditingController();
  final _basicChildCtrl = TextEditingController();

  final _campingAdultCtrl = TextEditingController();
  final _campingChildCtrl = TextEditingController();

  final _premiumAdultCtrl = TextEditingController();
  final _premiumChildCtrl = TextEditingController();

  final _tent2PersonCtrl = TextEditingController();
  final _tent4PersonCtrl = TextEditingController();
  final _tent6PersonCtrl = TextEditingController();
  final _tent10PersonCtrl = TextEditingController();

  final _businessNameCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();

    // 🔹 Cargar inmediatamente si ya existe
    final current = ref.read(settingsProvider).value;
    if (current != null) {
      _setControllers(current);
    }

    // 🔹 Escuchar cambios futuros
    ref.listenManual(settingsProvider, (prev, next) {
      next.whenData((settings) {
        _setControllers(settings);
      });
    });
  }

  void _setControllers(AppSettings settings) {
    _basicAdultCtrl.text = settings.basicAdultPrice.toStringAsFixed(0);

    _basicChildCtrl.text = settings.basicChildPrice.toStringAsFixed(0);

    _campingAdultCtrl.text = settings.campingAdultPrice.toStringAsFixed(0);

    _campingChildCtrl.text = settings.campingChildPrice.toStringAsFixed(0);

    _premiumAdultCtrl.text = settings.premiumAdultPrice.toStringAsFixed(0);

    _premiumChildCtrl.text = settings.premiumChildPrice.toStringAsFixed(0);

    _tent2PersonCtrl.text = settings.tent2PersonPrice.toStringAsFixed(0);

    _tent4PersonCtrl.text = settings.tent4PersonPrice.toStringAsFixed(0);

    _tent6PersonCtrl.text = settings.tent6PersonPrice.toStringAsFixed(0);

    _tent10PersonCtrl.text = settings.tent10PersonPrice.toStringAsFixed(0);

    _businessNameCtrl.text = settings.businessName;
  }

  Future<void> _saveSettings() async {
    final current = ref.read(settingsProvider).value;

    if (current == null) return;

    final updated = current.copyWith(
      basicAdultPrice: double.tryParse(
            _basicAdultCtrl.text,
          ) ??
          current.basicAdultPrice,
      basicChildPrice: double.tryParse(
            _basicChildCtrl.text,
          ) ??
          current.basicChildPrice,
      campingAdultPrice: double.tryParse(
            _campingAdultCtrl.text,
          ) ??
          current.campingAdultPrice,
      campingChildPrice: double.tryParse(
            _campingChildCtrl.text,
          ) ??
          current.campingChildPrice,
      premiumAdultPrice: double.tryParse(
            _premiumAdultCtrl.text,
          ) ??
          current.premiumAdultPrice,
      premiumChildPrice: double.tryParse(
            _premiumChildCtrl.text,
          ) ??
          current.premiumChildPrice,
      tent2PersonPrice: double.tryParse(
            _tent2PersonCtrl.text,
          ) ??
          current.tent2PersonPrice,
      tent4PersonPrice: double.tryParse(
            _tent4PersonCtrl.text,
          ) ??
          current.tent4PersonPrice,
      tent6PersonPrice: double.tryParse(
            _tent6PersonCtrl.text,
          ) ??
          current.tent6PersonPrice,
      tent10PersonPrice: double.tryParse(
            _tent10PersonCtrl.text,
          ) ??
          current.tent10PersonPrice,
      businessName: _businessNameCtrl.text.trim(),
    );

    await ref.read(settingsProvider.notifier).update(updated);

    ref.invalidate(settingsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuración guardada'),
        ),
      );
    }
  }

  Future<void> _savePin() async {
    if (_newPinCtrl.text.length < 4) {
      _showError('El PIN debe tener al menos 4 dígitos');
      return;
    }
    if (_newPinCtrl.text != _confirmPinCtrl.text) {
      _showError('Los PINs no coinciden');
      return;
    }
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updatePin(_newPinCtrl.text);
    _newPinCtrl.clear();
    _confirmPinCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ PIN actualizado'),
            backgroundColor: AppTheme.statusCheckedIn),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceRole = ref.watch(deviceRoleNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.goldenFirefly,
                foregroundColor: AppTheme.deepForest,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Precios
          _SettingsSection(
            title: 'Precios',
            icon: Icons.attach_money,
            children: [
              _priceRow(
                'Básico',
                _basicAdultCtrl,
                _basicChildCtrl,
              ),
              _priceRow(
                'Camping',
                _campingAdultCtrl,
                _campingChildCtrl,
              ),
              _priceRow(
                'Premium',
                _premiumAdultCtrl,
                _premiumChildCtrl,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nombre del negocio
          _SettingsSection(
            title: 'Negocio',
            icon: Icons.business,
            children: [
              TextFormField(
                controller: _businessNameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre del negocio'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cambiar rol
          _SettingsSection(
            title: 'Modo del dispositivo',
            icon: Icons.devices,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceRole == AppRole.reception
                              ? 'Recepción (Tableta)'
                              : 'Acceso (Teléfono)',
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'Toca para cambiar el modo',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(deviceRoleNotifierProvider.notifier)
                          .clearRole();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const RoleSelectionScreen()),
                          (_) => false,
                        );
                      }
                    },
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Apariencia
          _SettingsSection(
            title: 'Apariencia',
            icon: Icons.dark_mode,
            children: [
              SwitchListTile(
                value: themeMode == ThemeMode.dark,
                onChanged: (_) async {
                  await ref.read(themeModeProvider.notifier).toggle();
                },
                title: const Text('Modo oscuro'),
                subtitle: const Text('Fondo oscuro en toda la aplicación'),
                activeColor: AppTheme.goldenFirefly,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Precios de casas de campaña
          _SettingsSection(
            title: 'Precios de Casas de Campaña',
            icon: Icons.cabin,
            children: [
              Text(
                'Precio según número de personas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CabinPriceField(
                      label: '2 personas',
                      controller: _tent2PersonCtrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CabinPriceField(
                      label: '4 personas',
                      controller: _tent4PersonCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CabinPriceField(
                      label: '6 personas',
                      controller: _tent6PersonCtrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CabinPriceField(
                      label: '10 personas',
                      controller: _tent10PersonCtrl,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cambiar PIN
          _SettingsSection(
            title: 'Cambiar PIN',
            icon: Icons.lock,
            children: [
              TextFormField(
                controller: _newPinCtrl,
                decoration: const InputDecoration(labelText: 'Nuevo PIN'),
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPinCtrl,
                decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Actualizar PIN'),
                  onPressed: _savePin,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Luciérnagas Control v1.0.0\nNanacamilpa, Tlaxcala',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.grey[400],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _basicAdultCtrl.dispose();
    _basicChildCtrl.dispose();

    _campingAdultCtrl.dispose();
    _campingChildCtrl.dispose();

    _premiumAdultCtrl.dispose();
    _premiumChildCtrl.dispose();

    _tent2PersonCtrl.dispose();
    _tent4PersonCtrl.dispose();
    _tent6PersonCtrl.dispose();
    _tent10PersonCtrl.dispose();

    _businessNameCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.forestGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
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

class _CabinPriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _CabinPriceField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            prefixText: '\$',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
        ),
      ],
    );
  }
}
