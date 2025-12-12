import '../../../core/database/db_helper.dart';
import 'ingredient_model.dart';

class PantryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Ingredient>> getPantryItems() async {
    final db = await _dbHelper.database;
    final result = await db.query('ingredients', orderBy: 'name ASC');
    return result.map((json) => Ingredient.fromMap(json)).toList();
  }

  Future<int> addIngredient(Ingredient ingredient) async {
    final db = await _dbHelper.database;
    return await db.insert('ingredients', ingredient.toMap());
  }

  Future<int> updateIngredient(Ingredient ingredient) async {
    final db = await _dbHelper.database;
    return await db.update(
      'ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  Future<int> deleteIngredient(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}