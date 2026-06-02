import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/app_settings.dart';

class SettingsRepository {
  final DatabaseHelper _db =
      DatabaseHelper.instance;

  Future<AppSettings>
      getSettings() async {
    final rows =
        await _db.queryAll(
      AppConstants.tableSettings,
    );

    if (rows.isEmpty) {
      final defaults =
          AppSettings.defaults;

      await _db.insert(
        AppConstants.tableSettings,
        defaults.toMap(),
      );

      return defaults;
    }

    return AppSettings.fromMap(
      rows.first,
    );
  }

  Future<AppSettings>
      updateSettings(
    AppSettings settings,
  ) async {
    await _db.update(
      AppConstants.tableSettings,
      settings.toMap(),
      settings.id.toString(),
    );

    return settings;
  }

  Future<bool> verifyPin(
    String pin,
  ) async {
    final settings =
        await getSettings();

    return settings.adminPin ==
        pin;
  }

  Future<void> updatePin(
    String newPin,
  ) async {
    final settings =
        await getSettings();

    await updateSettings(
      settings.copyWith(
        adminPin: newPin,
      ),
    );
  }

  // ───────── Helpers precios ─────────

  Future<Map<String, double>>
      getPackagePrices(
    String packageType,
  ) async {
    final s =
        await getSettings();

    switch (packageType) {
      case 'camping':
        return {
          'adult':
              s.campingAdultPrice,
          'child':
              s.campingChildPrice,
        };

      case 'premium':
        return {
          'adult':
              s.premiumAdultPrice,
          'child':
              s.premiumChildPrice,
        };

      default:
        return {
          'adult':
              s.basicAdultPrice,
          'child':
              s.basicChildPrice,
        };
    }
  }
}