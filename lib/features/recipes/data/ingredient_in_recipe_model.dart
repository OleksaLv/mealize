import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class IngredientInRecipe {
  final String id;
  final String recipeId;
  final String ingredientId;
  final int quantity;

  final String? ingredientName;
  final String? ingredientUnit;
  final String? ingredientPhoto;
  final String? ingredientPhotoUrl;

  IngredientInRecipe({
    String? id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    this.ingredientName,
    this.ingredientUnit,
    this.ingredientPhoto,
    this.ingredientPhotoUrl,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'ingredientId': ingredientId,
      'quantity': quantity,
      'ingredientPhotoUrl': ingredientPhotoUrl,
    };
  }

  factory IngredientInRecipe.fromMap(Map<String, dynamic> map) {
    return IngredientInRecipe(
      id: map['id'] as String,
      recipeId: map['recipeId'] as String,
      ingredientId: map['ingredientId'] as String,
      quantity: (map['quantity'] as num).toInt(),
      ingredientName: map['ingredientName'] as String?,
      ingredientUnit: map['ingredientUnit'] as String?,
      ingredientPhoto: map['ingredientPhoto'] as String?,
      ingredientPhotoUrl: map['ingredientPhotoUrl'] as String?,
    );
  }

  factory IngredientInRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IngredientInRecipe(
      id: doc.id,
      recipeId: '',
      ingredientId: data['ingredientId'] ?? '',
      quantity: (data['quantity'] as num).toInt(),
      ingredientName: data['name'],
      ingredientUnit: data['unit'],
      ingredientPhotoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ingredientId': ingredientId,
      'quantity': quantity,
      'name': ingredientName,
      'unit': ingredientUnit,
      'photoUrl': ingredientPhotoUrl,
    };
  }

  IngredientInRecipe copyWith({
    String? id,
    String? recipeId,
    String? ingredientId,
    int? quantity,
    String? ingredientName,
    String? ingredientUnit,
    String? ingredientPhoto,
    String? ingredientPhotoUrl,
  }) {
    return IngredientInRecipe(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientUnit: ingredientUnit ?? this.ingredientUnit,
      ingredientPhoto: ingredientPhoto ?? this.ingredientPhoto,
      ingredientPhotoUrl: ingredientPhotoUrl ?? this.ingredientPhotoUrl,
    );
  }
}