import 'package:flutter/material.dart';

class DividerWithText extends StatelessWidget {
  const DividerWithText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    // Widget divider to avoid code duplication
    final divider = Expanded(
      child: Divider(
        color: Theme.of(context).colorScheme.onTertiary,
        thickness: 1,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        divider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        divider,
      ],
    );
  }
}