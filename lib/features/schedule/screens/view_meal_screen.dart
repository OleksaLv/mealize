import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mealize/core/widgets/primary_button.dart';
import 'package:mealize/features/recipes/screens/recipes_screen.dart';
import 'package:mealize/features/recipes/data/recipe_model.dart';
import '../bloc/schedule_cubit.dart';
import '../data/meal_plan_entry_model.dart';

class ViewMealScreen extends StatefulWidget {
  final MealPlanEntry? entry;
  final DateTime? initialDate;

  const ViewMealScreen({super.key, this.entry, this.initialDate});

  @override
  State<ViewMealScreen> createState() => _ViewMealScreenState();
}

class _ViewMealScreenState extends State<ViewMealScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Recipe? _selectedRecipe;
  
  String? _initialRecipeName;
  String? _initialRecipePhoto;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedDate = widget.entry!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.entry!.dateTime);
      _initialRecipeName = widget.entry!.recipeName;
      _initialRecipePhoto = widget.entry!.recipePhotoPath;

      _selectedRecipe = Recipe(
        id: widget.entry!.recipeId,
        name: widget.entry!.recipeName ?? '',
        photoPath: widget.entry!.recipePhotoPath,
        cookingTime: 0,
        description: '',
      );
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = const TimeOfDay(hour: 13, minute: 0);
    }
  }

  Future<void> _pickRecipe() async {
    final Recipe? recipe = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RecipesScreen(isSelectionMode: true),
      ),
    );

    if (recipe != null) {
      setState(() {
        _selectedRecipe = recipe;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              confirmButtonStyle: ButtonStyle(foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary)),
              cancelButtonStyle: ButtonStyle(foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary)),
            ), 
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _onSave() {
    if (_selectedRecipe == null || _selectedDate == null || _selectedTime == null) return;

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );


    final meal = MealPlanEntry(
      id: widget.entry?.id,
      recipeId: _selectedRecipe!.id!,
      dateTime: dateTime,
    );

    if (_isEditing) {
      context.read<ScheduleCubit>().updateMeal(meal);
    } else {
      context.read<ScheduleCubit>().addMeal(meal);
    }
    
    Navigator.of(context).pop();
  }

  void _onDelete() {
     showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        surfaceTintColor: Theme.of(context).colorScheme.secondary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.error, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Delete meal?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this meal? This action cannot be undone.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<ScheduleCubit>().deleteMeal(widget.entry!.id!);
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String dateText = '';
    if (_selectedDate != null) {
      final day = DateFormat('d').format(_selectedDate!);
      final month = DateFormat('MMMM').format(_selectedDate!).toLowerCase();
      final year = DateFormat('yyyy').format(_selectedDate!);
      dateText = '$day of $month, $year';
    }

    String timeText = '';
    if (_selectedTime != null) {
      final hour = _selectedTime!.hour.toString().padLeft(2, '0');
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      timeText = '$hour:$minute';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        title: Text('View meal', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSecondary, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            const Text('Dish', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickRecipe,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _selectedRecipe == null
                  ? const Center(child: Text('Select from dishes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)))
                  : Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40, 
                            height: 40,
                            child: _selectedRecipe!.photoPath != null 
                              ? Image.asset(_selectedRecipe!.photoPath!, fit: BoxFit.cover)
                              : const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedRecipe!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.edit_outlined, color: theme.colorScheme.onSecondary),
                      ],
                    ),
              ),
            ),

            const SizedBox(height: 24),

            const Text('Date', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 64,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Text(
                  dateText,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text('Time', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                height: 64,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Text(
                  timeText,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: PrimaryButton(
                    text: 'Save',
                    onPressed: (_selectedRecipe != null && _selectedDate != null && _selectedTime != null) ? _onSave : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}