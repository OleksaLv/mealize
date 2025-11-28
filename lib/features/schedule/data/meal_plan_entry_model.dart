class MealPlanEntry {
  final int? id;
  final int recipeId;
  final DateTime date;
  final String time;
  
  final String? recipeName;
  final String? recipePhotoPath;

  const MealPlanEntry({
    this.id,
    required this.recipeId,
    required this.date,
    required this.time,
    this.recipeName,
    this.recipePhotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'date': date.toIso8601String(),
      'time': time,
    };
  }

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    return MealPlanEntry(
      id: map['id'] as int?,
      recipeId: map['recipeId'] as int,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String,

      recipeName: map['recipeName'] as String?,
      recipePhotoPath: map['recipePhotoPath'] as String?,
    );
  }
}