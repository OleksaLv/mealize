import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mealize/core/constants/app_strings.dart';
import 'package:mealize/core/widgets/custom_app_bar.dart';
import 'package:mealize/core/widgets/app_bottom_nav_bar.dart';
import 'package:mealize/features/pantry/screens/pantry_screen.dart';
import 'package:mealize/features/recipes/screens/recipes_screen.dart';
import 'package:mealize/features/settings/screens/settings_screen.dart';
import '../bloc/schedule_cubit.dart';
import '../bloc/schedule_state.dart';

class CalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  const CalendarScreen({super.key, this.initialDate});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 365)); 
  final int _monthsToShow = 24;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMonth(widget.initialDate ?? DateTime.now());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMonth(DateTime date) {
    final monthsDiff = (date.year - _startDate.year) * 12 + (date.month - _startDate.month);
    
    if (monthsDiff >= 0 && monthsDiff < _monthsToShow && _scrollController.hasClients) {
      const double monthHeight = 400;
      final double offset = monthsDiff * monthHeight;
      
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: CustomAppBar(
        title: const Text(
          AppStrings.schedule,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            color: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          DateTime selectedDate = DateTime.now();
          List<DateTime> mealDates = [];

          if (state is ScheduleLoaded) {
            selectedDate = state.selectedDate;
            mealDates = state.allMeals
                .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
                .toSet()
                .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final dayName = DateFormat.E().format(DateTime(2024, 1, 1 + index)); 
                    return SizedBox(
                      width: 40,
                      child: Text(
                        dayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    );
                  }),
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _monthsToShow,
                  itemBuilder: (context, index) {
                    final monthDate = DateTime(_startDate.year, _startDate.month + index, 1);
                    return _MonthSection(
                      monthDate: monthDate,
                      selectedDate: selectedDate,
                      mealDates: mealDates,
                      onDaySelected: (date) {
                        context.read<ScheduleCubit>().selectDate(date);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
             Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const PantryScreen()),
              );
          } else if (index == 2) {
             Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const RecipesScreen()),
              );
          }
        },
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final DateTime monthDate;
  final DateTime selectedDate;
  final List<DateTime> mealDates;
  final ValueChanged<DateTime> onDaySelected;

  const _MonthSection({
    required this.monthDate,
    required this.selectedDate,
    required this.mealDates,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday; // 1=Mon, 7=Sun
    
    // Розрахунок порожніх клітинок на початку (офсет)
    // Якщо 1 число - понеділок (1), то офсет 0.
    final offset = firstWeekday - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              DateFormat('MMMM, yyyy').format(monthDate).toLowerCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 0,
            ),
            itemCount: offset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox();
              
              final day = index - offset + 1;
              final date = DateTime(monthDate.year, monthDate.month, day);
              
              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final hasMeal = mealDates.any((d) => DateUtils.isSameDay(d, date));

              return GestureDetector(
                onTap: () => onDaySelected(date),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasMeal)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onTertiary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else 
                      const SizedBox(height: 5),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          Divider(color: Theme.of(context).colorScheme.tertiary, height: 1),
        ],
      ),
    );
  }
}