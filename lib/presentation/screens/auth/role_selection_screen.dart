// lib/presentation/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

import '../dashboard/dashboard_screen.dart';
import '../checkin/checkin_screen.dart';
import '../../../core/constants/app_constants.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();

}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _scannerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredScannerName();
  }

  Future<void> _loadStoredScannerName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.keyScannerName);
    if (stored != null && mounted) {
      _scannerNameController.text = stored;
    }
  }

  Future<void> _setRoleAndNavigate(AppRole role, Widget nextScreen) async {
    if (role == AppRole.checkin && _scannerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre de quien escaneará los QR.')),
      );
      return;
    }

    if (role == AppRole.checkin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyScannerName, _scannerNameController.text.trim());
      ref.invalidate(scannerNameProvider);
    }

    await ref.read(deviceRoleNotifierProvider.notifier).setRole(role);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  void dispose() {
    _scannerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isSmallHeight = size.height < 520;
    final horizontalPadding = isSmallHeight ? 16.0 : 24.0;
    final verticalGapLarge = isSmallHeight ? 18.0 : 34.0;
    final verticalGapSmall = isSmallHeight ? 10.0 : 16.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.deepForest,
              AppTheme.forestGreen,
              Color(0xFF2D6A4F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    children: [
                      _AnimatedFirefly(
                        small: isSmallHeight,
                      ),

                      SizedBox(height: verticalGapSmall),

                      Text(
                        '✨ Luciérnagas Control',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmallHeight ? 24 : 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Nanacamilpa, Tlaxcala, México',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmallHeight ? 13 : 15,
                          color: Colors.white60,
                        ),
                      ),

                      SizedBox(height: verticalGapLarge),

                      Text(
                        'Selecciona el modo de este dispositivo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmallHeight ? 15 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: _scannerNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nombre del escaneador',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Ej. Juan o Ana',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
                          ),
                        ),
                      ),

                      SizedBox(height: verticalGapLarge),

                      isLandscape
                          ? Row(
                              children: [
                                Expanded(
                                  child: _RoleCard(
                                    compact: isSmallHeight,
                                    icon: Icons.tablet_android,
                                    title: 'Recepción',
                                    subtitle:
                                        'Tableta principal\nReservaciones y administración',
                                    onTap: () async {
                                      await _setRoleAndNavigate(
                                        AppRole.reception,
                                        const DashboardScreen(),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: _RoleCard(
                                    compact: isSmallHeight,
                                    icon: Icons.qr_code_scanner,
                                    title: 'Acceso',
                                    subtitle:
                                        'Teléfono entrada\nEscaneo QR y check-in',
                                    onTap: () async {
                                      await _setRoleAndNavigate(
                                        AppRole.checkin,
                                        const CheckInScreen(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _RoleCard(
                                  compact: false,
                                  icon: Icons.tablet_android,
                                  title: 'Recepción',
                                  subtitle:
                                      'Tableta principal\nReservaciones y administración',
                                  onTap: () async {
                                    await _setRoleAndNavigate(
                                      AppRole.reception,
                                      const DashboardScreen(),
                                    );
                                  },
                                ),

                                const SizedBox(height: 16),

                                _RoleCard(
                                  compact: false,
                                  icon: Icons.qr_code_scanner,
                                  title: 'Acceso',
                                  subtitle:
                                      'Teléfono de entrada\nEscaneo de QR y check-in',
                                  onTap: () async {
                                    await _setRoleAndNavigate(
                                      AppRole.checkin,
                                      const CheckInScreen(),
                                    );
                                  },
                                ),
                              ],
                            ),

                      SizedBox(height: verticalGapLarge),

                      Text(
                        'Esta configuración se puede cambiar desde\nAjustes con el PIN de administrador',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmallHeight ? 11 : 13,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.compact,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );

    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 16 : 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: compact ? 58 : 68,
                height: compact ? 58 : 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.goldenFirefly.withOpacity(0.18),
                ),
                child: Icon(
                  widget.icon,
                  size: compact ? 28 : 34,
                  color: AppTheme.goldenFirefly,
                ),
              ),

              SizedBox(height: compact ? 10 : 14),

              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: compact ? 11 : 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _AnimatedFirefly extends StatefulWidget {
  final bool small;

  const _AnimatedFirefly({
    required this.small,
  });

  @override
  State<_AnimatedFirefly> createState() =>
      _AnimatedFireflyState();
}

class _AnimatedFireflyState extends State<_AnimatedFirefly>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        '🌿',
        style: TextStyle(
          fontSize: widget.small ? 56 : 74,
        ),
      ),
    );
  }
}