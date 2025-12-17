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
      await _loadLocalAndEmit();

      final remoteMeals = await _repository.syncAndFetchRemote();
      
      final currentDate = (state is ScheduleLoaded) 
          ? (state as ScheduleLoaded).selectedDate 
          : DateTime.now();
          
      final dayMeals = _filterMealsForDate(remoteMeals, currentDate);
      
      emit(ScheduleLoaded(
        allMeals: remoteMeals, 
        dayMeals: dayMeals, 
        selectedDate: currentDate
      ));
      
    } catch (e) {
      if (state is! ScheduleLoaded) {
        emit(ScheduleError('Failed to load schedule: $e'));
      }
    }
  }

  Future<void> _loadLocalAndEmit() async {
    final allMeals = await _repository.getLocalMeals();
    final currentDate = (state is ScheduleLoaded) 
        ? (state as ScheduleLoaded).selectedDate 
        : DateTime.now();
    final dayMeals = _filterMealsForDate(allMeals, currentDate);
    
    emit(ScheduleLoaded(
      allMeals: allMeals, 
      dayMeals: dayMeals, 
      selectedDate: currentDate
    ));
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
      _refreshAndSync();
    } catch (e) {
      emit(ScheduleError('Failed to add meal: $e'));
    }
  }

  Future<void> updateMeal(MealPlanEntry meal) async {
    try {
      await _repository.updateMeal(meal);
      _refreshAndSync();
    } catch (e) {
      emit(ScheduleError('Failed to update meal: $e'));
    }
  }

  Future<void> deleteMeal(String id) async {
    try {
      await _repository.deleteMeal(id);
      _refreshAndSync();
    } catch (e) {
      emit(ScheduleError('Failed to delete meal: $e'));
    }
  }
  
  Future<void> _refreshAndSync() async {
    await _loadLocalAndEmit();
    
    final remoteMeals = await _repository.syncAndFetchRemote();
    
    final currentDate = (state is ScheduleLoaded) 
        ? (state as ScheduleLoaded).selectedDate 
        : DateTime.now();
    final dayMeals = _filterMealsForDate(remoteMeals, currentDate);
    
    emit(ScheduleLoaded(
      allMeals: remoteMeals,
      dayMeals: dayMeals,
      selectedDate: currentDate,
    ));
  }

  List<MealPlanEntry> _filterMealsForDate(List<MealPlanEntry> meals, DateTime date) {
    return meals.where((meal) => 
      meal.dateTime.year == date.year && 
      meal.dateTime.month == date.month && 
      meal.dateTime.day == date.day
    ).toList();
  }
}