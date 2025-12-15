import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/db_helper.dart';
import 'firestore_schedule_data_source.dart';
import 'meal_plan_entry_model.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreScheduleDataSource _firestoreDataSource =
      FirestoreScheduleDataSource();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _actionCreate = 'CREATE';
  static const String _actionUpdate = 'UPDATE';
  static const String _actionDelete = 'DELETE';
  static const String _collectionSchedule = 'schedule';

  Future<List<MealPlanEntry>> getAllMeals() async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      try {
        final cloudSchedule = await _firestoreDataSource.getSchedule(userId);

        await db.transaction((txn) async {
          for (var meal in cloudSchedule) {
            await txn.insert(
              'schedule',
              meal.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      } catch (e) {
        debugPrint('Offline mode (Schedule): Using local data only. Error: $e');
      }
    }

    final result = await db.rawQuery('''
      SELECT 
        s.id, 
        s.recipeId, 
        s.dateTime, 
        s.recipePhotoUrl,
        r.name as recipeName, 
        r.photoPath as recipePhotoPath,
        r.photoUrl as masterPhotoUrl
      FROM schedule s
      INNER JOIN recipes r ON s.recipeId = r.id
    ''');

    return result.map((json) {
      final masterUrl = json['masterPhotoUrl'] as String?;
      final entryUrl = json['recipePhotoUrl'] as String?;
      
      return MealPlanEntry.fromMap(json).copyWith(
        recipeName: json['recipeName'] as String?,
        recipePhotoPath: json['recipePhotoPath'] as String?,
        recipePhotoUrl: masterUrl ?? entryUrl, 
      );
    }).toList();
  }

  Future<void> addMeal(MealPlanEntry meal) async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    await db.insert(
      'schedule',
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (userId != null) {
      try {
        await _firestoreDataSource.addMeal(userId, meal);
      } catch (e) {
        debugPrint('Failed to sync addMeal. Adding to queue... Error: $e');
        await _addToSyncQueue(
          action: _actionCreate,
          docId: meal.id,
          data: meal.toMap(),
        );
      }
    }
  }

  Future<void> updateMeal(MealPlanEntry meal) async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    await db.update(
      'schedule',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );

    if (userId != null) {
      try {
        await _firestoreDataSource.updateMeal(userId, meal);
      } catch (e) {
        debugPrint('Failed to sync updateMeal. Adding to queue... Error: $e');
        await _addToSyncQueue(
          action: _actionUpdate,
          docId: meal.id,
          data: meal.toMap(),
        );
      }
    }
  }

  Future<void> deleteMeal(String id) async {
    final db = await _dbHelper.database;
    final userId = _auth.currentUser?.uid;

    final maps = await db.query('schedule', where: 'id = ?', whereArgs: [id]);
    Map<String, dynamic>? backupData;
    if (maps.isNotEmpty) {
      backupData = maps.first;
    }

    await db.delete('schedule', where: 'id = ?', whereArgs: [id]);

    if (userId != null) {
      try {
        await _firestoreDataSource.deleteMeal(userId, id);
      } catch (e) {
        debugPrint('Failed to sync deleteMeal. Adding to queue... Error: $e');
        if (backupData != null) {
          await _addToSyncQueue(
            action: _actionDelete,
            docId: id,
            data: backupData,
          );
        }
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
          'collection': _collectionSchedule,
          'docId': docId,
          'data': jsonEncode(data),
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Schedule operation added to sync queue: $action $docId');
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
    }
  }
}