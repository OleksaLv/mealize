import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  const CustomFAB({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,      
      backgroundColor: Theme.of(context).colorScheme.primary,      
      foregroundColor: Theme.of(context).colorScheme.onPrimary,      
      shape: const CircleBorder(),      
      child: const Icon(
        Icons.add,
        size: 32,
      ),
    );
  }
}