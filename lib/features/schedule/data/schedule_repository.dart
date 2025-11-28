import '../../../core/database/db_helper.dart';
import 'meal_plan_entry_model.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<MealPlanEntry>> getMealsForDate(DateTime date) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        s.id, 
        s.recipeId, 
        s.date, 
        s.time, 
        r.name as recipeName, 
        r.photoPath as recipePhotoPath
      FROM schedule s
      INNER JOIN recipes r ON s.recipeId = r.id
    ''');

    final allMeals = result.map((json) => MealPlanEntry.fromMap(json)).toList();

    return allMeals.where((meal) => 
      meal.date.year == date.year && 
      meal.date.month == date.month && 
      meal.date.day == date.day
    ).toList();
  }

  Future<int> addMeal(MealPlanEntry meal) async {
    final db = await _dbHelper.database;
    return await db.insert('schedule', meal.toMap());
  }

  Future<int> deleteMeal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('schedule', where: 'id = ?', whereArgs: [id]);
  }
}