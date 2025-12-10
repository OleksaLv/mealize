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
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE ingredients (
        id $idType,
        name $textType,
        notes TEXT,
        unit $textType,
        quantity $integerType,
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
        description $textType,
        isCustom $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id $idType,
        recipeId $integerType,
        ingredientId $integerType,
        quantity $integerType,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredientId) REFERENCES ingredients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule (
        id $idType,
        recipeId $integerType,
        dateTime $textType,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Ingredients
    final ingredients = [
      const Ingredient(name: 'Beef', unit: 'g', quantity: 500, photoPath: 'assets/images/beef.jpg'), // id 1
      const Ingredient(name: 'Beet', unit: 'g', quantity: 375, photoPath: 'assets/images/beet.jpg'), // id 2
      const Ingredient(name: 'Cabbage', unit: 'g', quantity: 550, photoPath: 'assets/images/cabbage.jpg'), // id 3
      const Ingredient(name: 'Carrot', unit: 'g', quantity: 100, photoPath: 'assets/images/carrot.jpg'), // id 4
      const Ingredient(name: 'Onion', unit: 'g', quantity: 250, photoPath: 'assets/images/onion.jpg'), // id 5
      const Ingredient(name: 'Egg', unit: 'pcs', quantity: 11, photoPath: 'assets/images/egg.jpg'), // id 6
      const Ingredient(name: 'Milk', unit: 'ml', quantity: 250, photoPath: 'assets/images/milk.jpg'), // id 7
      const Ingredient(name: 'Salt', unit: 'g', quantity: 400, photoPath: 'assets/images/salt.jpg'), // id 8
      const Ingredient(name: 'Black pepper', unit: 'g', quantity: 15, photoPath: 'assets/images/black_pepper.jpg'), // id 9
    ];

    for (var i in ingredients) {
      await db.insert('ingredients', i.toMap());
    }

    // Recipes
    final recipes = [
      const Recipe(
        name: 'Borsch', 
        photoPath: 'assets/images/borsch.jpg', 
        cookingTime: 45, 
        description: '1. Place meat in a large pot and cover with 3 liters of cold water...\n2. Sauté chopped onions and carrots...'
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

    // Linking ingredients to Borsch (Recipe ID 1)
    final borschIngredients = [
      {'id': 1, 'qty': 500}, // Beef
      {'id': 2, 'qty': 375}, // Beet
      {'id': 3, 'qty': 550}, // Cabbage
      {'id': 4, 'qty': 100}, // Carrot
      {'id': 5, 'qty': 250}, // Onion
    ];

    for (var item in borschIngredients) {
      await db.insert('recipe_ingredients', {
        'recipeId': 1,
        'ingredientId': item['id'],
        'quantity': item['qty'],
      });
    }

    // Linking ingredients to Potato pancakes (Recipe ID 3)
    await db.insert('recipe_ingredients', {
      'recipeId': 3,
      'ingredientId': 6, // Egg
      'quantity': 2,
    });
     await db.insert('recipe_ingredients', {
      'recipeId': 3,
      'ingredientId': 7, // Milk
      'quantity': 100,
    });


    // Meal Plan Entries
    final now = DateTime.now();
        
    await db.insert('schedule', MealPlanEntry(
      recipeId: 1, 
      dateTime: now.copyWith(hour: 13, minute: 0, second: 0, millisecond: 0)
    ).toMap());

    await db.insert('schedule', MealPlanEntry(
      recipeId: 2, 
      dateTime: now.copyWith(hour: 14, minute: 0, second: 0, millisecond: 0)
    ).toMap());
    
    await db.insert('schedule', MealPlanEntry(
      recipeId: 3, 
      dateTime: now.copyWith(hour: 18, minute: 0, second: 0, millisecond: 0)
    ).toMap());
  }
}