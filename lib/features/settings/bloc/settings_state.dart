import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool mealNotificationEnabled;
  final int mealNotificationTime;
  final bool purchaseNotificationEnabled;
  final int purchaseNotificationTime;
  final int purchaseDaysCount;

  const SettingsState({
    this.mealNotificationEnabled = true,
    this.mealNotificationTime = 60,
    this.purchaseNotificationEnabled = true,
    this.purchaseNotificationTime = 5,
    this.purchaseDaysCount = 1,
  });

  SettingsState copyWith({
    bool? mealNotificationEnabled,
    int? mealNotificationTime,
    bool? purchaseNotificationEnabled,
    int? purchaseNotificationTime,
    int? purchaseDaysCount,
  }) {
    return SettingsState(
      mealNotificationEnabled: mealNotificationEnabled ?? this.mealNotificationEnabled,
      mealNotificationTime: mealNotificationTime ?? this.mealNotificationTime,
      purchaseNotificationEnabled: purchaseNotificationEnabled ?? this.purchaseNotificationEnabled,
      purchaseNotificationTime: purchaseNotificationTime ?? this.purchaseNotificationTime,
      purchaseDaysCount: purchaseDaysCount ?? this.purchaseDaysCount,
    );
  }

  @override
  List<Object> get props => [
        mealNotificationEnabled,
        mealNotificationTime,
        purchaseNotificationEnabled,
        purchaseNotificationTime,
        purchaseDaysCount,
      ];
}