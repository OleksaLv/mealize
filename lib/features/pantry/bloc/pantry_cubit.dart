import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ingredient_model.dart';
import '../data/pantry_repository.dart';
import 'pantry_state.dart';

class PantryCubit extends Cubit<PantryState> {
  final PantryRepository _repository;

  PantryCubit(this._repository) : super(PantryInitial());

  Future<void> loadPantryItems() async {
    emit(PantryLoading());
    try {
      final items = await _repository.getPantryItems();
      emit(PantryLoaded(items));
    } catch (e) {
      emit(PantryError('Failed to load pantry items: $e'));
    }
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    try {
      await _repository.addIngredient(ingredient);
      loadPantryItems();
    } catch (e) {
      emit(PantryError('Failed to add ingredient: $e'));
    }
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    try {
      await _repository.updateIngredient(ingredient);
      loadPantryItems();
    } catch (e) {
      emit(PantryError('Failed to update ingredient: $e'));
    }
  }

  Future<void> deleteIngredient(int id) async {
    try {
      await _repository.deleteIngredient(id);
      loadPantryItems();
    } catch (e) {
      emit(PantryError('Failed to delete ingredient: $e'));
    }
  }
}