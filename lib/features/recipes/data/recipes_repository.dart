import '../../../core/database/db_helper.dart';
import 'recipe_model.dart';

class RecipesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Recipe>> getRecipes() async {
    final db = await _dbHelper.database;
    final result = await db.query('recipes');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<int> addRecipe(Recipe recipe) async {
    final db = await _dbHelper.database;
    return await db.insert('recipes', recipe.toMap());
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
}