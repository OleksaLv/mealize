import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mealize/core/constants/app_strings.dart';
import 'package:mealize/features/pantry/screens/pantry_screen.dart';
import 'package:mealize/features/recipes/screens/recipes_screen.dart';
import 'package:mealize/features/settings/screens/settings_screen.dart';
import 'package:mealize/core/widgets/custom_app_bar.dart';
import 'package:mealize/core/widgets/app_bottom_nav_bar.dart';
import 'package:mealize/core/widgets/custom_fab.dart';
import '../bloc/schedule_cubit.dart';
import '../bloc/schedule_state.dart';
import '../data/meal_plan_entry_model.dart';
import 'calendar_screen.dart';
import 'view_meal_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  
  @override
  void initState() {
    super.initState();
    context.read<ScheduleCubit>().loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        DateTime selectedDate = DateTime.now();
        List<MealPlanEntry> meals = [];
        bool isLoading = false;

        if (state is ScheduleLoaded) {
          selectedDate = state.selectedDate;
          meals = state.dayMeals;
        } else if (state is ScheduleLoading) {
          isLoading = true;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          appBar: CustomAppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.schedule,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.open_in_full),
                  color: Theme.of(context).colorScheme.onSecondary,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CalendarScreen(initialDate: selectedDate),
                      ),
                    );
                  },
                ),
              ],
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
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              _WeekDaySelector(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  context.read<ScheduleCubit>().selectDate(date);
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      const _TimeScale(),
                      ...meals.map((meal) {
                        final minutes = meal.dateTime.hour * 60 + meal.dateTime.minute;
                        final topOffset = minutes * (_TimeScale.hourHeight / 60.0);
                        
                        return _MealCard(
                          mealEntry: meal,
                          topOffset: topOffset,
                          onTap: () {
                            // Навігація на редагування
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ViewMealScreen(entry: meal),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0: break;
                case 1:
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const PantryScreen()),
                  );
                  break;
                case 2:
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const RecipesScreen()),
                  );
                  break;
              }
            },
          ),
          floatingActionButton: CustomFAB(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ViewMealScreen(
                    initialDate: context.read<ScheduleCubit>().state is ScheduleLoaded 
                        ? (context.read<ScheduleCubit>().state as ScheduleLoaded).selectedDate 
                        : DateTime.now(),
                  ),
                ),
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

class _WeekDaySelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekDaySelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_WeekDaySelector> createState() => _WeekDaySelectorState();
}

class _WeekDaySelectorState extends State<_WeekDaySelector> {
  final ScrollController _scrollController = ScrollController();
  final List<DateTime?> _daysInMonth = [];
  static const double _dayItemWidth = 56.0;

  @override
  void initState() {
    super.initState();
    _populateDays();
    WidgetsBinding.instance.addPostFrameCallback((_)  {
      _scrollToDate(widget.selectedDate);
    });
  }
  
  @override
  void didUpdateWidget(_WeekDaySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToDate(widget.selectedDate);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); 
    super.dispose();
  }

  void _populateDays() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    int daysToSubtract = firstDayOfMonth.weekday - DateTime.monday;
    DateTime displayStartDate =
        firstDayOfMonth.subtract(Duration(days: daysToSubtract));

    int daysToAdd = DateTime.sunday - lastDayOfMonth.weekday;
    DateTime displayEndDate =
        lastDayOfMonth.add(Duration(days: daysToAdd));

    for (DateTime date = displayStartDate;
        date.isBefore(displayEndDate.add(const Duration(days: 1)));
        date = DateTime(date.year, date.month, date.day + 1)) {
       _daysInMonth.add(date);
    }
  }

  void _scrollToDate(DateTime date) {
    if (_daysInMonth.isEmpty) return;
    final mondayOfSelectedWeek = date.subtract(Duration(days: date.weekday - 1));
    int index = -1;
    for(int i=0; i<_daysInMonth.length; i++) {
      if (_daysInMonth[i] != null && _isSameDay(_daysInMonth[i]!, mondayOfSelectedWeek)) {
        index = i;
        break;
      }
    }
    if (index != -1) {
      final double offset = index * _dayItemWidth;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _daysInMonth.map((date) {
            return _buildDayItem(context, date);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDayItem(BuildContext context, DateTime? date) {
    if (date == null) return const SizedBox(width: _dayItemWidth);

    final isSelected = _isSameDay(date, widget.selectedDate);
    final isCurrentMonth = date.month == DateTime.now().month; 

    return InkWell(
      onTap: () => widget.onDateSelected(date),
      borderRadius: BorderRadius.circular(20.0),
      child: Opacity(
        opacity: isCurrentMonth ? 1.0 : 0.3,
        child: SizedBox(
          width: _dayItemWidth,
          child: Column(
            children: [
              Text(
                DateFormat.E('en_US').format(date),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  DateFormat.d().format(date),
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeScale extends StatelessWidget {
  const _TimeScale();
  static const double hourHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(24, (index) => 0 + index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hours.map((hour) {
        return SizedBox(
          height: hourHeight,
          child: Row(
            children: [
              Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Divider(thickness: 1)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.mealEntry,
    required this.topOffset,
    this.onTap,
  });

  final MealPlanEntry mealEntry;
  final double topOffset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double cardHeight = _TimeScale.hourHeight - 16; 

    return Positioned(
      top: topOffset,
      left: 72.0,
      right: 0,
      height: cardHeight,
      child: Card(
        // ПОВЕРНУВ КОЛІР ЯК У СТАРОМУ КОДІ
        color: theme.colorScheme.primary.withAlpha(39),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: (mealEntry.recipePhotoPath != null)
                        ? Image.asset(mealEntry.recipePhotoPath!, fit: BoxFit.cover)
                        : Container(color: Colors.white, child: const Icon(Icons.fastfood)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealEntry.recipeName ?? 'Unknown Meal',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}