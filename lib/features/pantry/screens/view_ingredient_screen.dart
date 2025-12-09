import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/pantry_cubit.dart';
import '../data/ingredient_model.dart';
import 'package:flutter/services.dart';

class ViewIngredientScreen extends StatefulWidget {
  final Ingredient? ingredient;

  const ViewIngredientScreen({super.key, this.ingredient});

  @override
  State<ViewIngredientScreen> createState() => _ViewIngredientScreenState();
}

class _ViewIngredientScreenState extends State<ViewIngredientScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late double _quantity;
  String _unit = 'pcs';
  String? _photoPath;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ingredient?.name ?? '');
    _notesController = TextEditingController(text: widget.ingredient?.notes ?? '');
    _quantity = widget.ingredient?.quantity ?? 1.0;
    _unit = widget.ingredient?.unit ?? 'pcs';
    _photoPath = widget.ingredient?.photoPath;
    _quantityController = TextEditingController(text: _quantity.toInt().toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_titleController.text.isEmpty) return;

    final newIngredient = Ingredient(
      id: widget.ingredient?.id,
      name: _titleController.text,
      notes: _notesController.text,
      unit: _unit,
      quantity: _quantity,
      photoPath: _photoPath,
      isCustom: true,
    );

    if (widget.ingredient == null) {
      context.read<PantryCubit>().addIngredient(newIngredient);
    } else {
      context.read<PantryCubit>().updateIngredient(newIngredient);
    }
    Navigator.of(context).pop();
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete "${widget.ingredient?.name}"?', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Are you sure you want to delete this ingredient? This action cannot be undone.',
              textAlign: TextAlign.center),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () {
              if (widget.ingredient?.id != null) {
                context.read<PantryCubit>().deleteIngredient(widget.ingredient!.id!);
              }
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ingredient != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isEditing ? 'View ingredient' : 'New ingredient', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        actions: [
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              labelText: 'Title',
              controller: _titleController,
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
                      color: Theme.of(context).colorScheme.onTertiary,
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
                        child: OutlinedButton(onPressed: () {}, child: const Text('Take photo'))
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        child: OutlinedButton(onPressed: () {}, child: const Text('Select from gallery')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Units of measurement', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondary,
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _unit,
                  isExpanded: true,
                  items: ['pcs', 'g', 'ml',].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _unit = newValue!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              controller: _notesController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: () {
                    setState(() {
                      _quantity = (_quantity > 0) ? _quantity - 1 : 0;
                      _quantityController.text = _quantity.toInt().toString();
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
                SizedBox(
                  width: 80,
                  height: 32,
                  child: TextFormField(
                    controller: _quantityController,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final parsed = int.tryParse(value.isEmpty ? '0' : value);
                      setState(() {
                        _quantity = (parsed ?? 0).toDouble();
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    setState(() {
                      _quantity += 1;
                      _quantityController.text = _quantity.toInt().toString();
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
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                if (isEditing)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 50)
                      ),
                      onPressed: _onDelete,
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
                    onPressed: _onSave,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}