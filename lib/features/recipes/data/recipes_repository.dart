import '../../../core/database/db_helper.dart';
import '../../pantry/data/ingredient_model.dart';
import 'recipe_model.dart';
import 'ingredient_in_recipe_model.dart';

class RecipesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Recipe>> getRecipes() async {
    final db = await _dbHelper.database;
    final result = await db.query('recipes');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Recipe.fromMap(result.first);
    }
    return null;
  }

  Future<List<IngredientInRecipe>> getIngredientsForRecipe(String recipeId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        ri.id, 
        ri.recipeId, 
        ri.ingredientId, 
        ri.quantity,
        i.name as ingredientName,
        i.unit as ingredientUnit,
        i.photoPath as ingredientPhoto
      FROM recipe_ingredients ri
      INNER JOIN ingredients i ON ri.ingredientId = i.id
      WHERE ri.recipeId = ?
    ''', [recipeId]);

    return result.map((json) => IngredientInRecipe.fromMap(json)).toList();
  }

  // ... методи addRecipe, updateRecipe, deleteRecipe, getAllIngredients, getAvailableRecipeIds залишаються без змін ...
  Future<void> addRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final recipeId = await txn.insert('recipes', recipe.toMap());

      for (var ingredient in ingredients) {
        await txn.insert('recipe_ingredients', {
          'recipeId': recipeId,
          'ingredientId': ingredient.ingredientId,
          'quantity': ingredient.quantity,
        });
      }
    });
  }

  Future<void> updateRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'recipes',
        recipe.toMap(),
        where: 'id = ?',
        whereArgs: [recipe.id],
      );

      await txn.delete(
        'recipe_ingredients',
        where: 'recipeId = ?',
        whereArgs: [recipe.id],
      );

      for (var ingredient in ingredients) {
        await txn.insert('recipe_ingredients', {
          'recipeId': recipe.id,
          'ingredientId': ingredient.ingredientId,
          'quantity': ingredient.quantity,
        });
      }
    });
  }

  Future<void> deleteRecipe(String id) async {
    final db = await _dbHelper.database;
    
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Ingredient>> getAllIngredients() async {
    final db = await _dbHelper.database;
    final result = await db.query('ingredients', orderBy: 'name ASC');
    return result.map((json) => Ingredient.fromMap(json)).toList();
  }

  Future<List<int>> getAvailableRecipeIds() async {
    final db = await _dbHelper.database;

    final allNeeds = await db.rawQuery('SELECT * FROM recipe_ingredients');
    final pantryItems = await db.query('ingredients');
    
    final Map<int, double> pantryMap = {};
    for (var item in pantryItems) {
      final id = item['id'] as int;
      final qty = (item['quantity'] as num).toDouble();
      pantryMap[id] = qty;
    }

    final Map<int, List<Map<String, dynamic>>> recipeRequirements = {};
    for (var row in allNeeds) {
      final recipeId = row['recipeId'] as int;
      if (!recipeRequirements.containsKey(recipeId)) {
        recipeRequirements[recipeId] = [];
      }
      recipeRequirements[recipeId]!.add(row);
    }

    final List<int> availableIds = [];

    for (var recipeId in recipeRequirements.keys) {
      bool canCook = true;
      final requirements = recipeRequirements[recipeId]!;

      for (var req in requirements) {
        final ingId = req['ingredientId'] as int;
        final requiredQty = (req['quantity'] as num).toDouble();
        final availableQty = pantryMap[ingId] ?? 0.0;
        if (availableQty < requiredQty) {
          canCook = false;
          break; 
        }
      }
      if (canCook) {
        availableIds.add(recipeId);
      }
    }
    return availableIds;
  }

  Future<List<int>> getRecipeIdsByIngredients(List<String> ingredientNames) async {
      final db = await _dbHelper.database;
      if (ingredientNames.isEmpty) return [];

      final placeholders = List.filled(ingredientNames.length, '?').join(',');
      final ingredientsResult = await db.query(
        'ingredients',
        columns: ['id'],
        where: 'name IN ($placeholders)',
        whereArgs: ingredientNames,
      );
      
      final ingredientIds = ingredientsResult.map((e) => e['id'] as int).toList();
      
      if (ingredientIds.isEmpty) return [];

      final ingPlaceholders = List.filled(ingredientIds.length, '?').join(',');
      final result = await db.query(
        'recipe_ingredients',
        columns: ['recipeId'],
        where: 'ingredientId IN ($ingPlaceholders)',
        whereArgs: ingredientIds,
        distinct: true,
      );
      
      return result.map((e) => e['recipeId'] as int).toList();
  }
}