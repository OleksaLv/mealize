import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_model.dart';
import 'ingredient_in_recipe_model.dart';

class FirestoreRecipesDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helpers
  CollectionReference<Recipe> _getStandardRecipesRef() {
    return _firestore.collection('recipes').withConverter<Recipe>(
          fromFirestore: (snapshot, _) => Recipe.fromFirestore(snapshot),
          toFirestore: (recipe, _) => recipe.toFirestore(),
        );
  }

  CollectionReference<Recipe> _getUserCustomRecipesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_recipes')
        .withConverter<Recipe>(
          fromFirestore: (snapshot, _) => Recipe.fromFirestore(snapshot),
          toFirestore: (recipe, _) => recipe.toFirestore(),
        );
  }

  // Read Methods
  Future<List<Recipe>> getStandardRecipes() async {
    try {
      final snapshot = await _getStandardRecipesRef().get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to load standard recipes: $e');
    }
  }

  Future<List<Recipe>> getUserCustomRecipes(String userId) async {
    try {
      final snapshot = await _getUserCustomRecipesRef(userId).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to load custom recipes: $e');
    }
  }

  Future<List<IngredientInRecipe>> getIngredientsForRecipe({
    required String recipeId,
    bool isCustom = false,
    String? userId,
  }) async {
    try {
      Query query;

      if (isCustom) {
        if (userId == null) {
          throw Exception('UserId is required for custom recipes');
        }
        query = _getUserCustomRecipesRef(userId)
            .doc(recipeId)
            .collection('ingredientsInRecipe');
      } else {
        query = _getStandardRecipesRef()
            .doc(recipeId)
            .collection('ingredientsInRecipe');
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => IngredientInRecipe.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load ingredients for recipe: $e');
    }
  }

  // Write Methods
  Future<void> addCustomRecipe(
    String userId, 
    Recipe recipe, 
    List<IngredientInRecipe> ingredients
  ) async {
    try {
      final batch = _firestore.batch();

      final recipeRef = _getUserCustomRecipesRef(userId).doc(recipe.id);
      batch.set(recipeRef, recipe);

      for (var ingredient in ingredients) {
        final ingRef = recipeRef.collection('ingredientsInRecipe').doc(); 
        batch.set(ingRef, ingredient.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add custom recipe: $e');
    }
  }

  Future<void> updateCustomRecipe(
    String userId, 
    Recipe recipe, 
    List<IngredientInRecipe> ingredients
  ) async {
    try {
      final recipeRef = _getUserCustomRecipesRef(userId).doc(recipe.id);
      
      final oldIngredientsSnapshot = await recipeRef.collection('ingredientsInRecipe').get();

      final batch = _firestore.batch();

      batch.set(recipeRef, recipe, SetOptions(merge: true));

      for (var doc in oldIngredientsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (var ingredient in ingredients) {
        final ingRef = recipeRef.collection('ingredientsInRecipe').doc();
        batch.set(ingRef, ingredient.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update custom recipe: $e');
    }
  }

  Future<void> deleteCustomRecipe(String userId, String recipeId) async {
    try {
      final recipeRef = _getUserCustomRecipesRef(userId).doc(recipeId);
      
      final ingredientsSnapshot = await recipeRef.collection('ingredientsInRecipe').get();
      
      final batch = _firestore.batch();

      for (var doc in ingredientsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(recipeRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete custom recipe: $e');
    }
  }
}