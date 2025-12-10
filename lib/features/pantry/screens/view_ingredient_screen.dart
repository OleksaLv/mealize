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
  late int _quantity;
  String _unit = 'pcs';
  String? _photoPath;
  late TextEditingController _quantityController;

  bool get _isLocked => widget.ingredient != null && !widget.ingredient!.isCustom;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ingredient?.name ?? '');
    _notesController = TextEditingController(text: widget.ingredient?.notes ?? '');
    _quantity = widget.ingredient?.quantity ?? 1;
    _unit = widget.ingredient?.unit ?? 'pcs';
    _photoPath = widget.ingredient?.photoPath;
    _quantityController = TextEditingController(text: _quantity.toInt().toString());

    _titleController.addListener(_updateState);
    _notesController.addListener(_updateState);
    _quantityController.addListener(_updateState);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateState);
    _notesController.removeListener(_updateState);
    _quantityController.removeListener(_updateState);
    _titleController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {}); 
  }

  bool get _hasChanges {
    if (widget.ingredient == null) {
      return _titleController.text.isNotEmpty;
    }
    
    final initialNotes = widget.ingredient?.notes ?? '';
    
    return _titleController.text != widget.ingredient!.name ||
           _notesController.text != initialNotes ||
           _quantity != widget.ingredient!.quantity ||
           _unit != widget.ingredient!.unit ||
           _photoPath != widget.ingredient!.photoPath;
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
      isCustom: widget.ingredient?.isCustom ?? true,
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                'Delete "${widget.ingredient?.name}"?',
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
                'Are you sure you want to delete this ingredient? This action cannot be undone.',
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
                          if (widget.ingredient?.id != null) {
                            context.read<PantryCubit>().deleteIngredient(widget.ingredient!.id!);
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
    final isEditing = widget.ingredient != null;
    final lockedColor = Theme.of(context).colorScheme.tertiary; 

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
                          child: Text('Take photo', selectionColor: Colors.black,)
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
                          child: Text('Select from gallery')
                        ),
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
                color: _isLocked ? lockedColor : Theme.of(context).colorScheme.secondary,
                border: Border.all(color: _isLocked ? Colors.transparent : Theme.of(context).colorScheme.outline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _unit,
                  isExpanded: true,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  iconEnabledColor: Theme.of(context).colorScheme.onSecondary,
                  iconDisabledColor: Theme.of(context).colorScheme.onSecondary,
                  items: ['pcs', 'g', 'ml', 'kg', 'l'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: _isLocked ? null : (newValue) => setState(() => _unit = newValue!),
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
                fillColor: Theme.of(context).colorScheme.secondary,
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
                        _quantity = (parsed ?? 0).toInt();
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
            )
          ],
        ),
      ),
    );
  }
}