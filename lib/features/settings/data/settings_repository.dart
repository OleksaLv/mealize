import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/services/sync_manager.dart';
import 'firestore_settings_data_source.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreSettingsDataSource _firestoreDataSource = FirestoreSettingsDataSource();
  
  final SyncManager _syncManager = SyncManager();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Keys for SharedPreferences
  static const _keyMealNotifEnabled = 'meal_notif_enabled';
  static const _keyMealNotifTime = 'meal_notif_time';
  static const _keyPurchaseNotifEnabled = 'purchase_notif_enabled';
  static const _keyPurchaseNotifTime = 'purchase_notif_time';
  static const _keyPurchaseDaysCount = 'purchase_days_count';

  static const String _actionUpdate = 'UPDATE';
  static const String _collectionSettings = 'settings';
  static const String _docIdPreferences = 'preferences';

  Future<Map<String, dynamic>> getLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mealNotifEnabled': prefs.getBool(_keyMealNotifEnabled) ?? true,
      'mealNotifTime': prefs.getInt(_keyMealNotifTime) ?? 60,
      'purchaseNotifEnabled': prefs.getBool(_keyPurchaseNotifEnabled) ?? true,
      'purchaseNotifTime': prefs.getInt(_keyPurchaseNotifTime) ?? 19,
      'purchaseDaysCount': prefs.getInt(_keyPurchaseDaysCount) ?? 3,
    };
  }

  Future<Map<String, dynamic>> syncAndFetchRemote() async {
    final hasConnection = await InternetConnectionChecker().hasConnection;
    if (!hasConnection) {
      return getLocalSettings();
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return getLocalSettings();

    try {
      await _syncManager.syncPendingActions();

      final remoteSettings = await _firestoreDataSource.getSettings(userId);

      if (remoteSettings.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        
        if (remoteSettings.containsKey('mealNotifEnabled')) {
          await prefs.setBool(_keyMealNotifEnabled, remoteSettings['mealNotifEnabled']);
        }
        if (remoteSettings.containsKey('mealNotifTime')) {
          await prefs.setInt(_keyMealNotifTime, remoteSettings['mealNotifTime']);
        }
        if (remoteSettings.containsKey('purchaseNotifEnabled')) {
          await prefs.setBool(_keyPurchaseNotifEnabled, remoteSettings['purchaseNotifEnabled']);
        }
        if (remoteSettings.containsKey('purchaseNotifTime')) {
          await prefs.setInt(_keyPurchaseNotifTime, remoteSettings['purchaseNotifTime']);
        }
        if (remoteSettings.containsKey('purchaseDaysCount')) {
          await prefs.setInt(_keyPurchaseDaysCount, remoteSettings['purchaseDaysCount']);
        }
      }
      
      debugPrint('Remote settings fetch & merge completed.');
    } catch (e) {
      debugPrint('Sync/Fetch error (Settings): $e');
    }

    return getLocalSettings();
  }

  Future<void> saveMealNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMealNotifEnabled, enabled);
    await _addToSyncQueue({'mealNotifEnabled': enabled});
  }

  Future<void> saveMealTime(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMealNotifTime, minutes);
    await _addToSyncQueue({'mealNotifTime': minutes});
  }

  Future<void> savePurchaseNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPurchaseNotifEnabled, enabled);
    await _addToSyncQueue({'purchaseNotifEnabled': enabled});
  }

  Future<void> savePurchaseTime(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPurchaseNotifTime, hours);
    await _addToSyncQueue({'purchaseNotifTime': hours});
  }

  Future<void> savePurchaseDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPurchaseDaysCount, days);
    await _addToSyncQueue({'purchaseDaysCount': days});
  }

  Future<void> _addToSyncQueue(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    try {
      await db.insert(
        'pending_actions',
        {
          'id': const Uuid().v4(),
          'action': _actionUpdate,
          'collection': _collectionSettings,
          'docId': _docIdPreferences, 
          'data': jsonEncode(data),
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Settings update added to sync queue: $data');
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
    }
  }
}