import 'package:equatable/equatable.dart';
import '../data/meal_plan_entry_model.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];
}

class ScheduleInitial extends ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<MealPlanEntry> meals;
  final DateTime selectedDate;

  const ScheduleLoaded(this.meals, this.selectedDate);

  @override
  List<Object> get props => [meals, selectedDate];
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object> get props => [message];
}