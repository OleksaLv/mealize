import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyMealNotifEnabled = 'meal_notif_enabled';
  static const _keyMealNotifTime = 'meal_notif_time';
  static const _keyPurchaseNotifEnabled = 'purchase_notif_enabled';
  static const _keyPurchaseNotifTime = 'purchase_notif_time';
  static const _keyPurchaseDaysCount = 'purchase_days_count';

  Future<void> saveMealNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMealNotifEnabled, enabled);
  }

  Future<void> saveMealTime(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMealNotifTime, minutes);
  }

  Future<void> savePurchaseNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPurchaseNotifEnabled, enabled);
  }

  Future<void> savePurchaseTime(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPurchaseNotifTime, hours);
  }

  Future<void> savePurchaseDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPurchaseDaysCount, days);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mealNotifEnabled': prefs.getBool(_keyMealNotifEnabled) ?? true,
      'mealNotifTime': prefs.getInt(_keyMealNotifTime) ?? 60,
      'purchaseNotifEnabled': prefs.getBool(_keyPurchaseNotifEnabled) ?? true,
      'purchaseNotifTime': prefs.getInt(_keyPurchaseNotifTime) ?? 19,
      'purchaseDaysCount': prefs.getInt(_keyPurchaseDaysCount) ?? 3,
    };
  }
}