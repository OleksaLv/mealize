import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/pantry/data/ingredient_model.dart';
import '../../features/recipes/data/recipe_model.dart';
import '../../features/schedule/data/meal_plan_entry_model.dart';

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
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE ingredients (
        id $idType,
        name $textType,
        unit $textType,
        quantity $realType,
        photoPath TEXT,
        isCustom $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id $idType,
        name $textType,
        photoPath TEXT,
        cookingTime $integerType,
        description $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule (
        id $idType,
        recipeId $integerType,
        date $textType,
        time $textType,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final ingredients = [
      const Ingredient(name: 'Apricot', notes: '1 is about very-very small (like a grape)', unit: 'pcs', quantity: 3, photoPath: 'assets/images/apricot.jpg'),
      const Ingredient(name: 'Black garlic', unit: 'pcs', quantity: 3, photoPath: 'assets/images/black_garlic.jpg'),
      const Ingredient(name: 'Black pepper', unit: 'g', quantity: 15, photoPath: 'assets/images/black_pepper.jpg'),
      const Ingredient(name: 'Cep', unit: 'g', quantity: 200, photoPath: 'assets/images/cep.jpeg'),
      const Ingredient(name: 'Egg', unit: 'pcs', quantity: 11, photoPath: 'assets/images/egg.jpg'),
      const Ingredient(name: 'Milk', unit: 'ml', quantity: 250, photoPath: 'assets/images/milk.jpg'),
      const Ingredient(name: 'Salt', unit: 'g', quantity: 400, photoPath: 'assets/images/salt.jpg'),
    ];

    for (var i in ingredients) {
      await db.insert('ingredients', i.toMap());
    }

    final recipes = [
      const Recipe(
        name: 'Borsch', 
        photoPath: 'assets/images/borsch.jpg', 
        cookingTime: 45, 
        description: 'Traditional Ukrainian soup...'
      ),
      const Recipe(
        name: 'Stuffed cabbage rolls', 
        photoPath: 'assets/images/cabbage_rolls.jpg', 
        cookingTime: 80,
        description: 'Delicious rolls with meat and rice...'
      ),
      const Recipe(
        name: 'Potato pancakes', 
        photoPath: 'assets/images/potato_pancakes.jpg', 
        cookingTime: 45, 
        description: 'Crispy potato pancakes...'
      ),
      const Recipe(
        name: 'Tacos', 
        photoPath: 'assets/images/tacos.jpg', 
        cookingTime: 70,
        description: 'Mexican classic...'
      ),
    ];

    for (var r in recipes) {
      await db.insert('recipes', r.toMap());
    }

    final now = DateTime.now();
        
    await db.insert('schedule', MealPlanEntry(
      recipeId: 1, 
      date: now,
      time: '13:00'
    ).toMap());

    await db.insert('schedule', MealPlanEntry(
      recipeId: 2, 
      date: now,
      time: '14:00'
    ).toMap());
    
    await db.insert('schedule', MealPlanEntry(
      recipeId: 3, 
      date: now,
      time: '18:00'
    ).toMap());
  }
}