import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/pantry/data/ingredient_model.dart';
import '../../features/recipes/data/recipe_model.dart';
import '../../features/recipes/data/ingredient_in_recipe_model.dart';
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

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final beef = Ingredient(name: 'Beef', unit: 'g', quantity: 500, photoPath: 'assets/images/beef.jpg');
    final beet = Ingredient(name: 'Beet', unit: 'g', quantity: 375, photoPath: 'assets/images/beet.jpg');
    final cabbage = Ingredient(name: 'Cabbage', unit: 'g', quantity: 550, photoPath: 'assets/images/cabbage.jpg');
    final carrot = Ingredient(name: 'Carrot', unit: 'g', quantity: 100, photoPath: 'assets/images/carrot.jpg');
    final onion = Ingredient(name: 'Onion', unit: 'g', quantity: 250, photoPath: 'assets/images/onion.jpg');
    final egg = Ingredient(name: 'Egg', unit: 'pcs', quantity: 11, photoPath: 'assets/images/egg.jpg');
    final milk = Ingredient(name: 'Milk', unit: 'ml', quantity: 250, photoPath: 'assets/images/milk.jpg');
    final salt = Ingredient(name: 'Salt', unit: 'g', quantity: 400, photoPath: 'assets/images/salt.jpg');
    final pepper = Ingredient(name: 'Black pepper', unit: 'g', quantity: 15, photoPath: 'assets/images/black_pepper.jpg');

    final ingredients = [beef, beet, cabbage, carrot, onion, egg, milk, salt, pepper];

    for (var i in ingredients) {
      await db.insert('ingredients', i.toMap());
    }

    final borsch = Recipe(
      name: 'Borsch', 
      photoPath: 'assets/images/borsch.jpg', 
      cookingTime: 45, 
      steps: '1. Place meat in a large pot and cover with 3 liters of cold water...\n2. Sauté chopped onions and carrots...'
    );

    final cabbageRolls = Recipe(
      name: 'Stuffed cabbage rolls', 
      photoPath: 'assets/images/cabbage_rolls.jpg', 
      cookingTime: 80,
      steps: 'Delicious rolls with meat and rice...'
    );

    final pancakes = Recipe(
      name: 'Potato pancakes', 
      photoPath: 'assets/images/potato_pancakes.jpg', 
      cookingTime: 45, 
      steps: 'Crispy potato pancakes...'
    );

    final tacos = Recipe(
      name: 'Tacos', 
      photoPath: 'assets/images/tacos.jpg', 
      cookingTime: 70,
      steps: 'Mexican classic...'
    );

    final recipes = [borsch, cabbageRolls, pancakes, tacos];

    for (var r in recipes) {
      await db.insert('recipes', r.toMap());
    }

    final borschLinks = [
      IngredientInRecipe(recipeId: borsch.id, ingredientId: beef.id, quantity: 500),
      IngredientInRecipe(recipeId: borsch.id, ingredientId: beet.id, quantity: 375),
      IngredientInRecipe(recipeId: borsch.id, ingredientId: cabbage.id, quantity: 550),
      IngredientInRecipe(recipeId: borsch.id, ingredientId: carrot.id, quantity: 100),
      IngredientInRecipe(recipeId: borsch.id, ingredientId: onion.id, quantity: 250),
    ];

    for (var link in borschLinks) {
      await db.insert('recipe_ingredients', link.toMap());
    }

    final pancakesLinks = [
      IngredientInRecipe(recipeId: pancakes.id, ingredientId: egg.id, quantity: 2),
      IngredientInRecipe(recipeId: pancakes.id, ingredientId: milk.id, quantity: 100),
    ];

    for (var link in pancakesLinks) {
      await db.insert('recipe_ingredients', link.toMap());
    }

    final now = DateTime.now();
        
    await db.insert('schedule', MealPlanEntry(
      recipeId: borsch.id, 
      dateTime: now.copyWith(hour: 13, minute: 0, second: 0, millisecond: 0),
      recipeName: borsch.name,
      recipePhotoPath: borsch.photoPath
    ).toMap());

    await db.insert('schedule', MealPlanEntry(
      recipeId: cabbageRolls.id, 
      dateTime: now.copyWith(hour: 14, minute: 0, second: 0, millisecond: 0),
      recipeName: cabbageRolls.name,
      recipePhotoPath: cabbageRolls.photoPath
    ).toMap());
    
    await db.insert('schedule', MealPlanEntry(
      recipeId: pancakes.id, 
      dateTime: now.copyWith(hour: 18, minute: 0, second: 0, millisecond: 0),
      recipeName: pancakes.name,
      recipePhotoPath: pancakes.photoPath
    ).toMap());
  }
}