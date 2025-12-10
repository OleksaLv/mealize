import 'package:equatable/equatable.dart';
import '../data/recipe_model.dart';

abstract class RecipesState extends Equatable {
  const RecipesState();

  @override
  List<Object> get props => [];
}

class RecipesInitial extends RecipesState {}

class RecipesLoading extends RecipesState {}

class RecipesLoaded extends RecipesState {
  final List<Recipe> recipes;

  const RecipesLoaded(this.recipes);

  @override
  List<Object> get props => [recipes];
}

class RecipesError extends RecipesState {
  final String message;

  const RecipesError(this.message);

  @override
  List<Object> get props => [message];
}