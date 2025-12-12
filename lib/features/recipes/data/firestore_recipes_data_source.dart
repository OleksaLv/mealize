import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_model.dart';
import 'ingredient_in_recipe_model.dart';

class FirestoreRecipesDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Recipe>> getStandardRecipes() async {
    final snapshot = await _firestore.collection('recipes').get();
    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  Future<List<Recipe>> getUserCustomRecipes(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_recipes')
        .get();
    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  Future<void> addCustomRecipe(String userId, Recipe recipe, List<IngredientInRecipe> ingredients) async {
    final recipeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_recipes')
        .doc(recipe.id);

    final batch = _firestore.batch();
    
    batch.set(recipeRef, recipe.toFirestore());

    for (var ing in ingredients) {
      final ingRef = recipeRef.collection('ingredientsInRecipe').doc();
      batch.set(ingRef, ing.toFirestore());
    }

    await batch.commit();
  }
  
  Future<void> updateCustomRecipe(String userId, Recipe recipe, List<IngredientInRecipe> ingredients) async {
     final recipeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_recipes')
        .doc(recipe.id);
     
     await _firestore.runTransaction((transaction) async {
       transaction.set(recipeRef, recipe.toFirestore());

     });
     
     // Спрощений update (не атомарний, але працює):
     await recipeRef.set(recipe.toFirestore());
     
     // Видаляємо старі піддокументи
     final oldIngredients = await recipeRef.collection('ingredientsInRecipe').get();
     for (var doc in oldIngredients.docs) {
       await doc.reference.delete();
     }
     
     // Додаємо нові
     final batch = _firestore.batch();
     for (var ing in ingredients) {
       final ingRef = recipeRef.collection('ingredientsInRecipe').doc();
       batch.set(ingRef, ing.toFirestore());
     }
     await batch.commit();
  }

  Future<void> deleteCustomRecipe(String userId, String recipeId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_recipes')
        .doc(recipeId)
        .delete();
  }

  // Отримання інгредієнтів для конкретного рецепта
  Future<List<IngredientInRecipe>> getIngredientsForRecipe(String recipeId, {String? userId, bool isCustom = false}) async {
    Query query;
    
    if (isCustom && userId != null) {
      query = _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_recipes')
          .doc(recipeId)
          .collection('ingredientsInRecipe');
    } else {
      query = _firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('ingredientsInRecipe');
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => IngredientInRecipe.fromFirestore(doc)).toList();
  }
}