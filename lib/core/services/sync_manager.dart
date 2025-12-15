import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../database/db_helper.dart';
// import 'supabase_storage_service.dart';

// Data Sources
import '../../features/pantry/data/firestore_ingredients_data_source.dart';
import '../../features/recipes/data/firestore_recipes_data_source.dart';
import '../../features/schedule/data/firestore_schedule_data_source.dart';

// Models
import '../../features/pantry/data/ingredient_model.dart';
import '../../features/recipes/data/recipe_model.dart';
import '../../features/recipes/data/ingredient_in_recipe_model.dart';
import '../../features/schedule/data/meal_plan_entry_model.dart';

class SyncManager {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  // final SupabaseStorageService _storageService = SupabaseStorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirestoreIngredientsDataSource _ingredientsSource = FirestoreIngredientsDataSource();
  final FirestoreRecipesDataSource _recipesSource = FirestoreRecipesDataSource();
  final FirestoreScheduleDataSource _scheduleSource = FirestoreScheduleDataSource();

  bool _isSyncing = false;

  Future<void> syncPendingActions() async {
    if (_isSyncing) return;
    
    bool hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      debugPrint('SyncManager: No internet connection.');
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _isSyncing = true;
    debugPrint('SyncManager: Starting sync...');

    try {
      final pendingActions = await _dbHelper.getPendingActions();
      debugPrint('SyncManager: Found ${pendingActions.length} pending actions.');

      for (var actionRow in pendingActions) {
        final String id = actionRow['id'];
        final String action = actionRow['action'];
        final String collection = actionRow['collection'];
        final String docId = actionRow['docId'];
        final Map<String, dynamic> data = jsonDecode(actionRow['data']);

        bool success = false;

        try {
          switch (collection) {
            case 'pantry':
              success = await _syncPantry(userId, action, docId, data);
              break;
            case 'recipes':
              success = await _syncRecipe(userId, action, docId, data);
              break;
            case 'schedule':
              success = await _syncSchedule(userId, action, docId, data);
              break;
          }

          if (success) {
            await _dbHelper.deletePendingAction(id);
            debugPrint('SyncManager: Action $id ($collection/$action) synced successfully.');
          }
        } catch (e) {
          debugPrint('SyncManager: Failed to sync action $id: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncPantry(String userId, String action, String docId, Map<String, dynamic> data) async {
    if (action == 'DELETE') {
      await _ingredientsSource.deletePantryItem(userId, docId);
      await _ingredientsSource.deleteCustomIngredient(userId, docId);
      return true;
    }

    var ingredient = Ingredient.fromMap(data);

    if (ingredient.photoPath != null && 
       (ingredient.photoUrl == null || ingredient.photoUrl!.isEmpty)) {
      final cloudUrl = await _uploadImage(ingredient.photoPath!, 'ingredients');
      if (cloudUrl != null) {
        ingredient = ingredient.copyWith(photoUrl: cloudUrl);
      }
    }

    if (ingredient.isCustom) {
      await _ingredientsSource.saveCustomIngredient(userId, ingredient);
    }
    
    if (ingredient.quantity > 0 || action == 'UPDATE') {
      await _ingredientsSource.savePantryItem(userId, ingredient);
    }
    
    return true;
  }

  Future<bool> _syncRecipe(String userId, String action, String docId, Map<String, dynamic> data) async {
    if (action == 'DELETE') {
      await _recipesSource.deleteCustomRecipe(userId, docId);
      return true;
    }

    final recipeMap = data['recipe'] as Map<String, dynamic>;
    var recipe = Recipe.fromMap(recipeMap);
    
    final ingredientsList = (data['ingredients'] as List).map((x) => IngredientInRecipe.fromMap(x)).toList();

    if (recipe.photoPath != null && 
       (recipe.photoUrl == null || recipe.photoUrl!.isEmpty)) {
      final cloudUrl = await _uploadImage(recipe.photoPath!, 'recipes');
      if (cloudUrl != null) {
        recipe = recipe.copyWith(photoUrl: cloudUrl);
      }
    }

    if (action == 'CREATE') {
      await _recipesSource.addCustomRecipe(userId, recipe, ingredientsList);
    } else if (action == 'UPDATE') {
      await _recipesSource.updateCustomRecipe(userId, recipe, ingredientsList);
    }
    return true;
  }

  Future<bool> _syncSchedule(String userId, String action, String docId, Map<String, dynamic> data) async {
    if (action == 'DELETE') {
      await _scheduleSource.deleteMeal(userId, docId);
      return true;
    }

    final meal = MealPlanEntry.fromMap(data);

    if (action == 'CREATE') {
      await _scheduleSource.addMeal(userId, meal);
    } else if (action == 'UPDATE') {
      await _scheduleSource.updateMeal(userId, meal);
    }
    return true;
  }

  Future<String?> _uploadImage(String path, String folder) async {
    final file = File(path);
    if (file.existsSync()) {
      try {
        // return await _storageService.uploadFile(file, folder);
      } catch (e) {
        debugPrint('SyncManager: Error uploading image: $e');
        return null;
      }
    }
    return null;
  }
}