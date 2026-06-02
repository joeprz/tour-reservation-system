// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCustomers} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
  CREATE TABLE ${AppConstants.tableReservations} (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    token TEXT NOT NULL,
    date TEXT NOT NULL,
    time_slot TEXT NOT NULL,
    adults INTEGER NOT NULL DEFAULT 1,
    children INTEGER NOT NULL DEFAULT 0,
    adult_price REAL NOT NULL,
    child_price REAL NOT NULL,
    total REAL NOT NULL,
    deposit REAL NOT NULL DEFAULT 0,
    balance REAL NOT NULL DEFAULT 0,

    package_type TEXT DEFAULT 'basic',
    package_name TEXT DEFAULT 'PAQUETE BÁSICO',
    nights INTEGER DEFAULT 0,
    tents INTEGER DEFAULT 0,

    status TEXT NOT NULL DEFAULT 'pending',
    notes TEXT,
    checked_in_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,

    FOREIGN KEY (customer_id) REFERENCES ${AppConstants.tableCustomers}(id)
  )
''');

    await db.execute('''
CREATE TABLE ${AppConstants.tableSettings} (
  id INTEGER PRIMARY KEY,

  basic_adult_price REAL NOT NULL DEFAULT 300,
  basic_child_price REAL NOT NULL DEFAULT 200,

  camping_adult_price REAL NOT NULL DEFAULT 500,
  camping_child_price REAL NOT NULL DEFAULT 400,

  premium_adult_price REAL NOT NULL DEFAULT 1000,
  premium_child_price REAL NOT NULL DEFAULT 800,

  tent_2_person_price REAL NOT NULL DEFAULT 280,
  tent_4_person_price REAL NOT NULL DEFAULT 450,
  tent_6_person_price REAL NOT NULL DEFAULT 600,
  tent_10_person_price REAL NOT NULL DEFAULT 900,

  business_name TEXT NOT NULL,
  time_slots TEXT NOT NULL,
  admin_pin TEXT NOT NULL DEFAULT '330297',
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncLog} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL DEFAULT 'upsert',
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert(AppConstants.tableSettings, {
      'id': 1,
      'basic_adult_price': 300,
      'basic_child_price': 200,
      'camping_adult_price': 500,
      'camping_child_price': 400,
      'premium_adult_price': 1000,
      'premium_child_price': 800,
      'tent_2_person_price': 280,
      'tent_4_person_price': 450,
      'tent_6_person_price': 600,
      'tent_10_person_price': 900,
      'business_name': AppConstants.businessName,
      'time_slots': AppConstants.defaultTimeSlots.join(','),
      'admin_pin': '330297',
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert example data
    await _insertExampleData(db);
  }

  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        '''
      ALTER TABLE ${AppConstants.tableReservations}
      ADD COLUMN service_type TEXT NOT NULL DEFAULT 'tour'
      ''',
      );

      await db.execute(
        '''
      ALTER TABLE ${AppConstants.tableReservations}
      ADD COLUMN nights INTEGER NOT NULL DEFAULT 0
      ''',
      );

      await db.execute(
        '''
      ALTER TABLE ${AppConstants.tableReservations}
      ADD COLUMN check_out_date TEXT
      ''',
      );

      await db.execute(
        '''
      ALTER TABLE ${AppConstants.tableReservations}
      ADD COLUMN camping_tents INTEGER NOT NULL DEFAULT 0
      ''',
      );

      await db.execute(
        '''
      ALTER TABLE ${AppConstants.tableReservations}
      ADD COLUMN camping_zone TEXT
      ''',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE settings ADD COLUMN basic_adult_price REAL DEFAULT 300");

      await db.execute(
          "ALTER TABLE settings ADD COLUMN basic_child_price REAL DEFAULT 200");

      await db.execute(
          "ALTER TABLE settings ADD COLUMN camping_adult_price REAL DEFAULT 500");

      await db.execute(
          "ALTER TABLE settings ADD COLUMN camping_child_price REAL DEFAULT 400");

      await db.execute(
          "ALTER TABLE settings ADD COLUMN premium_adult_price REAL DEFAULT 1000");

      await db.execute(
          "ALTER TABLE settings ADD COLUMN premium_child_price REAL DEFAULT 800");

      await db.execute(
          "ALTER TABLE reservations ADD COLUMN package_type TEXT DEFAULT 'basic'");

      await db.execute(
          "ALTER TABLE reservations ADD COLUMN package_name TEXT DEFAULT 'PAQUETE BÁSICO'");

      await db.execute(
          "ALTER TABLE reservations ADD COLUMN tents INTEGER DEFAULT 0");
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE settings ADD COLUMN tent_2_person_price REAL DEFAULT 280",
      );

      await db.execute(
        "ALTER TABLE settings ADD COLUMN tent_4_person_price REAL DEFAULT 450",
      );

      await db.execute(
        "ALTER TABLE settings ADD COLUMN tent_6_person_price REAL DEFAULT 600",
      );

      await db.execute(
        "ALTER TABLE settings ADD COLUMN tent_10_person_price REAL DEFAULT 900",
      );
    }
  }

  Future<void> _insertExampleData(Database db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sample customers
    final customers = [
      {
        'id': 'c1',
        'name': 'María González López',
        'phone': '246 123 4567',
        'created_at': now.toIso8601String()
      },
      {
        'id': 'c2',
        'name': 'Carlos Hernández Martínez',
        'phone': '246 987 6543',
        'created_at': now.toIso8601String()
      },
      {
        'id': 'c3',
        'name': 'Ana Ramírez Torres',
        'phone': '55 1234 5678',
        'created_at': now.toIso8601String()
      },
      {
        'id': 'c4',
        'name': 'José Luis Pérez',
        'phone': '246 555 0001',
        'created_at': now.toIso8601String()
      },
    ];

    for (var c in customers) {
      await db.insert(AppConstants.tableCustomers, c);
    }

    // Sample reservations for today
    final reservations = [
      {
        'id': 'r1',
        'customer_id': 'c1',
        'code': 'LCT-001',
        'token': 'tok_abc123',
        'date': today.toIso8601String().split('T')[0],
        'time_slot': '21:00 - 22:00',
        'adults': 2,
        'children': 1,
        'adult_price': 150.0,
        'child_price': 80.0,
        'total': 380.0,
        'deposit': 200.0,
        'balance': 180.0,
        'status': 'confirmed',
        'notes': 'Festejan aniversario',
        'checked_in_at': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'r2',
        'customer_id': 'c2',
        'code': 'LCT-002',
        'token': 'tok_def456',
        'date': today.toIso8601String().split('T')[0],
        'time_slot': '20:00 - 21:00',
        'adults': 4,
        'children': 0,
        'adult_price': 150.0,
        'child_price': 80.0,
        'total': 600.0,
        'deposit': 300.0,
        'balance': 300.0,
        'status': 'checked_in',
        'notes': '',
        'checked_in_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'r3',
        'customer_id': 'c3',
        'code': 'LCT-003',
        'token': 'tok_ghi789',
        'date': today.toIso8601String().split('T')[0],
        'time_slot': '22:00 - 23:00',
        'adults': 2,
        'children': 2,
        'adult_price': 150.0,
        'child_price': 80.0,
        'total': 460.0,
        'deposit': 0.0,
        'balance': 460.0,
        'status': 'pending',
        'notes': 'Grupo familiar',
        'checked_in_at': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
    ];

    for (var r in reservations) {
      await db.insert(AppConstants.tableReservations, r);
    }
  }

  // ─── Generic CRUD ──────────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> queryById(String table, String id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String id,
  ) async {
    final db = await database;
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  /// Export all data as JSON map
  Future<Map<String, dynamic>> exportAll() async {
    final customers = await queryAll(AppConstants.tableCustomers);
    final reservations = await queryAll(AppConstants.tableReservations);
    final settings = await queryAll(AppConstants.tableSettings);
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'version': AppConstants.dbVersion,
      'customers': customers,
      'reservations': reservations,
      'settings': settings,
    };
  }

  /// Import data from JSON map (restore)
  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var c in (data['customers'] as List)) {
        await txn.insert(
          AppConstants.tableCustomers,
          Map<String, dynamic>.from(c),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var r in (data['reservations'] as List)) {
        await txn.insert(
          AppConstants.tableReservations,
          Map<String, dynamic>.from(r),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
