import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/services/sync_manager.dart';
import '../../pantry/data/ingredient_model.dart';
import 'firestore_recipes_data_source.dart';
import 'recipe_model.dart';
import 'ingredient_in_recipe_model.dart';

class RecipesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreRecipesDataSource _firestoreDataSource =
      FirestoreRecipesDataSource();
  
  final SyncManager _syncManager = SyncManager();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _actionCreate = 'CREATE';
  static const String _actionUpdate = 'UPDATE';
  static const String _actionDelete = 'DELETE';
  static const String _collectionRecipes = 'recipes';

  Future<List<Recipe>> getLocalRecipes() async {
    final db = await _dbHelper.database;
    final result = await db.query('recipes');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<List<Recipe>> syncAndFetchRemote() async {
    final hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      return getLocalRecipes();
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return getLocalRecipes();

    try {
      await _syncManager.syncPendingActions();

      final results = await Future.wait([
        _firestoreDataSource.getStandardRecipes(),
        _firestoreDataSource.getUserCustomRecipes(userId),
      ]);

      final standardRecipes = results[0];
      final customRecipes = results[1];
      final allCloudRecipes = [...standardRecipes, ...customRecipes];

      final db = await _dbHelper.database;
      
      await db.transaction((txn) async {
        for (var recipe in allCloudRecipes) {
          await txn.insert(
            'recipes',
            recipe.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          final ingredients = await _firestoreDataSource.getIngredientsForRecipe(
            recipeId: recipe.id,
            isCustom: recipe.isCustom,
            userId: userId,
          );

          await txn.delete(
            'recipe_ingredients',
            where: 'recipeId = ?',
            whereArgs: [recipe.id],
          );

          for (var ing in ingredients) {
            if (ing.quantity > 0) {
              final ingToSave = IngredientInRecipe(
                id: ing.id,
                recipeId: recipe.id,
                ingredientId: ing.ingredientId,
                quantity: ing.quantity,
                ingredientPhotoUrl: ing.ingredientPhotoUrl,
              );
              await txn.insert(
                'recipe_ingredients',
                ingToSave.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      });
      
      debugPrint('Remote recipes fetch & merge completed.');
    } catch (e) {
      debugPrint('Sync/Fetch error (Recipes): $e');
    }

    return getLocalRecipes();
  }

  Future<Recipe?> getRecipeById(String id) async {
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
        ri.ingredientPhotoUrl,
        i.name as ingredientName,
        i.unit as ingredientUnit,
        i.photoPath as ingredientPhoto,
        i.photoUrl as masterPhotoUrl
      FROM recipe_ingredients ri
      LEFT JOIN ingredients i ON ri.ingredientId = i.id
      WHERE ri.recipeId = ?
    ''', [recipeId]);

    return result.map((json) {
      final masterUrl = json['masterPhotoUrl'] as String?;
      
      return IngredientInRecipe.fromMap(json).copyWith(
        ingredientPhotoUrl: masterUrl ?? json['ingredientPhotoUrl'] as String?,
      );
    }).toList();
  }

  Future<void> addRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert(
        'recipes',
        recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var ingredient in ingredients) {
        if (ingredient.quantity > 0) {
          await txn.insert('recipe_ingredients', {
            'id': ingredient.id,
            'recipeId': recipe.id,
            'ingredientId': ingredient.ingredientId,
            'quantity': ingredient.quantity,
          });
        }
      }
    });

    await _addToSyncQueue(
      action: _actionCreate,
      docId: recipe.id,
      recipe: recipe,
      ingredients: ingredients.where((i) => i.quantity > 0).toList(),
    );
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
        if (ingredient.quantity > 0) {
          await txn.insert('recipe_ingredients', {
            'id': ingredient.id,
            'recipeId': recipe.id,
            'ingredientId': ingredient.ingredientId,
            'quantity': ingredient.quantity,
          });
        }
      }
    });

    await _addToSyncQueue(
      action: _actionUpdate,
      docId: recipe.id,
      recipe: recipe,
      ingredients: ingredients.where((i) => i.quantity > 0).toList(),
    );
  }

  Future<void> deleteRecipe(String id) async {
    final db = await _dbHelper.database;

    final recipeMap = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    if (recipeMap.isEmpty) return;
    final recipe = Recipe.fromMap(recipeMap.first);

    if (recipe.photoPath != null) {
      try {
        final localFile = File(recipe.photoPath!);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local recipe file: $e');
      }
    }

    await db.delete('recipe_ingredients', where: 'recipeId = ?', whereArgs: [id]);
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);

    await _addToSyncQueue(
      action: _actionDelete,
      docId: id,
      recipe: recipe,
      ingredients: [],
    );
  }

  // Helper Methods
  Future<List<Ingredient>> getAllIngredients() async {
    final db = await _dbHelper.database;
    final result = await db.query('ingredients', orderBy: 'name ASC');
    return result.map((json) => Ingredient.fromMap(json)).toList();
  }

  Future<List<String>> getAvailableRecipeIds() async {
    final db = await _dbHelper.database;
    final pantryItems = await db.query('ingredients');
    final Map<String, double> pantryMap = {};
    
    for (var item in pantryItems) {
      final id = item['id'] as String;
      final qty = (item['quantity'] as num).toDouble();
      pantryMap[id] = qty;
    }

    final allNeeds = await db.rawQuery('SELECT * FROM recipe_ingredients');
    final Map<String, List<Map<String, dynamic>>> recipeRequirements = {};
    
    for (var row in allNeeds) {
      final recipeId = row['recipeId'] as String;
      if (!recipeRequirements.containsKey(recipeId)) {
        recipeRequirements[recipeId] = [];
      }
      recipeRequirements[recipeId]!.add(row);
    }

    final List<String> availableIds = [];

    for (var recipeId in recipeRequirements.keys) {
      bool canCook = true;
      final requirements = recipeRequirements[recipeId]!;

      for (var req in requirements) {
        final ingId = req['ingredientId'] as String;
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
  
  Future<List<String>> getRecipeIdsByIngredients(List<String> ingredientNames) async {
    final db = await _dbHelper.database;
    if (ingredientNames.isEmpty) return [];

    final placeholders = List.filled(ingredientNames.length, '?').join(',');
    final ingredientsResult = await db.query(
      'ingredients',
      columns: ['id'],
      where: 'name IN ($placeholders)',
      whereArgs: ingredientNames,
    );
    
    final ingredientIds = ingredientsResult.map((e) => e['id'] as String).toList();
    if (ingredientIds.isEmpty) return [];

    final ingPlaceholders = List.filled(ingredientIds.length, '?').join(',');
    final result = await db.query(
      'recipe_ingredients',
      columns: ['recipeId'],
      where: 'ingredientId IN ($ingPlaceholders)',
      whereArgs: ingredientIds,
      distinct: true,
    );
    
    return result.map((e) => e['recipeId'] as String).toList();
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String docId,
    required Recipe recipe,
    required List<IngredientInRecipe> ingredients,
  }) async {
    final db = await _dbHelper.database;
    
    final Map<String, dynamic> complexData = {
      'recipe': recipe.toMap(),
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
    };

    try {
      await db.insert(
        'pending_actions',
        {
          'id': const Uuid().v4(),
          'action': action,
          'collection': _collectionRecipes,
          'docId': docId,
          'data': jsonEncode(complexData),
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Recipe operation added to sync queue: $action $docId');
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
    }
  }
}