import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../database/db_helper.dart';
import 'firebase_storage_service.dart';

// Data Sources
import '../../features/pantry/data/firestore_ingredients_data_source.dart';
import '../../features/recipes/data/firestore_recipes_data_source.dart';
import '../../features/schedule/data/firestore_schedule_data_source.dart';
import '../../features/settings/data/firestore_settings_data_source.dart';

// Models
import '../../features/pantry/data/ingredient_model.dart';
import '../../features/recipes/data/recipe_model.dart';
import '../../features/recipes/data/ingredient_in_recipe_model.dart';
import '../../features/schedule/data/meal_plan_entry_model.dart';

class SyncManager {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirestoreIngredientsDataSource _ingredientsSource = FirestoreIngredientsDataSource();
  final FirestoreRecipesDataSource _recipesSource = FirestoreRecipesDataSource();
  final FirestoreScheduleDataSource _scheduleSource = FirestoreScheduleDataSource();
  final FirestoreSettingsDataSource _settingsSource = FirestoreSettingsDataSource();

  bool _isSyncing = false;

  Future<void> syncPendingActions() async {
    if (_isSyncing) return;
    
    bool hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      debugPrint('SyncManager: No internet connection. Sync skipped.');
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
            case 'settings':
              success = await _syncSettings(userId, action, docId, data);
              break;
          }

          if (success) {
            await _dbHelper.deletePendingAction(id);
            debugPrint('SyncManager: Action $id ($collection/$action) synced & removed from queue.');
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
    var ingredient = Ingredient.fromMap(data);

    if (action == 'DELETE') {
      await _ingredientsSource.deletePantryItem(userId, docId);
      if (ingredient.isCustom) {
        await _ingredientsSource.deleteCustomIngredient(userId, docId);
        if (ingredient.photoUrl != null) {
          try {
             await _storageService.deleteFile(ingredient.photoUrl!);
          } catch (_) {}
        }
      }
      return true;
    }

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
    
    final bool hasNotes = ingredient.notes != null && ingredient.notes!.isNotEmpty;
    
    if (ingredient.quantity == 0 && !hasNotes) {
      await _ingredientsSource.deletePantryItem(userId, docId);
    } else {
      await _ingredientsSource.savePantryItem(userId, ingredient);
    }
    
    return true;
  }

  Future<bool> _syncRecipe(String userId, String action, String docId, Map<String, dynamic> data) async {
    final recipeMap = data['recipe'] as Map<String, dynamic>;
    var recipe = Recipe.fromMap(recipeMap);
    
    if (action == 'DELETE') {
      if (recipe.isCustom) {
        await _recipesSource.deleteCustomRecipe(userId, docId);
        if (recipe.photoUrl != null) {
          try {
            await _storageService.deleteFile(recipe.photoUrl!);
          } catch (_) {}
        }
      }
      return true;
    }

    if (recipe.photoPath != null && 
       (recipe.photoUrl == null || recipe.photoUrl!.isEmpty)) {
      final cloudUrl = await _uploadImage(recipe.photoPath!, 'recipes');
      if (cloudUrl != null) {
        recipe = recipe.copyWith(photoUrl: cloudUrl);
      }
    }

    final ingredientsList = (data['ingredients'] as List)
        .map((x) => IngredientInRecipe.fromMap(x))
        .toList();

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

  Future<bool> _syncSettings(String userId, String action, String docId, Map<String, dynamic> data) async {
    await _settingsSource.updateSettings(userId, data);
    return true;
  }

  Future<String?> _uploadImage(String path, String folder) async {
    final file = File(path);
    if (file.existsSync()) {
      try {
        return await _storageService.uploadFile(file, folder);
      } catch (e) {
        debugPrint('SyncManager: Error uploading image: $e');
        return null;
      }
    }
    return null;
  }
}