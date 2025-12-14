import 'package:cloud_firestore/cloud_firestore.dart';
import 'meal_plan_entry_model.dart';

class FirestoreScheduleDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<MealPlanEntry> _getScheduleRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('schedule')
        .withConverter<MealPlanEntry>(
          fromFirestore: (snapshot, _) => MealPlanEntry.fromFirestore(snapshot),
          toFirestore: (entry, _) => entry.toFirestore(),
        );
  }

  Future<List<MealPlanEntry>> getSchedule(String userId) async {
    try {
      final snapshot = await _getScheduleRef(userId).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to load schedule: $e');
    }
  }

  Future<void> addMeal(String userId, MealPlanEntry meal) async {
    try {
      await _getScheduleRef(userId).doc(meal.id).set(meal);
    } catch (e) {
      throw Exception('Failed to add meal to schedule: $e');
    }
  }

  Future<void> updateMeal(String userId, MealPlanEntry meal) async {
    try {
      await _getScheduleRef(userId).doc(meal.id).set(meal, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update meal in schedule: $e');
    }
  }

  Future<void> deleteMeal(String userId, String mealId) async {
    try {
      await _getScheduleRef(userId).doc(mealId).delete();
    } catch (e) {
      throw Exception('Failed to delete meal from schedule: $e');
    }
  }
}