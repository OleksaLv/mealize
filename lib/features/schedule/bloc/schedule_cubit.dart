import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/schedule_repository.dart';
import '../data/meal_plan_entry_model.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleCubit(this._repository) : super(ScheduleInitial());

  Future<void> loadSchedule() async {
    emit(ScheduleLoading());
    try {
      final allMeals = await _repository.getAllMeals();
      final now = DateTime.now();
      final dayMeals = _filterMealsForDate(allMeals, now);
      
      emit(ScheduleLoaded(
        allMeals: allMeals, 
        dayMeals: dayMeals, 
        selectedDate: now
      ));
    } catch (e) {
      emit(ScheduleError('Failed to load schedule: $e'));
    }
  }

  void selectDate(DateTime date) {
    if (state is ScheduleLoaded) {
      final currentState = state as ScheduleLoaded;
      final dayMeals = _filterMealsForDate(currentState.allMeals, date);
      
      emit(currentState.copyWith(
        dayMeals: dayMeals,
        selectedDate: date,
      ));
    }
  }

  Future<void> addMeal(MealPlanEntry meal) async {
    try {
      await _repository.addMeal(meal);
      _refreshData();
    } catch (e) {
      emit(ScheduleError('Failed to add meal: $e'));
    }
  }

  Future<void> updateMeal(MealPlanEntry meal) async {
    try {
      await _repository.updateMeal(meal);
      _refreshData();
    } catch (e) {
      emit(ScheduleError('Failed to update meal: $e'));
    }
  }

  Future<void> deleteMeal(int id) async {
    try {
      await _repository.deleteMeal(id);
      await _refreshData();
    } catch (e) {
      emit(ScheduleError('Failed to delete meal: $e'));
    }
  }
  
  Future<void> _refreshData() async {
    if (state is ScheduleLoaded) {
      final currentDate = (state as ScheduleLoaded).selectedDate;
      final allMeals = await _repository.getAllMeals();
      final dayMeals = _filterMealsForDate(allMeals, currentDate);
      
      emit(ScheduleLoaded(
        allMeals: allMeals,
        dayMeals: dayMeals,
        selectedDate: currentDate,
      ));
    } else {
      loadSchedule();
    }
  }

  List<MealPlanEntry> _filterMealsForDate(List<MealPlanEntry> meals, DateTime date) {
    return meals.where((meal) => 
      meal.dateTime.year == date.year && 
      meal.dateTime.month == date.month && 
      meal.dateTime.day == date.day
    ).toList();
  }

  Future<void> addMealFromUI(MealPlanEntry meal) async {
    try {
      await _repository.addMeal(meal);
      _refreshData();
    } catch (e) {
      emit(ScheduleError('Failed to add meal: $e'));
    }
  }
}