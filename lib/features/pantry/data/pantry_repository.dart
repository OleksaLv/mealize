import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/services/firebase_storage_service.dart';
import 'firestore_ingredients_data_source.dart';
import 'ingredient_model.dart';

class PantryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreIngredientsDataSource _firestoreDataSource =
      FirestoreIngredientsDataSource();
  
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _actionCreate = 'CREATE';
  static const String _actionUpdate = 'UPDATE';
  static const String _actionDelete = 'DELETE';
  static const String _collectionPantry = 'pantry';

  Future<List<Ingredient>> getPantryItems() async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      try {
        final results = await Future.wait([
          _firestoreDataSource.getStandardIngredients(),
          _firestoreDataSource.getUserCustomIngredients(userId),
          _firestoreDataSource.getPantry(userId),
        ]);

        final standards = results[0];
        final customs = results[1];
        final pantryItems = results[2];

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

          for (var item in pantryItems) {
            await txn.rawUpdate(
              'UPDATE ingredients SET quantity = ?, notes = ? WHERE id = ?',
              [item.quantity, item.notes, item.id],
            );
          }
        });
      } catch (e) {
        debugPrint('Offline mode: Using local data only. Error: $e');
      }
    }

    final result = await db.query('ingredients', orderBy: 'name ASC');
    return result.map((json) => Ingredient.fromMap(json)).toList();
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    await db.insert(
      'ingredients',
      ingredient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (userId != null) {
      try {
        String? cloudPhotoUrl = ingredient.photoUrl;

        if (ingredient.photoPath != null &&
            (ingredient.photoUrl == null || ingredient.photoUrl!.isEmpty)) {
          final file = File(ingredient.photoPath!);
          if (file.existsSync()) {
            cloudPhotoUrl =
                await _storageService.uploadFile(file, 'ingredients');
          }
        }

        final syncedIngredient = ingredient.copyWith(photoUrl: cloudPhotoUrl);

        if (ingredient.isCustom) {
          await _firestoreDataSource.saveCustomIngredient(
              userId, syncedIngredient);
        }
        
        if (ingredient.quantity > 0) {
          await _firestoreDataSource.savePantryItem(userId, syncedIngredient);
        }

        if (cloudPhotoUrl != null && cloudPhotoUrl != ingredient.photoUrl) {
          await db.update(
            'ingredients',
            {'photoUrl': cloudPhotoUrl},
            where: 'id = ?',
            whereArgs: [ingredient.id],
          );
        }

      } catch (e) {
        debugPrint('Failed to sync addIngredient. Adding to queue... Error: $e');
        await _addToSyncQueue(
          action: _actionCreate,
          docId: ingredient.id,
          data: ingredient.toMap(),
        );
      }
    }
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    await db.update(
      'ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );

    if (userId != null) {
      try {
        String? cloudPhotoUrl = ingredient.photoUrl;

        if (ingredient.photoPath != null) {
          final file = File(ingredient.photoPath!);
          if (file.existsSync()) {
            cloudPhotoUrl =
                await _storageService.uploadFile(file, 'ingredients');
          }
        }

        final syncedIngredient = ingredient.copyWith(photoUrl: cloudPhotoUrl);

        if (ingredient.isCustom) {
          await _firestoreDataSource.saveCustomIngredient(
              userId, syncedIngredient);
        }
        
        await _firestoreDataSource.savePantryItem(userId, syncedIngredient);

      } catch (e) {
        debugPrint(
            'Failed to sync updateIngredient. Adding to queue... Error: $e');
        await _addToSyncQueue(
          action: _actionUpdate,
          docId: ingredient.id,
          data: ingredient.toMap(),
        );
      }
    }
  }

  Future<void> deleteIngredient(String id) async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return;
    final ingredient = Ingredient.fromMap(maps.first);

    if (ingredient.photoPath != null) {
      try {
        final localFile = File(ingredient.photoPath!);
        if (await localFile.exists()) {
          await localFile.delete();
          debugPrint('Local file deleted: ${ingredient.photoPath}');
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

    if (userId != null) {
      try {
        await _firestoreDataSource.deletePantryItem(userId, id);

        if (ingredient.isCustom) {
          await _firestoreDataSource.deleteCustomIngredient(userId, id);
          if (ingredient.photoUrl != null) {
            await _storageService.deleteFile(ingredient.photoUrl!);
          }
        }
      } catch (e) {
        debugPrint(
            'Failed to sync deleteIngredient. Adding to queue... Error: $e');
        await _addToSyncQueue(
          action: _actionDelete,
          docId: id,
          data: ingredient.toMap(), 
        );
      }
    }
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
      debugPrint('Error adding to sync queue (Table might be missing): $e');
    }
  }
}