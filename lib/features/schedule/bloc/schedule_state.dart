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
  final List<MealPlanEntry> allMeals;
  final List<MealPlanEntry> dayMeals;
  final DateTime selectedDate;

  const ScheduleLoaded({
    required this.allMeals,
    required this.dayMeals,
    required this.selectedDate,
  });

  @override
  List<Object> get props => [allMeals, dayMeals, selectedDate];
  
  ScheduleLoaded copyWith({
    List<MealPlanEntry>? allMeals,
    List<MealPlanEntry>? dayMeals,
    DateTime? selectedDate,
  }) {
    return ScheduleLoaded(
      allMeals: allMeals ?? this.allMeals,
      dayMeals: dayMeals ?? this.dayMeals,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object> get props => [message];
}