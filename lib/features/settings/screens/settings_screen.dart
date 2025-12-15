import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mealize/core/constants/app_strings.dart';
import 'package:mealize/core/services/auth_repository.dart';
import 'package:mealize/core/widgets/custom_app_bar.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';
import '../../auth/screens/auth_gate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email ?? AppStrings.noEmailAvailable;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: const Text(
          AppStrings.settings,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            color: Colors.black,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSwitchRow(
                  context,
                  title: 'Meal notification',
                  value: state.mealNotificationEnabled,
                  onChanged: cubit.toggleMealNotification,
                ),
                const SizedBox(height: 16),
                _buildCounterRow(
                  context,
                  title: 'Before meal (mins)',
                  value: state.mealNotificationTime,
                  isEnabled: state.mealNotificationEnabled,
                  onDecrement: () => cubit.updateMealTime(state.mealNotificationTime - 1),
                  onIncrement: () => cubit.updateMealTime(state.mealNotificationTime + 1),
                  onValueChanged: cubit.updateMealTime,
                ),
                
                const SizedBox(height: 16),
                const Divider(thickness: 1, color: Color(0xFFEDF1F3)), 
                const SizedBox(height: 16),

                _buildSwitchRow(
                  context,
                  title: 'Purchase notifications',
                  value: state.purchaseNotificationEnabled,
                  onChanged: cubit.togglePurchaseNotification,
                ),
                const SizedBox(height: 16),
                _buildCounterRow(
                  context,
                  title: 'Before next day (hours)',
                  value: state.purchaseNotificationTime,
                  isEnabled: state.purchaseNotificationEnabled,
                  onDecrement: () => cubit.updatePurchaseTime(state.purchaseNotificationTime - 1),
                  onIncrement: () => cubit.updatePurchaseTime(state.purchaseNotificationTime + 1),
                  onValueChanged: cubit.updatePurchaseTime,
                ),
                const SizedBox(height: 16),
                _buildCounterRow(
                  context,
                  title: 'Ingredients for next days',
                  value: state.purchaseDaysCount,
                  isEnabled: state.purchaseNotificationEnabled,
                  onDecrement: () => cubit.updatePurchaseDays(state.purchaseDaysCount - 1),
                  onIncrement: () => cubit.updatePurchaseDays(state.purchaseDaysCount + 1),
                  onValueChanged: cubit.updatePurchaseDays,
                ),

                const SizedBox(height: 16),
                const Divider(thickness: 1, color: Color(0xFFEDF1F3)),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await authRepository.signOut();
                      
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const AuthGate()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text(
                      AppStrings.logOut,
                      style: TextStyle(
                        color: Color(0xFFD20000), 
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: Theme.of(context).colorScheme.primary.withAlpha(51),
        ),
      ],
    );
  }

  Widget _buildCounterRow(
    BuildContext context, {
    required String title,
    required int value,
    required bool isEnabled,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required ValueChanged<int> onValueChanged,
  }) {
    final color = isEnabled ? Colors.black : Colors.grey;
    final btnColor = isEnabled ? Colors.black87 : Colors.grey;
    final theme = Theme.of(context);

    final textFieldDecoration = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      filled: true,
      fillColor: isEnabled ? theme.colorScheme.secondary : theme.colorScheme.tertiary,
    );


    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color),
        ),
        Row(
          children: [
            _CounterButton(
              icon: Icons.remove,
              onTap: isEnabled ? onDecrement : null,
              color: btnColor,
            ),
            
            const SizedBox(width: 8),

            SizedBox(
              width: 50, 
              height: 32,
              child: TextFormField(
                key: ValueKey(value),
                enabled: isEnabled,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                initialValue: value.toString(), 
                keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (text) {
                  final parsed = int.tryParse(text.isEmpty ? '0' : text) ?? 0;
                  onValueChanged(parsed);
                },
                style: TextStyle(color: color),
                decoration: textFieldDecoration,
              ),
            ),

            const SizedBox(width: 8),

            _CounterButton(
              icon: Icons.add,
              onTap: isEnabled ? onIncrement : null,
              color: btnColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _CounterButton({
    required this.icon,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF1F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}