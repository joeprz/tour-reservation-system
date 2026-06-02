import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/auth/role_selection_screen.dart';
import 'presentation/screens/checkin/checkin_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_MX', null);
  await initializeDateFormatting('es', null);

  await DatabaseHelper.instance.database;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load compile-time environment values for Supabase.
  final supabaseUrl = AppConstants.supabaseUrl;
  final supabaseAnonKey = AppConstants.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Supabase credentials must be provided at build time using --dart-define=SUPABASE_URL and --dart-define=SUPABASE_ANON_KEY.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: LuciernagasApp(),
    ),
  );
}

class LuciernagasApp extends ConsumerWidget {
  const LuciernagasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final deviceRole = ref.watch(deviceRoleProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Localization
      locale: const Locale('es', 'MX'),

      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('es'),
        Locale('en', 'US'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: deviceRole.when(
        data: (role) {
          if (role == null) {
            return const RoleSelectionScreen();
          }

          if (role == AppRole.reception) {
            return const DashboardScreen();
          }

          return const CheckInScreen();
        },
        loading: () => const _SplashScreen(),
        error: (_, __) => const RoleSelectionScreen(),
      ),

      routes: {
        '/role-selection': (_) => const RoleSelectionScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/checkin': (_) => const CheckInScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '✨',
              style: TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nanacamilpa, Tlaxcala',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
