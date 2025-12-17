import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient_model.dart';

class FirestoreIngredientsDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference get _mealizeRef => _firestore.collection('mealize').doc('v1');

  // refs
  CollectionReference<Ingredient> _getStandardIngredientsRef() {
    return _mealizeRef.collection('ingredients').withConverter<Ingredient>(
          fromFirestore: (snapshot, _) => Ingredient.fromFirestore(snapshot),
          toFirestore: (ingredient, _) => ingredient.toFirestore(),
        );
  }

  CollectionReference<Ingredient> _getUserCustomIngredientsRef(String userId) {
    return _mealizeRef
        .collection('users')
        .doc(userId)
        .collection('custom_ingredients')
        .withConverter<Ingredient>(
          fromFirestore: (snapshot, _) => Ingredient.fromFirestore(snapshot),
          toFirestore: (ingredient, _) => ingredient.toFirestore(),
        );
  }

  CollectionReference<Ingredient> _getPantryRef(String userId) {
    return _mealizeRef
        .collection('users')
        .doc(userId)
        .collection('pantry')
        .withConverter<Ingredient>(
          fromFirestore: (snapshot, _) => Ingredient.fromFirestore(snapshot),
          toFirestore: (ingredient, _) => ingredient.toFirestore(),
        );
  }

  // Raw ref for writing partial data in Pantry (quantity/notes)
  CollectionReference<Map<String, dynamic>> _getPantryRawRef(String userId) {
    return _mealizeRef
        .collection('users')
        .doc(userId)
        .collection('pantry');
  }

  // read methods
  Future<List<Ingredient>> getStandardIngredients() async {
    try {
      final snapshot = await _getStandardIngredientsRef().get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch standard ingredients: $e');
    }
  }

  Future<List<Ingredient>> getUserCustomIngredients(String userId) async {
    try {
      final snapshot = await _getUserCustomIngredientsRef(userId).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch user custom ingredients: $e');
    }
  }

  Future<List<Ingredient>> getPantry(String userId) async {
    try {
      final snapshot = await _getPantryRef(userId).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch pantry: $e');
    }
  }

  // write methods
  Future<void> saveCustomIngredient(String userId, Ingredient ingredient) async {
    try {
      await _getUserCustomIngredientsRef(userId)
          .doc(ingredient.id)
          .set(ingredient, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save custom ingredient: $e');
    }
  }

  Future<void> deleteCustomIngredient(String userId, String ingredientId) async {
    try {
      await _getUserCustomIngredientsRef(userId).doc(ingredientId).delete();
    } catch (e) {
      throw Exception('Failed to delete custom ingredient: $e');
    }
  }

  Future<void> savePantryItem(String userId, Ingredient item) async {
    try {
      final dataToSave = {
        'quantity': item.quantity,
        'notes': item.notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _getPantryRawRef(userId)
          .doc(item.id)
          .set(dataToSave, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save pantry item: $e');
    }
  }

  Future<void> deletePantryItem(String userId, String itemId) async {
    try {
      await _getPantryRef(userId).doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete pantry item: $e');
    }
  }
}