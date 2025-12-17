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
      final localRecipes = await _repository.getLocalRecipes();
      emit(RecipesLoaded(localRecipes));

      final remoteRecipes = await _repository.syncAndFetchRemote();
      emit(RecipesLoaded(remoteRecipes));
      
    } catch (e) {
      if (state is! RecipesLoaded) {
        emit(RecipesError('Failed to load recipes: $e'));
      }
    }
  }

  Future<void> addRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    try {
      await _repository.addRecipe(recipe, ingredients);
      
      final localRecipes = await _repository.getLocalRecipes();
      emit(RecipesLoaded(localRecipes));
      
      final remoteRecipes = await _repository.syncAndFetchRemote();
      emit(RecipesLoaded(remoteRecipes));
    } catch (e) {
      emit(RecipesError('Failed to add recipe: $e'));
      loadRecipes(); 
    }
  }

  Future<void> updateRecipe(Recipe recipe, List<IngredientInRecipe> ingredients) async {
    try {
      await _repository.updateRecipe(recipe, ingredients);
      
      final localRecipes = await _repository.getLocalRecipes();
      emit(RecipesLoaded(localRecipes));
      
      final remoteRecipes = await _repository.syncAndFetchRemote();
      emit(RecipesLoaded(remoteRecipes));
    } catch (e) {
      emit(RecipesError('Failed to update recipe: $e'));
      loadRecipes();
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      await _repository.deleteRecipe(id);
      
      final localRecipes = await _repository.getLocalRecipes();
      emit(RecipesLoaded(localRecipes));
      
      final remoteRecipes = await _repository.syncAndFetchRemote();
      emit(RecipesLoaded(remoteRecipes));
    } catch (e) {
      emit(RecipesError('Failed to delete recipe: $e'));
      loadRecipes();
    }
  }

  Future<List<IngredientInRecipe>> getIngredients(String recipeId) {
    return _repository.getIngredientsForRecipe(recipeId);
  }
}