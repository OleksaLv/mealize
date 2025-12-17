import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/services/sync_manager.dart';
import 'firestore_schedule_data_source.dart';
import 'meal_plan_entry_model.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreScheduleDataSource _firestoreDataSource =
      FirestoreScheduleDataSource();
  
  final SyncManager _syncManager = SyncManager();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _actionCreate = 'CREATE';
  static const String _actionUpdate = 'UPDATE';
  static const String _actionDelete = 'DELETE';
  static const String _collectionSchedule = 'schedule';

  Future<List<MealPlanEntry>> getLocalMeals() async {
    final db = await _dbHelper.database;
    
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
      LEFT JOIN recipes r ON s.recipeId = r.id
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

  Future<List<MealPlanEntry>> syncAndFetchRemote() async {
    final hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      return getLocalMeals();
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return getLocalMeals();

    try {
      await _syncManager.syncPendingActions();

      final cloudSchedule = await _firestoreDataSource.getSchedule(userId);

      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.delete('schedule');

        for (var meal in cloudSchedule) {
          await txn.insert(
            'schedule',
            meal.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      
      debugPrint('Remote schedule fetch & merge completed.');
    } catch (e) {
      debugPrint('Sync/Fetch error (Schedule): $e');
    }

    return getLocalMeals();
  }

  Future<void> addMeal(MealPlanEntry meal) async {
    final db = await _dbHelper.database;

    await db.insert(
      'schedule',
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _addToSyncQueue(
      action: _actionCreate,
      docId: meal.id,
      data: meal.toMap(),
    );
  }

  Future<void> updateMeal(MealPlanEntry meal) async {
    final db = await _dbHelper.database;

    await db.update(
      'schedule',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );

    await _addToSyncQueue(
      action: _actionUpdate,
      docId: meal.id,
      data: meal.toMap(),
    );
  }

  Future<void> deleteMeal(String id) async {
    final db = await _dbHelper.database;

    final maps = await db.query('schedule', where: 'id = ?', whereArgs: [id]);
    Map<String, dynamic> backupData = {};
    if (maps.isNotEmpty) {
      backupData = maps.first;
    }

    await db.delete('schedule', where: 'id = ?', whereArgs: [id]);

    await _addToSyncQueue(
      action: _actionDelete,
      docId: id,
      data: backupData,
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