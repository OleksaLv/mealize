import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSettingsDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference get _mealizeRef => _firestore.collection('mealize').doc('v1');

  DocumentReference<Map<String, dynamic>> _getSettingsRef(String userId) {
    return _mealizeRef
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences');
  }

  Future<Map<String, dynamic>> getSettings(String userId) async {
    try {
      final snapshot = await _getSettingsRef(userId).get();
      return snapshot.data() ?? {};
    } catch (e) {
      throw Exception('Failed to fetch settings: $e');
    }
  }

  Future<void> updateSettings(String userId, Map<String, dynamic> data) async {
    try {
      await _getSettingsRef(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }
}