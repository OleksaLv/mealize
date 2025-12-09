import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mealize/core/constants/app_strings.dart';
import 'package:mealize/features/settings/screens/settings_screen.dart';
import 'package:mealize/features/schedule/screens/schedule_screen.dart';
import 'package:mealize/features/recipes/screens/recipes_screen.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'package:mealize/core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/custom_fab.dart';
import '../bloc/pantry_cubit.dart';
import '../bloc/pantry_state.dart';
import '../data/ingredient_model.dart';
import 'view_ingredient_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _searchQuery = '';
  bool _filterStandard = true;
  bool _filterCustom = true;

  @override
  void initState() {
    super.initState();
    context.read<PantryCubit>().loadPantryItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: CustomAppBar(
        title: const Text(
          AppStrings.pantry,
            style: TextStyle(
              fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            color: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {}
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
              Expanded(
                      child: _buildFilterChip('standard', _filterStandard, (v) => setState(() => _filterStandard = v)),
                    ),                
              const SizedBox(width: 12),
              Expanded(
                      child: _buildFilterChip('custom', _filterCustom, (v) => setState(() => _filterCustom = v)),
                    ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
                 enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<PantryCubit, PantryState>(
              builder: (context, state) {
                if (state is PantryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PantryLoaded) {
                  final filteredList = state.ingredients.where((item) {
                    final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    
                    bool matchesFilter = true;
                    if (_filterStandard && !_filterCustom) matchesFilter = !item.isCustom;
                    if (!_filterStandard && _filterCustom) matchesFilter = item.isCustom;
                    
                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('No ingredients found'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _PantryTile(ingredient: item);
                    },
                  );
                } else if (state is PantryError) {
                  return Center(child: Text(state.message, style: TextStyle(color: Theme.of(context).colorScheme.error)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ScheduleScreen(),
                ),
              );
              break;
            case 1:
              break;
            case 2:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const RecipesScreen(),
                ),
              );
              break;
          }
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ViewIngredientScreen(),
          ));
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onSelected) {
    return SizedBox(
    width: double.infinity,
    child: FilterChip(
      label: SizedBox(
        width: double.infinity,
        child: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      side:BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
    ),
  );
  }
}

class _PantryTile extends StatelessWidget {
  final Ingredient ingredient;

  const _PantryTile({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.tertiary,
              image: ingredient.photoPath != null
                  ? DecorationImage(image: AssetImage(ingredient.photoPath!), fit: BoxFit.cover)
                  : null,
            ),
            child: ingredient.photoPath == null ? const Icon(Icons.image_not_supported) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  ingredient.notes ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () {
              if (ingredient.quantity > 0) {
                final updated = ingredient.copyWith(quantity: ingredient.quantity - 1);
                context.read<PantryCubit>().updateIngredient(updated);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary, 
              padding: EdgeInsets.zero, 
              minimumSize: const Size(32, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              '${ingredient.quantity.toInt()} ${ingredient.unit}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () {
              final updated = ingredient.copyWith(quantity: ingredient.quantity + 1);
              context.read<PantryCubit>().updateIngredient(updated);
            },
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary, 
              padding: EdgeInsets.zero, 
              minimumSize: const Size(32, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ViewIngredientScreen(ingredient: ingredient),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).colorScheme.onSecondary),
            ),
          ),
        ],
      ),
    );
  }
}