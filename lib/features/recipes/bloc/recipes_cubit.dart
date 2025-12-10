import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/recipes_repository.dart';
import 'recipes_state.dart';
import '../data/recipe_model.dart';
import '../data/ingredient_in_recipe_model.dart';

class RecipesCubit extends Cubit<RecipesState> {
  final RecipesRepository _repository;

  RecipesCubit(this._repository) : super(RecipesInitial());

  Future<void> loadRecipes() async {
    emit(RecipesLoading());
    try {
      final recipes = await _repository.getRecipes();
      emit(RecipesLoaded(recipes));
    } catch (e) {
      emit(RecipesError('Failed to load recipes: $e'));
    }
  }

  Future<void> addRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    try {
      await _repository.addRecipe(recipe, ingredients);
      loadRecipes();
    } catch (e) {
      emit(RecipesError('Failed to add recipe: $e'));
    }
  }

  Future<void> updateRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    try {
      await _repository.updateRecipe(recipe, ingredients);
      loadRecipes();
    } catch (e) {
      emit(RecipesError('Failed to update recipe: $e'));
    }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      await _repository.deleteRecipe(id);
      loadRecipes();
    } catch (e) {
      emit(RecipesError('Failed to delete recipe: $e'));
    }
  }

  Future<List<IngredientInRecipe>> getIngredients(int recipeId) {
    return _repository.getIngredientsForRecipe(recipeId);
  }
}