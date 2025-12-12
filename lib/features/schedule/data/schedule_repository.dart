import '../../../core/database/db_helper.dart';
import 'meal_plan_entry_model.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<MealPlanEntry>> getAllMeals() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        s.id, 
        s.recipeId, 
        s.dateTime, 
        r.name as recipeName, 
        r.photoPath as recipePhotoPath
      FROM schedule s
      INNER JOIN recipes r ON s.recipeId = r.id
    ''');

    return result.map((json) => MealPlanEntry.fromMap(json)).toList();
  }

  Future<int> addMeal(MealPlanEntry meal) async {
    final db = await _dbHelper.database;
    return await db.insert('schedule', meal.toMap());
  }

  Future<int> deleteMeal(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('schedule', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> updateMeal(MealPlanEntry meal) async {
    final db = await _dbHelper.database;
    await db.update(
      'schedule', 
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }
}