import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; //for date formatting
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/custom_fab.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.open_in_full),
              color: Colors.black,
              onPressed: () {},
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            color: Colors.red,
            onPressed: () {
              FirebaseCrashlytics.instance.crash();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            color: Colors.black,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: Colors.black,
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          const _WeekDaySelector(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  const _TimeScale(),
                  _MealCard(
                    mealName: 'Borsch',
                    imagePath: 'assets/images/borsch.jpg',
                    onTap: () {},
                    topOffset: 720,
                  ),
                  _MealCard(
                    mealName: 'Stuffed cabbage rolls',
                    imagePath: 'assets/images/cabbage_rolls.jpg',
                    onTap: () {},
                    topOffset: 1040,
                  ),
                  _MealCard(
                    mealName: 'Potato pancakes',
                    imagePath: 'assets/images/potato_pancakes.jpg',
                    onTap: () {},
                    topOffset: 1440,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
      floatingActionButton: const CustomFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Widgets for Time Scale and Week Day Selector

class _WeekDaySelector extends StatefulWidget {
  const _WeekDaySelector();

  @override
  State<_WeekDaySelector> createState() => _WeekDaySelectorState();
}

class _WeekDaySelectorState extends State<_WeekDaySelector> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final List<DateTime?> _daysInMonth = [];

  static const double _dayItemWidth = 56.0;

  @override
  void initState() {
    super.initState();
    _populateDays();

    // Scroll to the current week after the layout is built
    WidgetsBinding.instance.addPostFrameCallback((_)  {
      _scrollToCurrentWeek();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // dispose controllers
    super.dispose();
  }

  // Populates the _daysInMonth list with all days to be displayed,
  // including null fillers for empty slots in the first and last weeks.
  void _populateDays() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Find the Monday of the first week to display
    int daysToSubtract = firstDayOfMonth.weekday - DateTime.monday;
    DateTime displayStartDate =
        firstDayOfMonth.subtract(Duration(days: daysToSubtract));

    // Find the Sunday of the last week to display.
    int daysToAdd = DateTime.sunday - lastDayOfMonth.weekday;
    DateTime displayEndDate =
        lastDayOfMonth.add(Duration(days: daysToAdd));

    // Loop from the start Monday to the end Sunday
    for (DateTime date = displayStartDate;
        date.isBefore(displayEndDate.add(const Duration(days: 1)));
        date = DateTime(date.year, date.month, date.day + 1)) {
      if (date.month != now.month) {
        _daysInMonth.add(null);
      } else {
        _daysInMonth.add(date);
      }
    }
  }

  // Calculates and animates the scroll position to the Monday
  // of the currently selected week
  void _scrollToCurrentWeek() {
    final now = DateTime.now();
    // Find Monday of the current week
    final mondayOfCurrentWeek =
        now.subtract(Duration(days: now.weekday - DateTime.monday));

    // Find the Monday of the first displayed week
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    int daysToSubtract = firstDayOfMonth.weekday - DateTime.monday;
    DateTime displayStartDate =
        firstDayOfMonth.subtract(Duration(days: daysToSubtract));

    // Calculate the index of the current Monday in the whole list
    if (mondayOfCurrentWeek.isAfter(displayStartDate) ||
        mondayOfCurrentWeek.isAtSameMomentAs(displayStartDate)) {
      final int index =
          mondayOfCurrentWeek.difference(displayStartDate).inDays;

      // Calculate the scroll offset
      final double offset = index * _dayItemWidth;

      // Animate the scroll
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Handles tap events on a date.
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  // Helper to check if two DateTime objects represent the same day.
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

  // Builds a single day item
  Widget _buildDayItem(BuildContext context, DateTime? date) {
    // If date is null, place an empty spacer
    if (date == null) {
      return const SizedBox(width: _dayItemWidth);
    }

    final isSelected = _isSameDay(date, _selectedDate);

    return InkWell(
      onTap: () => _onDateSelected(date),
      borderRadius:
          BorderRadius.circular(20.0),
      child: SizedBox(
        width: _dayItemWidth,
        child: Column(
          children: [
            Text(
              DateFormat.E('en_US').format(date),
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
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
                      : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
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
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.mealName,
    required this.imagePath,
    this.onTap,
    required this.topOffset,
  });

  final String mealName;
  final String imagePath;  
  final VoidCallback? onTap;
  final double topOffset;
  final double slotHeight = _TimeScale.hourHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardHeight = slotHeight - 16;

    return Positioned(
      top: topOffset,
      left: 72.0,
      right: 0,
      height: cardHeight,
      child: Card(
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
                    child: imagePath.startsWith('http')
                        ? Image.network(imagePath, fit: BoxFit.cover)
                        : Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                ),
                
                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    mealName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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