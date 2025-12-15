import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mealize.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE ingredients (
        id $idType,
        name $textType,
        notes $textNullable,
        unit $textType,
        quantity $integerType,
        photoPath $textNullable,
        photoUrl $textNullable,
        isCustom $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id $idType,
        name $textType,
        photoPath $textNullable,
        photoUrl $textNullable,
        cookingTime $integerType,
        steps $textType,
        isCustom $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id $idType,
        recipeId $textType,
        ingredientId $textType,
        quantity $integerType,
        ingredientPhotoUrl $textNullable, 
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredientId) REFERENCES ingredients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule (
        id $idType,
        recipeId $textType,
        dateTime $textType,
        recipePhotoUrl $textNullable,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_actions (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        collection TEXT NOT NULL,
        docId TEXT NOT NULL,
        data TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    return await db.query('pending_actions', orderBy: 'createdAt ASC');
  }

  Future<int> deletePendingAction(String id) async {
    final db = await database;
    return await db.delete(
      'pending_actions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}