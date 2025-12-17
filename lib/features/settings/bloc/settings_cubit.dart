import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> loadSettings() async {
    await _loadLocalAndEmit();
    
    await _repository.syncAndFetchRemote();
    
    await _loadLocalAndEmit();
  }

  Future<void> _loadLocalAndEmit() async {
    final settings = await _repository.getLocalSettings();
    emit(SettingsState(
      mealNotificationEnabled: settings['mealNotifEnabled'],
      mealNotificationTime: settings['mealNotifTime'],
      purchaseNotificationEnabled: settings['purchaseNotifEnabled'],
      purchaseNotificationTime: settings['purchaseNotifTime'],
      purchaseDaysCount: settings['purchaseDaysCount'],
    ));
  }

  void toggleMealNotification(bool value) {
    emit(state.copyWith(mealNotificationEnabled: value));
    _repository.saveMealNotification(value);
  }

  void updateMealTime(int value) {
    if (value < 5) return;
    emit(state.copyWith(mealNotificationTime: value));
    _repository.saveMealTime(value);
  }

  void togglePurchaseNotification(bool value) {
    emit(state.copyWith(purchaseNotificationEnabled: value));
    _repository.savePurchaseNotification(value);
  }

  void updatePurchaseTime(int value) {
    if (value < 1) return;
    emit(state.copyWith(purchaseNotificationTime: value));
    _repository.savePurchaseTime(value);
  }

  void updatePurchaseDays(int value) {
    if (value < 1) return;
    emit(state.copyWith(purchaseDaysCount: value));
    _repository.savePurchaseDays(value);
  }
}