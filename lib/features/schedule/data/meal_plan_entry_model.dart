import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MealPlanEntry {
  final String id;
  final String recipeId;
  final DateTime dateTime;
  
  final String? recipeName;
  final String? recipePhotoPath;
  final String? recipePhotoUrl;
  
  MealPlanEntry({
    String? id,
    required this.recipeId,
    required this.dateTime,
    this.recipeName,
    this.recipePhotoPath,
    this.recipePhotoUrl,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'dateTime': dateTime.toIso8601String(),
      'recipePhotoUrl': recipePhotoUrl,
    };
  }

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    return MealPlanEntry(
      id: map['id'] as String,
      recipeId: map['recipeId'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      recipeName: map['recipeName'] as String?,
      recipePhotoPath: map['recipePhotoPath'] as String?, 
      recipePhotoUrl: map['recipePhotoUrl'] as String?, 
    );
  }

  factory MealPlanEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime date = DateTime.now();
    if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      date = DateTime.parse(data['date']);
    }

    return MealPlanEntry(
      id: doc.id,
      recipeId: data['recipeId'] ?? '',
      dateTime: date,
      recipeName: data['recipeName'],
      recipePhotoUrl: data['recipePhotoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipeId': recipeId,
      'date': Timestamp.fromDate(dateTime),
      'recipeName': recipeName,
      'recipePhotoUrl': recipePhotoUrl,
    };
  }
}