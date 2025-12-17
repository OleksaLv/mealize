import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/services/sync_manager.dart';
import 'firestore_ingredients_data_source.dart';
import 'ingredient_model.dart';

class PantryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreIngredientsDataSource _firestoreDataSource =
      FirestoreIngredientsDataSource();
  
  final SyncManager _syncManager = SyncManager();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _actionCreate = 'CREATE';
  static const String _actionUpdate = 'UPDATE';
  static const String _actionDelete = 'DELETE';
  static const String _collectionPantry = 'pantry';

  Future<List<Ingredient>> getLocalPantryItems() async {
    final db = await _dbHelper.database;
    final result = await db.query('ingredients', orderBy: 'name ASC');
    return result.map((json) => Ingredient.fromMap(json)).toList();
  }

  Future<List<Ingredient>> syncAndFetchRemote() async {
    final hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      return getLocalPantryItems();
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return getLocalPantryItems();

    try {
      await _syncManager.syncPendingActions();

      final results = await Future.wait([
        _firestoreDataSource.getStandardIngredients(),
        _firestoreDataSource.getUserCustomIngredients(userId),
        _firestoreDataSource.getPantry(userId),
      ]);

      final standards = results[0];
      final customs = results[1];
      final pantryItems = results[2];

      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        for (var item in standards) {
          await txn.insert(
            'ingredients',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        for (var item in customs) {
          await txn.insert(
            'ingredients',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        final pantryMap = {for (var item in pantryItems) item.id: item};
        
        final localData = await txn.query('ingredients');
        
        for (var row in localData) {
          final id = row['id'] as String;
          final remoteItem = pantryMap[id];
          
          if (remoteItem != null) {
            await txn.rawUpdate(
              'UPDATE ingredients SET quantity = ?, notes = ? WHERE id = ?',
              [remoteItem.quantity, remoteItem.notes, id],
            );
          } else {
             await txn.rawUpdate(
              'UPDATE ingredients SET quantity = 0 WHERE id = ?',
              [id],
            );
          }
        }
      });
      
      debugPrint('Remote fetch & merge completed.');
    } catch (e) {
      debugPrint('Sync/Fetch error: $e');
    }

    return getLocalPantryItems();
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    final db = await _dbHelper.database;
    
    await db.insert(
      'ingredients',
      ingredient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _addToSyncQueue(
      action: _actionCreate,
      docId: ingredient.id,
      data: ingredient.toMap(),
    );
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    final db = await _dbHelper.database;

    await db.update(
      'ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );

    await _addToSyncQueue(
      action: _actionUpdate,
      docId: ingredient.id,
      data: ingredient.toMap(),
    );
  }

  Future<void> deleteIngredient(String id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return;
    final ingredientMap = maps.first;
    final photoPath = ingredientMap['photoPath'] as String?;

    if (photoPath != null) {
      try {
        final localFile = File(photoPath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local file: $e');
      }
    }

    await db.delete(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );

    await _addToSyncQueue(
      action: _actionDelete,
      docId: id,
      data: ingredientMap, 
    );
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final db = await _dbHelper.database;
    
    try {
      await db.insert(
        'pending_actions',
        {
          'id': const Uuid().v4(),
          'action': action,
          'collection': _collectionPantry,
          'docId': docId,
          'data': jsonEncode(data),
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Operation added to sync queue: $action $docId');
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
    }
  }
}