import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/universal_image.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../pantry/data/ingredient_model.dart';
import '../../pantry/screens/pantry_screen.dart';
import '../bloc/recipes_cubit.dart';
import '../data/recipe_model.dart';
import '../data/ingredient_in_recipe_model.dart';

class ViewDishScreen extends StatefulWidget {
  final Recipe? recipe;

  const ViewDishScreen({super.key, this.recipe});

  @override
  State<ViewDishScreen> createState() => _ViewDishScreenState();
}

class _ViewDishScreenState extends State<ViewDishScreen> {
  final _pickerService = ImagePickerService();
  
  late TextEditingController _titleController;
  late TextEditingController _stepsController;
  late int _cookingTime;
  late TextEditingController _cookingTimeController;
  
  String? _photoPath;
  String? _photoUrl;
  
  List<Map<String, dynamic>> _ingredientsList = [];

  bool get _isLocked => widget.recipe != null && !widget.recipe!.isCustom;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe?.name ?? '');
    _stepsController = TextEditingController(text: widget.recipe?.steps ?? '');
    _cookingTime = widget.recipe?.cookingTime ?? 1;
    
    _photoPath = widget.recipe?.photoPath;
    _photoUrl = widget.recipe?.photoUrl;
    
    _cookingTimeController = TextEditingController(text: _cookingTime.toInt().toString());

    if (widget.recipe != null) {
      _loadIngredients();
    }

    _titleController.addListener(_updateState);
    _stepsController.addListener(_updateState);
    _cookingTimeController.addListener(_updateState);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateState);
    _stepsController.removeListener(_updateState);
    _cookingTimeController.removeListener(_updateState);
    _titleController.dispose();
    _stepsController.dispose();
    _cookingTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    if (widget.recipe?.id == null) return;
    try {
      final ingredients = await context.read<RecipesCubit>().getIngredients(widget.recipe!.id);
      if (mounted && ingredients.isNotEmpty) {
        setState(() {
          _ingredientsList = ingredients.map((i) => {
            'id': i.ingredientId,
            'name': i.ingredientName ?? '',
            'quantity': i.quantity.toDouble(),
            'unit': i.ingredientUnit ?? '',
            'imagePath': i.ingredientPhoto,
            'imageUrl': i.ingredientPhotoUrl,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading ingredients: $e');
    }
  }

  Future<void> _pickIngredient() async {
    final Ingredient? picked = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PantryScreen(isSelectionMode: true),
      ),
    );

    if (picked != null) {
      final exists = _ingredientsList.any((i) => i['id'] == picked.id);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingredient already added')),
          );
        }
        return;
      }

      setState(() {
        _ingredientsList.add({
          'id': picked.id,
          'name': picked.name,
          'quantity': 0.0,
          'unit': picked.unit,
          'imagePath': picked.photoPath,
          'imageUrl': picked.photoUrl,
        });
      });
    }
  }

  Future<void> _pickRecipePhoto() async {
    final pickedPath = await _pickerService.showImageSourceDialog(context);
    if (pickedPath != null) {
      setState(() {
        _photoPath = pickedPath;
      });
    }
  }

  void _updateState() {
    setState(() {});
  }

  bool get _hasChanges {
    if (widget.recipe == null) {
      return _titleController.text.isNotEmpty;
    }
    return _titleController.text != widget.recipe!.name ||
           _stepsController.text != widget.recipe!.steps ||
           _cookingTime != widget.recipe!.cookingTime ||
           _photoPath != widget.recipe!.photoPath ||
           _photoUrl != widget.recipe!.photoUrl ||
           true;
  }

  void _onSave() {
    if (_titleController.text.isEmpty) return;

    final newRecipe = Recipe(
      id: widget.recipe?.id,
      name: _titleController.text,
      steps: _stepsController.text,
      cookingTime: _cookingTime,
      photoPath: _photoPath,
      photoUrl: _photoUrl,
      isCustom: widget.recipe?.isCustom ?? true,
    );

    final ingredients = _ingredientsList.map((map) {
      final qty = map['quantity'];
      final intQty = (qty is double) ? qty.toInt() : (qty as int);
      return IngredientInRecipe(
        recipeId: widget.recipe?.id ?? '',
        ingredientId: map['id'], 
        quantity: intQty,
        ingredientPhoto: map['imagePath'],
        ingredientPhotoUrl: map['imageUrl'],
      );
    }).toList();

    if (widget.recipe == null) {
      context.read<RecipesCubit>().addRecipe(newRecipe, ingredients);
    } else {
      context.read<RecipesCubit>().updateRecipe(newRecipe, ingredients);
    }
    Navigator.of(context).pop();
  }
  
  void _onDelete() {
     showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Text('Delete Recipe?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               Row(children: [
                 Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                 const SizedBox(width: 10),
                 Expanded(child: ElevatedButton(
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                   onPressed: () {
                     if (widget.recipe?.id != null) {
                        context.read<RecipesCubit>().deleteRecipe(widget.recipe!.id);
                     }
                     Navigator.pop(ctx);
                     Navigator.pop(context);
                   }, 
                   child: const Text('Delete')
                 )),
               ])
             ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;
    final lockedColor = Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          widget.recipe == null ? 'New dish' : 'View dish', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(), 
            icon: const Icon(Icons.close, size: 28)
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              labelText: 'Title',
              controller: _titleController,
              enabled: !_isLocked,
            ),
            
            const SizedBox(height: 24),
            
            const Text('Photo', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                UniversalImage(
                  width: 100,
                  height: 100,
                  borderRadius: BorderRadius.circular(8),
                  photoPath: _photoPath,
                  photoUrl: _photoUrl,
                  fallbackAssetPath: 'assets/images/placeholder_dish.png',
                  placeholder: Container(
                    width: 100, height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        child: OutlinedButton(
                          onPressed: _isLocked ? null : _pickRecipePhoto, 
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isLocked ? lockedColor : null,
                            side: _isLocked ? BorderSide.none : null,
                          ),
                          child: const Text('Change photo'),
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            const Text('Cooking time (minutes)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
             Row(
              children: [
                if (!_isLocked) ...[
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () {
                      setState(() {
                        _cookingTime = (_cookingTime > 0) ? _cookingTime - 1 : 0;
                        _cookingTimeController.text = _cookingTime.toInt().toString();
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                SizedBox(
                  width: 80,
                  height: 32,
                  child: TextFormField(
                      controller: _cookingTimeController,
                      enabled: !_isLocked,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) => setState(() => _cookingTime = int.tryParse(val) ?? 0),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        fillColor: _isLocked ? lockedColor : Colors.white,
                        filled: true,
                      ),
                  ),
                ),

                if (!_isLocked) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      setState(() {
                        _cookingTime += 1;
                        _cookingTimeController.text = _cookingTime.toInt().toString();
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: true,
                iconColor: Colors.black,
                collapsedIconColor: Colors.black,
                children: [
                  ..._ingredientsList.map((ing) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: UniversalImage(
                              borderRadius: BorderRadius.circular(8),
                              photoPath: ing['imagePath'],
                              photoUrl: ing['imageUrl'],
                              fallbackAssetPath: 'assets/images/placeholder_ingredient.png',
                              placeholder: Container(color: Colors.grey[200]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          Expanded(
                            child: Text(
                              ing['name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          
                          if (!_isLocked) ...[
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (ing['quantity'] > 0) ing['quantity'] -= 1;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.tertiary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(32, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${ing['quantity'].toInt()} ${ing['unit']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          
                          if (!_isLocked) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                setState(() {
                                  ing['quantity'] += 1;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.tertiary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(32, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                                onTap: () => setState(() => _ingredientsList.remove(ing)),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(Icons.close, size: 20, color: Theme.of(context).colorScheme.onSecondary),
                                ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  if (!_isLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _pickIngredient,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add ingredient'),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

             Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('Steps', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: true,
                iconColor: Colors.black,
                collapsedIconColor: Colors.black,
                children: [
                  TextFormField(
                    enabled: !_isLocked,
                    maxLines: 5,
                    controller: _stepsController,
                    decoration: InputDecoration(
                      hintText: 'Describe how to cook...',
                      filled: true,
                      fillColor: _isLocked ? lockedColor : Theme.of(context).colorScheme.secondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            
             Row(
              children: [
                if (isEditing)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 50),
                      ),
                      onPressed: _isLocked ? null : _onDelete,
                      child: const Text('Delete'),
                    ),
                  ),
                if (isEditing) const SizedBox(width: 16),
                
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 50)
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: PrimaryButton(
                    text: 'Save',
                    onPressed: _hasChanges ? _onSave : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}