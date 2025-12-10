import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/schedule_repository.dart';
import '../data/meal_plan_entry_model.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleCubit(this._repository) : super(ScheduleInitial());

  Future<void> loadSchedule(DateTime date) async {
    emit(ScheduleLoading());
    try {
      final meals = await _repository.getMealsForDate(date);
      emit(ScheduleLoaded(meals, date));
    } catch (e) {
      emit(ScheduleError('Failed to load schedule: $e'));
    }
  }

  Future<void> deleteMeal(int id, DateTime currentDate) async {
    try {
      await _repository.deleteMeal(id);
      loadSchedule(currentDate);
    } catch (e) {
      emit(ScheduleError('Failed to delete meal: $e'));
    }
  }
}