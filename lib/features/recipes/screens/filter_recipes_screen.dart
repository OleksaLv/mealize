import 'package:flutter/material.dart';
import '../../pantry/data/ingredient_model.dart';
import '../data/recipes_repository.dart';

class FilterResult {
  final bool onlyFromPantry;
  final RangeValues cookingTimeRange;
  final List<String> selectedIngredients;

  FilterResult({
    required this.onlyFromPantry,
    required this.cookingTimeRange,
    required this.selectedIngredients,
  });
}

class FilterRecipesScreen extends StatefulWidget {
  final FilterResult? currentFilters;

  const FilterRecipesScreen({super.key, this.currentFilters});

  @override
  State<FilterRecipesScreen> createState() => _FilterRecipesScreenState();
}

class _FilterRecipesScreenState extends State<FilterRecipesScreen> {
  final RecipesRepository _repository = RecipesRepository();
  
  bool _onlyFromPantry = false;
  
  RangeValues _timeRange = const RangeValues(10, 500);
  
  List<Ingredient> _allIngredients = [];
  final Set<String> _selectedIngredients = {};
  
  String _searchQuery = '';
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentFilters != null) {
      _onlyFromPantry = widget.currentFilters!.onlyFromPantry;
      _timeRange = widget.currentFilters!.cookingTimeRange;
      _selectedIngredients.addAll(widget.currentFilters!.selectedIngredients);
    }
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final list = await _repository.getAllIngredients();
    if (mounted) {
      setState(() {
        _allIngredients = list;
      });
    }
  }

  String _formatTime(double minutes) {
    final int totalMinutes = minutes.toInt();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    } else {
      final int hours = totalMinutes ~/ 60;
      final int mins = totalMinutes % 60;
      return '${hours}h ${mins > 0 ? '$mins min' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleIngredients = _allIngredients.where((ing) {
      return ing.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final int itemCount = _isExpanded ? visibleIngredients.length : (visibleIngredients.length > 7 ? 7 : visibleIngredients.length);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.shade200),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              children: [
                InkWell(
                  onTap: () => setState(() => _onlyFromPantry = !_onlyFromPantry),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _onlyFromPantry,
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _onlyFromPantry = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'from my pantry (including quantity)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cooking time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Icon(Icons.keyboard_arrow_up, color: Colors.black),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_formatTime(_timeRange.start), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_formatTime(_timeRange.end), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                RangeSlider(
                  values: _timeRange,
                  min: 0,
                  max: 600,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Theme.of(context).colorScheme.tertiary,
                  onChanged: (values) => setState(() => _timeRange = values),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ingredients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Icon(Icons.keyboard_arrow_up, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onTertiary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ...List.generate(itemCount, (index) {
                  final ingredient = visibleIngredients[index];
                  final isSelected = _selectedIngredients.contains(ingredient.name);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIngredients.remove(ingredient.name);
                          } else {
                            _selectedIngredients.add(ingredient.name);
                          }
                        });
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isSelected,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIngredients.add(ingredient.name);
                                  } else {
                                    _selectedIngredients.remove(ingredient.name);
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(ingredient.name, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }),

                if (visibleIngredients.length > 7)
                  TextButton(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      children: [
                        Text(
                          _isExpanded ? 'Show less' : 'Show more',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(FilterResult(
                    onlyFromPantry: _onlyFromPantry,
                    cookingTimeRange: _timeRange,
                    selectedIngredients: _selectedIngredients.toList(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}