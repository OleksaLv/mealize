class MealPlanEntry {
  final int? id;
  final int recipeId;
  final DateTime dateTime;
  
  final String? recipeName;
  final String? recipePhotoPath;

  const MealPlanEntry({
    this.id,
    required this.recipeId,
    required this.dateTime,
    this.recipeName,
    this.recipePhotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    return MealPlanEntry(
      id: map['id'] as int?,
      recipeId: map['recipeId'] as int,
      dateTime: DateTime.parse(map['dateTime'] as String),

      recipeName: map['recipeName'] as String?,
      recipePhotoPath: map['recipePhotoPath'] as String?,
    );
  }
}