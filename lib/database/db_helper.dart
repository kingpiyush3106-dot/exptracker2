// lib/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../notification_service.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  // Table / columns
  static const String tableItems = 'items';
  static const String colId = 'id';
  static const String colUserId = 'userId';
  static const String colProductName = 'productName';
  static const String colManufactureDate = 'manufactureDate';
  static const String colExpiryDate = 'expiryDate';
  static const String colImagePath = 'imagePath';
  static const String colSynced = 'synced';
  static const String colCreatedAt = 'createdAt';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expiry_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableItems (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colUserId TEXT,
        $colProductName TEXT NOT NULL,
        $colManufactureDate TEXT,
        $colExpiryDate TEXT,
        $colImagePath TEXT,
        $colSynced INTEGER DEFAULT 0,
        $colCreatedAt TEXT
      )
    ''');
  }

  // ---------- CRUD ----------

  /// Insert a local item. Returns inserted row id.
  Future<int> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    final id = await db.insert(
      tableItems,
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // ✅ Schedule expiry reminders (after successful insert)
    try {
      if (item.containsKey(colExpiryDate) && item[colExpiryDate] != null) {
        final expiryDateString = item[colExpiryDate];
        if (expiryDateString != null && expiryDateString.toString().isNotEmpty) {
          final expiryDate = DateTime.parse(expiryDateString);
          final productName = item[colProductName] ?? 'Unknown Product';

          await NotificationService.scheduleExpiryReminders(
            productName: productName,
            expiryDate: expiryDate,
          );

          print("🕒 Notifications scheduled for $productName (expiry: $expiryDate)");
        }
      }
    } catch (e) {
      print("⚠️ Error scheduling notification: $e");
    }

    return id;
  }

  /// Fetch all items for a given userId.
  Future<List<Map<String, dynamic>>> getItemsByUser(String userId) async {
    final db = await database;
    return await db.query(
      tableItems,
      where: '$colUserId = ?',
      whereArgs: [userId],
      orderBy: '$colCreatedAt DESC',
    );
  }

  /// Fetch only unsynced items for a given user.
  Future<List<Map<String, dynamic>>> getUnsyncedItems(String userId) async {
    final db = await database;
    return await db.query(
      tableItems,
      where: '$colUserId = ? AND $colSynced = 0',
      whereArgs: [userId],
    );
  }

  /// Mark an item as synced (set synced = 1)
  Future<int> markItemSynced(int id) async {
    final db = await database;
    return await db.update(
      tableItems,
      {colSynced: 1},
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// Update entire item (expects item map to contain 'id' key)
  Future<int> updateItem(Map<String, dynamic> item) async {
    final db = await database;
    final id = item[colId];
    return await db.update(tableItems, item, where: '$colId = ?', whereArgs: [id]);
  }

  /// Delete item by id
  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(tableItems, where: '$colId = ?', whereArgs: [id]);
  }

  /// Delete all items for a user (useful on logout)
  Future<int> deleteAllForUser(String userId) async {
    final db = await database;
    return await db.delete(tableItems, where: '$colUserId = ?', whereArgs: [userId]);
  }

  Future<void> close() async {
    final dbClient = await database;
    await dbClient.close();
    _db = null;
  }
}
