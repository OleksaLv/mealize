class Recipe {
  final int? id;
  final String name;
  final String? photoPath;
  final int cookingTime;
  final String description;
  final bool isCustom;

  const Recipe({
    this.id,
    required this.name,
    this.photoPath,
    required this.cookingTime,
    required this.description,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
      'cookingTime': cookingTime,
      'description': description,
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      photoPath: map['photoPath'] as String?,
      cookingTime: map['cookingTime'] as int,
      description: map['description'] as String,
      isCustom: (map['isCustom'] as int) == 1,
    );
  }
}