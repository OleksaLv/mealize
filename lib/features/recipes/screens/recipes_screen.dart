import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/custom_fab.dart';
import '../../../../core/constants/app_strings.dart';
import '../bloc/recipes_cubit.dart';
import '../bloc/recipes_state.dart';
import '../data/recipe_model.dart';
import '../data/recipes_repository.dart';
import 'view_dish_screen.dart';
import 'filter_recipes_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../../pantry/screens/pantry_screen.dart';
import '../../settings/screens/settings_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _searchQuery = '';
  bool _filterStandard = true;
  bool _filterCustom = true;

  FilterResult? _advancedFilters;
  List<int> _availableRecipeIds = [];
  List<int> _ingredientFilteredIds = [];

  @override
  void initState() {
    super.initState();
    context.read<RecipesCubit>().loadRecipes();
  }

  void _openFilters() async {
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterRecipesScreen(currentFilters: _advancedFilters),
    );

    if (result != null) {
      if (result.selectedIngredients.isNotEmpty) {
        final repo = RecipesRepository();
        final ids = await repo.getRecipeIdsByIngredients(result.selectedIngredients);
        if (mounted) {
           setState(() {
             _ingredientFilteredIds = ids;
           });
        }
      } else {
        setState(() {
          _ingredientFilteredIds = [];
        });
      }

      setState(() {
        _advancedFilters = result;
      });

      if (result.onlyFromPantry) {
        _checkPantryAvailability();
      }
    }
  }

  Future<void> _checkPantryAvailability() async {
    final repo = RecipesRepository(); 
    final ids = await repo.getAvailableRecipeIds();
    if (mounted) {
      setState(() {
        _availableRecipeIds = ids;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: const Text(
          AppStrings.recipes, 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            color: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
                Expanded(child: _buildFilterChip('standard', _filterStandard, (v) => setState(() => _filterStandard = v))),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('custom', _filterCustom, (v) => setState(() => _filterCustom = v))),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _openFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                      child: const Text(
                        'filter',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search dishes...',
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
            child: BlocBuilder<RecipesCubit, RecipesState>(
              builder: (context, state) {
                if (state is RecipesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is RecipesLoaded) {
                  final filteredList = state.recipes.where((item) {
                    final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    
                    final matchesStandard = _filterStandard && !item.isCustom;
                    final matchesCustom = _filterCustom && item.isCustom;
                    bool topBarMatch = matchesSearch && (matchesStandard || matchesCustom);
                    
                    if (!topBarMatch) return false;

                    if (_advancedFilters != null) {
                      if (item.cookingTime < _advancedFilters!.cookingTimeRange.start || 
                          item.cookingTime > _advancedFilters!.cookingTimeRange.end) {
                        return false;
                      }

                      if (_advancedFilters!.onlyFromPantry) {
                         if (!_availableRecipeIds.contains(item.id)) {
                           return false;
                         }
                      }
                      
                      if (_advancedFilters!.selectedIngredients.isNotEmpty) {
                        if (!_ingredientFilteredIds.contains(item.id)) {
                          return false;
                        }
                      }
                    }

                    return true;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('No recipes found'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _RecipeCard(recipe: filteredList[index]);
                    },
                  );
                } else if (state is RecipesError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ScheduleScreen()));
              break;
            case 1:
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PantryScreen()));
              break;
            case 2:
              break;
          }
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ViewDishScreen(),
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

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ViewDishScreen(recipe: recipe),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: recipe.photoPath != null
                        ? DecorationImage(image: AssetImage(recipe.photoPath!), fit: BoxFit.cover)
                        : null,
                    color: Colors.white,
                    
                  ),
                  child: recipe.photoPath == null ? const Icon(Icons.image_not_supported) : null,
                ),
            ),
            
            const SizedBox(height: 12),

            Text(
              recipe.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${recipe.cookingTime} min',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSecondary.withAlpha(153),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}