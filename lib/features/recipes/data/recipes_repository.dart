import '../../../core/database/db_helper.dart';
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

  Future<List<IngredientInRecipe>> getIngredientsForRecipe(int recipeId) async {
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

  Future<void> addRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final recipeId = await txn.insert('recipes', recipe.toMap());

      for (var ingredient in ingredients) {
        await txn.insert('recipe_ingredients', {
          'recipeId': recipeId, // Use the real ID from step 1
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

  Future<void> deleteRecipe(int id) async {
    final db = await _dbHelper.database;
    
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}