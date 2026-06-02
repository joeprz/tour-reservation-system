// lib/core/constants/app_constants.dart

enum AppRole { reception, checkin }

class AppConstants {
  static const String appName = 'Luciérnagas Control';
  static const String businessName = 'Tour de Luciérnagas Nanacamilpa';
  static const String currency = 'MXN';
  static const String currencySymbol = '\$';

  // Default prices
  static const double defaultAdultPrice = 150.0;
  static const double defaultChildPrice = 80.0;

  // Default time slots
  static const List<String> defaultTimeSlots = [
    '20:00 - 21:00',
    '21:00 - 22:00',
    '22:00 - 23:00',
  ];

  // Shared preferences keys
  static const String keyDeviceRole = 'device_role';
  static const String keyAdminPin = 'admin_pin';
  static const String keyThemeMode = 'theme_mode';
  static const String keyScannerName = 'scanner_name';
  static const String keyExpenses = 'expenses';
  static const String keyServerIp = 'server_ip';
  static const String keyServerPort = 'server_port';
  static const String keyIsServer = 'is_server';
  static const String keyFirstLaunch = 'first_launch';

  // Network
  static const int syncServerPort = 8765;
  static const int syncIntervalSeconds = 30;
  static const String syncApiPrefix = '/api/v1';

  // QR
  static const String qrPrefix = 'LCT';

  // Supabase environment variables (compile-time values)
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Reservation statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCancelled = 'cancelled';
  static const String statusCheckedIn = 'checked_in';
  static const String statusNoShow = 'no_show';

  // Table names
  static const String tableCustomers = 'customers';
  static const String tableReservations = 'reservations';
  static const String tableExpenses = 'expenses';
  static const String tableSettings = 'settings';
  static const String tableSyncLog = 'sync_log';

  // Database version
  static const int dbVersion = 4;
  static const String dbName = 'luciernas_control.db';
}
