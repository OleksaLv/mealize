import 'package:equatable/equatable.dart';
import '../data/ingredient_model.dart';

abstract class PantryState extends Equatable {
  const PantryState();

  @override
  List<Object> get props => [];
}

class PantryInitial extends PantryState {}

class PantryLoading extends PantryState {}

class PantryLoaded extends PantryState {
  final List<Ingredient> ingredients;

  const PantryLoaded(this.ingredients);

  @override
  List<Object> get props => [ingredients];
}

class PantryError extends PantryState {
  final String message;

  const PantryError(this.message);

  @override
  List<Object> get props => [message];
}