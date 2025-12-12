import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  late TextEditingController _titleController;
  late TextEditingController _stepsController;
  late int _cookingTime;
  String? _photoPath;
  late TextEditingController _cookingTimeController;
  
  List<Map<String, dynamic>> _ingredientsList = [];

  bool get _isLocked => widget.recipe != null && !widget.recipe!.isCustom;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe?.name ?? '');
    _stepsController = TextEditingController(text: widget.recipe?.description ?? '');
    _cookingTime = widget.recipe?.cookingTime ?? 1;
    _photoPath = widget.recipe?.photoPath;
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
      final ingredients = await context.read<RecipesCubit>().getIngredients(widget.recipe!.id!);
      if (mounted && ingredients.isNotEmpty) {
        setState(() {
          _ingredientsList = ingredients.map((i) => {
            'id': i.ingredientId,
            'name': i.ingredientName ?? '',
            'quantity': i.quantity.toDouble(),
            'unit': i.ingredientUnit ?? '',
            'image': i.ingredientPhoto,
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
          'image': picked.photoPath,
        });
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
           _stepsController.text != widget.recipe!.description ||
           _cookingTime != widget.recipe!.cookingTime ||
           _photoPath != widget.recipe!.photoPath ||
           true; 
  }

  void _onSave() {
    if (_titleController.text.isEmpty) return;

    final newRecipe = Recipe(
      id: widget.recipe?.id,
      name: _titleController.text,
      description: _stepsController.text,
      cookingTime: _cookingTime,
      photoPath: _photoPath,
      isCustom: widget.recipe?.isCustom ?? true,
    );

    final ingredients = _ingredientsList.map((map) {
      final qty = map['quantity'];
      final intQty = (qty is double) ? qty.toInt() : (qty as int);
      return IngredientInRecipe(
        recipeId: widget.recipe?.id ?? 0,
        ingredientId: map['id'] ?? 0, 
        quantity: intQty,
      );
    }).where((i) => i.ingredientId != 0).toList();

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
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 64,
                ),
              const SizedBox(height: 20),

              Text(
                'Delete "${widget.recipe?.name}"?',
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Are you sure you want to delete this recipe? This action cannot be undone.',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.recipe?.id != null) {
                            context.read<RecipesCubit>().deleteRecipe(widget.recipe!.id!);
                          }
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: _photoPath != null
                        ? DecorationImage(image: AssetImage(_photoPath!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photoPath == null ? const Icon(Icons.image_not_supported) : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        child: OutlinedButton(
                          onPressed: _isLocked ? null : () {}, 
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isLocked ? lockedColor : null,
                            side: _isLocked ? BorderSide.none : null,
                          ),
                          child: const Text('Take photo')
                        )
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        child: OutlinedButton(
                          onPressed: _isLocked ? null : () {}, 
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isLocked ? lockedColor : null,
                            side: _isLocked ? BorderSide.none : null,
                          ),
                          child: const Text('Select from gallery')
                        ),
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
                  child: _isLocked
                      ? Center(
                          child: Text(
                            '$_cookingTime',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : TextFormField(
                          controller: _cookingTimeController,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            final parsed = int.tryParse(value.isEmpty ? '0' : value);
                            setState(() {
                              _cookingTime = (parsed ?? 0).toInt();
                            });
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                children: [
                  ..._ingredientsList.map((ing) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ing['image'] != null
                                  ? Image.asset(
                                      ing['image'], 
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, o, s) => const Icon(Icons.fastfood, color: Colors.grey),
                                    )
                                  : const Icon(Icons.fastfood, color: Colors.grey),
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
                            width: 80,
                            height: 32,
                            child: _isLocked
                              ? Center(
                                  child: Text(
                                    ing['quantity'].toInt().toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : TextFormField(
                                  enabled: true,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  controller: TextEditingController(text: ing['quantity'].toInt().toString()),
                                  onChanged: (value) {
                                    final parsed = int.tryParse(value.isEmpty ? '0' : value);
                                    setState(() {
                                      ing['quantity'] = (parsed ?? 0).toDouble();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 30,
                            child: Text(
                              ing['unit'],
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                            const SizedBox(width: 12),
                            InkWell(
                                onTap: () {
                                    setState(() {
                                        _ingredientsList.remove(ing);
                                    });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                        Icons.close, 
                                        size: 20, 
                                        color: Theme.of(context).colorScheme.onSecondary
                                    ),
                                ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  if (!_isLocked)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _pickIngredient,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        ),
                        child: const Text('Add ingredient',),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                children: [
                  TextFormField(
                    enabled: !_isLocked,
                    maxLines: 3,
                    controller: _stepsController,
                    decoration: InputDecoration(
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                      ),
                      fillColor: _isLocked ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.secondary,
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
                        disabledBackgroundColor: Theme.of(context).colorScheme.error.withAlpha(128), 
                        disabledForegroundColor: Theme.of(context).colorScheme.onError,
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 50),
                        elevation: _isLocked ? 0 : 2,
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