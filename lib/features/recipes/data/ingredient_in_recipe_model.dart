class IngredientInRecipe {
  final int? id;
  final int recipeId;
  final int ingredientId;
  final int quantity;

  final String? ingredientName;
  final String? ingredientUnit;
  final String? ingredientPhoto;

  const IngredientInRecipe({
    this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,

    this.ingredientName,
    this.ingredientUnit,
    this.ingredientPhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'ingredientId': ingredientId,
      'quantity': quantity,
    };
  }

  factory IngredientInRecipe.fromMap(Map<String, dynamic> map) {
    return IngredientInRecipe(
      id: map['id'] as int?,
      recipeId: map['recipeId'] as int,
      ingredientId: map['ingredientId'] as int,
      quantity: (map['quantity'] as num).toInt(),

      ingredientName: map['ingredientName'] as String?,
      ingredientUnit: map['ingredientUnit'] as String?,
      ingredientPhoto: map['ingredientPhoto'] as String?,
    );
  }
}